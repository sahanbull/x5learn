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
      oerCards =
        model.oerNoteboards
        |> Dict.toList
        |> List.filter (\(oerId, noteboard) -> isOerLoaded model oerId && List.length noteboard>0)
        |> List.filterMap (\(oerId, _) -> model.cachedOers |> Dict.get oerId)
        |> List.indexedMap (viewResourceCardWithNotes model)

      content =
        if model.requestingOers then
          viewLoadingSpinner
        else
          case oerCards of
            [] ->
              viewCenterNote "Your notes will appear here. Look at some resources to create your first note."

            cards ->
              cards
              |> column [ width fill, height fill, spacing 150 ]

      page =
        content
        |> el [ centerY, width fill, paddingXY 20 140 ]
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


viewResourceCardWithNotes : Model -> Int -> Oer -> Element Msg
viewResourceCardWithNotes model index oer =
  let
      rowHeight =
        cardHeight + verticalSpacingBetweenCards

      card =
        viewOerCard model [] (Point 15 15) ("notes-"++ (String.fromInt index)) oer
        |> inFront

      notes =
        getOerNoteboard model oer.id
        |> List.map (viewNoteCard model oer)
        |> column [ spacing 15 ]

      cardPlaceholder =
        none
        |> el [ width (px cardWidth), height (cardHeight + verticalSpacingBetweenCards |> px) ]

      content =
        [ cardPlaceholder
        , notes
        ]
        |> row [ spacing 15, padding 15 ]
  in
      content
      |> el [  spacing 20, width (px boxWidth), Border.rounded 2, card, Background.color semiTransparentWhite, centerX ]


boxWidth =
  960
