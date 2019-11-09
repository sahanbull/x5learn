module View.Pages.Search exposing (viewSearchPage)

import Url
import Dict
import Set

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewSearchPage : Model -> SearchState -> PageWithModal
viewSearchPage model searchState =
  let
      modal =
        viewInspectorModalOrEmpty model

      content =
        viewBody model searchState
  in
      (content, modal)


viewBody model searchState =
  case searchState.searchResults of
    Nothing ->
      viewLoadingSpinner

    Just [] ->
      "No results were found for \"" ++ searchState.lastSearch ++ "\". Please try a different search term." |> viewCenterNote

    Just oerIds ->
      Playlist "" oerIds
      |> viewOerGrid model
      |> el [ width fill, height fill, paddingTRBL 0 0 100 0 ]
