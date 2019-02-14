module View.Pages.Search exposing (viewSearchPage)

import Url
import Dict

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)
import View.Inspector exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewSearchPage : Model -> SearchState -> PageWithModal
viewSearchPage model searchState =
  let
      modal =
        viewInspectorModalOrEmpty model
  in
      (viewSearchResults model searchState, modal)


viewSearchResults model searchState =
  case searchState.searchResults of
    Nothing ->
      viewLoadingSpinner

    Just oers ->
      let
          cards =
            oers
            |> oerCardGrid model
            |> List.map inFront

          attrs =
            [ padding 20, spacing 20, width fill, height fill, Border.color orange ] ++ cards
      in
          none
          |> el attrs


oerCardGrid model oers =
  let
      cardAtIndex index oer =
        let
            x =
              modBy 3 index

            y =
              index//3
        in
            viewOerCard model { x = x*400 |> toFloat, y = y*400 |> toFloat } oer
  in
      oers
      |> List.indexedMap cardAtIndex
      |> List.reverse -- Rendering the cards in reverse order so that popup menus (to the bottom and right) are rendered above the neighboring card, rather than below.
