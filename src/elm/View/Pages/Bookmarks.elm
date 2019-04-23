module View.Pages.Bookmarks exposing (viewBookmarksPage)

import Url
import Dict
import Set

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

import Msg exposing (..)

import Json.Decode as Decode


viewBookmarksPage : Model -> PageWithModal
viewBookmarksPage model =
  let
      playlists =
        model.bookmarklists
        |> List.map (viewOerGrid model)
        |> List.filter (\playlist -> playlist /= none)

      page =
        if playlists |> List.isEmpty then
          viewCenterNote "Your notes will appear hear. Look inside a resource to create your first note."
        else
          playlists
          |> column [ width fill, height fill, spacing 20 ]
          |> el [ padding 50, width fill ]
  in
      (page, viewInspectorModalOrEmpty model)
