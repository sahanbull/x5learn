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
import View.Utility exposing (..)
import View.SearchWidget exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


{-| Render the search page, mainly including the search results
    Note that the search field is part of the NavigationDrawer
-}
viewSearchPage : Model -> SearchState -> PageWithInspector
viewSearchPage model searchState =
  let
      inspector =
        viewInspector model

      content =
        viewBody model searchState
  in
      (content, inspector)


{-| Render the main part of the search pge
-}
viewBody : Model -> SearchState -> Element Msg
viewBody model searchState =
  case searchState.searchResults of
    Nothing ->
      viewLoadingSpinner

    Just [] ->
      "No results were found for \"" ++ searchState.lastSearchText ++ "\". Please try a different search term." |> viewCenterMessage

    Just oerIds ->
      if isLabStudy1 model && model.currentTaskName==Nothing then
        "Please wait for the researcher's instructions." |> viewCenterMessage
      else
        Playlist "" oerIds
        |> viewOerGrid model
        |> el [ width fill, height fill, paddingBottom 100 ]
