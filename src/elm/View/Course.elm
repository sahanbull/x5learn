module View.Course exposing (viewCourse)

import Dict
import Set
import Json.Decode as Decode

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)

import Model exposing (..)
import View.Utility exposing (..)

import Msg exposing (..)


{-| Render the user's course as a list of items
-}
viewCourse : Model -> Element Msg
viewCourse model =
  if model.course.items==[] then
    none
  else
    let
        items =
          model.course.items
          |> List.indexedMap (viewCourseItem model)
          |> column [ spacing 20, paddingTop 20, width fill ]
    in
        [ items
        , viewCoursePathFinderContainer model
        ]
        |> column [ spacing 50, width fill ]


{-| Render a single course item
-}
viewCourseItem : Model -> Int -> CourseItem -> Element Msg
viewCourseItem model index item =
  case model.cachedOers |> Dict.get item.oerId of
    Nothing ->
      none -- impossible

    Just oer ->
      let
          nCourseItems =
            model.course.items |> List.length

          buttonAttrs =
            [ paddingXY 5 3, buttonRounding, Background.color primaryGreen, alignRight ]

          moveUpButton =
            if index==0 || isLabStudy1 model then
              none
            else
              button buttonAttrs { onPress = Just <| MovedCourseItemDown (index-1), label = "Move ↑" |> captionNowrap [ whiteText ] }

          moveDownButton =
            if index==nCourseItems-1 || isLabStudy1 model then
              none
            else
              button buttonAttrs { onPress = Just <| MovedCourseItemDown index, label = "Move ↓" |> captionNowrap [ whiteText ] }

          deleteButton =
            button [] { onPress = Just <| RemovedOerFromCourse oer.id, label = "Remove" |> captionNowrap [ greyText] }

          topRow =
            [ index+1 |> String.fromInt |> bodyNoWrap []
            , moveUpButton
            , moveDownButton
            , deleteButton
            ]
            |> row [ width fill, spacing 10 ]

          miniCard =
            [ topRow
            , oer.title |> bodyWrap []
            ]
            |> column [ width fill, spacing 10, paddingTop 10, borderTop 1, Border.color <| greyDivider ]
      in
          miniCard
          |> el [ width fill, htmlClass "PreventClosingInspectorOnClick", onClickStopPropagation <| ClickedOnCourseItem oer ]


{-| Render the coursePathFinder
-}
viewCoursePathFinderContainer : Model -> Element Msg
viewCoursePathFinderContainer model =
  if List.length model.course.items>1 then
    viewCoursePathFinderWidget model
  else
    -- "Tip: Add more items to your workspace" |> captionWrap []
    none


{-| Render the widget that integrates the coursePathFinder API from Nantes
-}
viewCoursePathFinderWidget : Model -> Element Msg
viewCoursePathFinderWidget model =
  if isLabStudy1 model then
    none
  else
    case model.courseOptimization of
      Nothing ->
        actionButtonWithIcon [ whiteText, paddingXY 12 10, width fill, centerX ] [ Background.color electricBlue, width fill, buttonRounding ] IconLeft 1 "directions_walk_white" "Optimise learning path" (Just PressedOptimiseLearningPath)

      Just Loading ->
        viewLoadingSpinner

      Just (UndoAvailable savedPreviousCourse) ->
        let
            content =
              if savedPreviousCourse == model.course then
                [ "Your workspace is in a good sequence for learning, according to our algorithm. No changes needed." |> captionWrap [ whiteText ]
                ]
              else
                [ "Our algorithm has changed the sequence of your items." |> captionWrap [ whiteText ]
                , simpleButton [ Font.size 12, Font.color electricBlue ] "Undo" (Just <| PressedUndoCourse savedPreviousCourse)
                ]
        in
            content
            |> column [ spacing 15, padding 10, Background.color <| grey 50, Border.rounded 10 ]
