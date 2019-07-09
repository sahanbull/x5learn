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


viewNotesPage : Model -> UserState -> PageWithModal
viewNotesPage model userState =
  let
      noteCards =
        userState.oerNoteboards
        |> Dict.toList
        |> List.concatMap (\(oerUrl, noteboard) -> noteboard |> List.map (\note -> (note, oerUrl |> getCachedOerWithBlankDefault model)))
        |> List.sortBy (\(note, _) -> (posixToMillis note.time))
        |> List.reverse
        |> List.map (viewNoteCard model)

      content =
        if model.requestingOers then
          viewLoadingSpinner
        else
          case noteCards of
            [] ->
              viewCenterNote "Your notes will appear here. Look at some resources to create your first note."

            cards ->
              cards
              |> column [ width fill, height fill, spacing 20 ]

      page =
        content
        |> el [ centerX, centerY ]
  in
      (page, viewInspectorModalOrEmpty model userState)


viewNoteCard model (note, oer) =
  let
      date =
        note.time
        |> humanReadableRelativeTime model
        |> captionNowrap [ greyTextDisabled, alignRight ]
        |> el [ width (px 60) ]

      oerTitle =
        oer.title
        |> bodyWrap [ Font.bold ]

      card =
        [ avatarImage |> el [ alignTop ]
        , note.text |> bodyWrap [ width (px 400) ]
        , oerTitle |> el [ paddingLeft 40, width fill ]
        , date
        ]
        |> row [ spacing 10, width (px 800) ]
  in
      button [ htmlClass "materialCard", htmlClass "CloseInspectorOnClickOutside", padding 10 ] { onPress = openInspectorOnPress model oer, label = card }
