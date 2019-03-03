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
import View.Card exposing (..)
import View.Inspector exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewNextStepsPage : Model -> PageWithModal
viewNextStepsPage model =
  case model.nextSteps of
    Nothing ->
      (viewLoadingSpinner, [])

    Just pathways ->
      let
          page =
            pathways
            |> List.map (viewPathway model)
            |> column [ width fill, height fill, spacing 70 ]
            |> el [ padding 50, width fill ]
      in
          (page, viewInspectorModalOrEmpty model)
