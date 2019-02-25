module View.Pages.History exposing (viewHistoryPage)

import Url
import Dict
import Set
import List.Extra

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

import Msg exposing (..)

import Json.Decode as Decode


viewHistoryPage : Model -> PageWithModal
viewHistoryPage model =
  let
      page =
        case model.viewedFragments of
          Nothing ->
            viewLoadingSpinner

          Just fragmentsOrEmpty ->
            case fragmentsOrEmpty of
              [] ->
                viewCenterNote "Your viewed items will appear here"

              fragments ->
                fragments
                  |> List.map .oer
                  |> List.Extra.uniqueBy .url
                  |> List.reverse
                  |> Playlist "Watched recently"
                  |> viewPlaylist model
                  |> List.singleton
                  |> column [ width fill, height fill, spacing 50 ]
                  |> el [ padding 50, width fill ]
  in
      (page, viewInspectorModalOrEmpty model)
