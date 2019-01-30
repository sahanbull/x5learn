module View.Pages.NextSteps exposing (viewNextStepsPage)

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

import Msg exposing (..)

import Json.Decode as Decode


viewNextStepsPage : Model -> PageWithModal
viewNextStepsPage model =
  let
      playlists =
        model.nextSteps |> Maybe.withDefault []

      page =
        playlists
        |> List.map (viewPlaylist model)
        |> column [ width fill, height fill, spacing 50 ]
        |> el [ padding 50, width fill ]
  in
      (page, viewInspectorModalOrEmpty model)
