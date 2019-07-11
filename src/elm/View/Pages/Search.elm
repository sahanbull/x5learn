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

    Just [] ->
      -- "Sorry, no results were found for \""++ searchState.lastSearch ++"\"" |> viewCenterNote
      -- "No results were found for \"" ++ searchState.lastSearch ++ "\". Try using the topic suggestions." |> viewCenterNote
      "No results were found for \"" ++ searchState.lastSearch ++ "\". Please try a different search term." |> viewCenterNote

    Just oerUrls ->
      -- Playlist ("Search results for \""++ searchState.lastSearch ++"\"") oerUrls
      (if isLabStudy1 model then
        Playlist (searchState.lastSearch ++" ("++(oerUrls |> List.length |> String.fromInt) ++ " video" ++ (if List.length oerUrls == 1 then "" else "s")++")") oerUrls
      else
        Playlist ((oerUrls |> List.length |> String.fromInt) ++ " result" ++ (if List.length oerUrls == 1 then "" else "s") ++ " for \""++ searchState.lastSearch ++"\"") oerUrls
      )
      |> viewOerGrid model
      |> el [ width fill, paddingTRBL 0 0 100 0 ]
