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

import I18Next exposing ( t, Delims(..) )

import Msg exposing (..)


{-| Render the user's course as a list of items
-}
viewCourse : Model -> Element Msg
viewCourse model =
  if model.course.items==[] then
      none
  else
    case model.playlist of
        Nothing ->
            none
    
        Just playlist ->
          let
              items =
                model.course.items
                |> List.indexedMap (viewCourseItem model)
                |> column [ spacing 20, paddingTop 20, width fill, htmlClass "PlaylistItemsContainer" ]
          in
              [ items
              , viewCoursePathFinderContainer model
              ]
              |> column [ spacing 30, width fill ]
            
    


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
              button (buttonAttrs ++ [onClickStopPropagation (MovedCourseItemDown (index-1))]) { onPress = Nothing, label = (t model.translations "playlist.btn_move_material") ++ " ↑" |> captionNowrap [ whiteText ] }

          moveDownButton =
            if index==nCourseItems-1 || isLabStudy1 model then
              none
            else
              button (buttonAttrs ++ [onClickStopPropagation (MovedCourseItemDown index)]) { onPress = Nothing, label = (t model.translations "playlist.btn_move_material") ++ " ↓" |> captionNowrap [ whiteText ] }

          deleteButton =
            -- button [ alignRight ] { onPress = Just <| RemovedOerFromCourse oer.id, label = "Remove" |> captionNowrap [ greyText ] }
            -- We could use a button here but we don't want the click event to bubble up to the miniCard.
            -- One quick way to prevent this is to use stopPropagation instead of elm-ui's button element
            (t model.translations "playlist.btn_remove_material")
            |> captionNowrap [ greyText, alignRight, htmlClass "CursorPointer", onClickStopPropagation (RemovedOerFromCourse oer.id) ]

          topRow =
            if getPlaylistTitle model oer.id == Nothing then
              oer.title |> bodyWrap []
            else
              Maybe.withDefault oer.title (getPlaylistTitle model oer.id) |> bodyWrap []

          buttonRow =
            [ moveUpButton
            , moveDownButton
            , deleteButton
            ]
            |> row [ width fill, spacing 10 ]

          miniCard =
            [ topRow
            , buttonRow
            ]
            |> column [ width fill, spacing 10, padding 10, buttonRounding, Border.width 1, Border.color greyDivider, smallShadow ]
      in
          miniCard
          |> el [ width fill, htmlClass "PreventClosingInspectorOnClick", onClickStopPropagation <| ClickedOnPlaylistItem oer ]


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
        actionButtonWithIcon [ whiteText, paddingXY 12 10, width fill, centerX ] [ Background.color electricBlue, width fill, buttonRounding ] IconLeft 1 "directions_walk_white" (t model.translations "playlist.btn_optimize_learning_path") (Just PressedOptimiseLearningPath)

      Just Loading ->
        viewLoadingSpinner

      Just (UndoAvailable savedPreviousCourse) ->
        let
            content =
              if savedPreviousCourse == model.course then
                [ t model.translations "alerts.lbl_learning_path_already_optimized" |> captionWrap [ whiteText ]
                ]
              else
                [ t model.translations "alerts.lbl_learning_path_optimized" |> captionWrap [ whiteText ]
                , simpleButton [ Font.size 12, Font.color electricBlue ] (t model.translations "playlist.btn_undo_optimize_learning_path") (Just <| PressedUndoCourse savedPreviousCourse)
                ]
        in
            content
            |> column [ spacing 15, padding 10, Background.color <| grey 50, Border.rounded 10 ]

getPlaylistTitle : Model -> OerId -> Maybe String
getPlaylistTitle model oerId =
  case model.playlist of 
    Nothing ->
      Nothing

    Just playlist ->
      let

        playlistItemData =
          List.head ( List.filter (\x -> x.oerId == oerId ) playlist.playlistItemData)

      in
        case playlistItemData of
            Nothing ->
              Nothing
                
            Just itemData ->
              Just itemData.title
                
        