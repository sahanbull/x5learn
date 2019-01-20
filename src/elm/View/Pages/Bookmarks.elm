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

import Msg exposing (..)

import Json.Decode as Decode


viewBookmarksPage : Model -> PageWithModal
viewBookmarksPage model =
  let
      modal =
        []
  in
      ("Bookmarks page goes here" |> text, modal)
