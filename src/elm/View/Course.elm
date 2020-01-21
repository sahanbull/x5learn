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
            [ paddingXY 5 3, Background.color x5color, alignRight ]

          moveUpButton =
            if index==0 then
              none
            else
              button buttonAttrs { onPress = Just <| MovedCourseItemDown (index-1), label = "Move ↑" |> captionNowrap [ whiteText ] }

          moveDownButton =
            if index==nCourseItems-1 then
              none
            else
              button buttonAttrs { onPress = Just <| MovedCourseItemDown index, label = "Move ↓" |> captionNowrap [ whiteText ] }

          deleteButton =
            button (buttonAttrs ++ [ Background.color red ]) { onPress = Just <| RemovedOerFromCourse oer.id, label = "Remove" |> captionNowrap [ whiteText ] }

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
          |> el [ width fill, htmlClass "CloseInspectorOnClickOutside", onClickStopPropagation <| InspectCourseItem oer ]


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
  let
      optimiseButton =
        actionButtonWithIcon [ whiteText, paddingXY 12 10, Background.color orange, width fill, centerX ] IconLeft "directions_walk_white" "Optimise learning path" (Just PressedOptimiseLearningPath)

      undoSection =
        case model.courseInUndoBuffer of
          Nothing ->
            none

          Just courseInUndoBuffer ->
            [ "Our algorithm has changed the sequence of your items." |> captionWrap []
            , simpleButton [ Font.size 12, Font.color blue ] "Undo" (Just <| PressedUndoCourse courseInUndoBuffer)
            ]
            |> column [ spacing 15 ]
  in
      [ optimiseButton
      , undoSection
      ]
      |> column [ spacing 15 ]
