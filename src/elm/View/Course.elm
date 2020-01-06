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
        heading =
          -- "Workspace" |> headlineWrap []
          none

        items =
          model.course.items
          |> List.indexedMap (viewCourseItem model)
          |> column [ spacing 20, paddingTop 20 ]
    in
        [ heading
        , items
        ]
        |> column [ spacing 10 ]


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
              button buttonAttrs { onPress = Just <| MovedCourseItemDown (index-1), label = "Move up" |> captionNowrap [ whiteText ] }

          moveDownButton =
            if index==nCourseItems-1 then
              none
            else
              button buttonAttrs { onPress = Just <| MovedCourseItemDown index, label = "Move down" |> captionNowrap [ whiteText ] }

          topRow =
            [ index+1 |> String.fromInt |> bodyNoWrap []
            , moveUpButton
            , moveDownButton
            ]
            |> row [ width fill, spacing 10 ]

          miniCard =
            [ topRow
            , oer.title |> bodyWrap []
            ]
            |> column [ width fill, spacing 10, paddingTop 10, borderTop 1, Border.color <| greyDivider ]
      in
          miniCard
          |> el [ width fill, htmlClass "CloseInspectorOnClickOutside", onClickNoBubble <| InspectCourseItem oer ]
