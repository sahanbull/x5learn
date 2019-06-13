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
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewSearchPage : Model -> UserState -> SearchState -> PageWithModal
viewSearchPage model userState searchState =
  let
      modal =
        viewInspectorModalOrEmpty model userState
  in
      (viewSearchResults model userState searchState, modal)


viewSearchResults model userState searchState =
  case searchState.searchResults of
    Nothing ->
      viewLoadingSpinner

    Just [] ->
      -- "Sorry, no results were found for \""++ searchState.lastSearch ++"\"" |> viewCenterNote
      "No results were found for \"" ++ searchState.lastSearch ++ "\". Try using the topic suggestions." |> viewCenterNote

    Just oerUrls ->
      -- Playlist ("Search results for \""++ searchState.lastSearch ++"\"") oerUrls
      Playlist ((oerUrls |> List.length |> String.fromInt) ++ " result" ++ (if List.length oerUrls == 1 then "" else "s") ++ " for \""++ searchState.lastSearch ++"\"") oerUrls
      |> viewOerGrid model userState
      |> el [ width fill, paddingTRBL 35 0 100 0 ]
