module View.Pages.Notes exposing (viewNotesPage)

import Url
import Dict
import Set

import Time exposing (posixToMillis)

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import Animation exposing (..)
import View.Shared exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)
import View.Noteboard exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewNotesPage : Model -> PageWithModal
viewNotesPage model =
  let
      oerBoxesAndCards =
        model.oerNoteboards
        |> Dict.toList
        |> List.filter (\(oerId, noteboard) -> isOerLoaded model oerId && List.length noteboard>0)
        |> List.filterMap (\(oerId, _) -> model.cachedOers |> Dict.get oerId)
        |> List.indexedMap (viewOerBoxAndDetachedCard model)

      oerBoxes =
        oerBoxesAndCards
        |> List.map .box

      oerCards =
        oerBoxesAndCards
        |> List.filterMap .card

      content =
        if model.requestingOers then
          viewLoadingSpinner
        else
          case oerBoxes of
            [] ->
              viewCenterNote "Your notes will appear here. Look at some resources to create your first note."

            boxes ->
              boxes
              |> column [ width fill, height fill, spacing 50 ]

      page =
        content
        |> el ([ centerY, width fill, paddingXY 20 140 ] ++ oerCards)
  in
      (page, viewInspectorModalOrEmpty model)


viewNoteCard model oer note =
  let
      date =
        note.time
        |> humanReadableRelativeTime model
        |> captionNowrap [ greyTextDisabled, alignRight ]
        |> el [ width (px 60) ]

      card =
        [ avatarImage |> el [ alignTop ]
        , note.text |> bodyWrap [ width fill ]
        , date
        ]
        |> row [ spacing 10, width (boxWidth - cardWidth - 69 |> px) ]
  in
      button [ htmlClass "materialCard", htmlClass "CloseInspectorOnClickOutside", padding 10 ] { onPress = openInspectorOnPress model oer, label = card }


viewOerBoxAndDetachedCard : Model -> Int -> Oer -> { box : Element Msg, card : Maybe (Attribute Msg) }
viewOerBoxAndDetachedCard model index oer =
  let
      rowHeight =
        cardHeight + verticalSpacingBetweenCards

      card =
        case model.oerCardPlaceholderPositions |> List.filter (\{oerId} -> oerId==oer.id) |> List.head of
          Nothing ->
            Nothing

          Just {x, y } ->
            viewOerCard model [] (Point (x - navigationDrawerWidth) (y - pageHeaderHeight)) ("notes-"++ (String.fromInt index)) oer
            |> inFront
            |> Just

      notes =
        getOerNoteboard model oer.id
        |> List.map (viewNoteCard model oer)
        |> column [ spacing 15 ]

      cardPlaceholder =
        none
        |> el [ width (px cardWidth), height (cardHeight |> px), htmlClass "OerCardPlaceholder", htmlDataAttribute <| String.fromInt oer.id ]

      box =
        [ cardPlaceholder
        , notes
        ]
        |> row [ spacing 15, padding 15 ]
        |> el [  spacing 20, width (px boxWidth), Border.rounded 2, Background.color semiTransparentWhite, centerX ]
  in
      { box = box, card = card }


boxWidth =
  960
