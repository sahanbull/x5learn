module View.ContentFlowToggle exposing (viewContentFlowToggle)

import Html
import Html.Attributes as Attributes
import Html.Events as Events

import Element exposing (..)
import Element.Events as Events exposing (onClick)

import Model exposing (..)
import Msg exposing (..)
import View.Utility exposing (..)
import View.ToggleIndicator exposing (..)


{-| Render the widget for the user to switch ContentFlow on and off
-}
viewContentFlowToggle : Model -> Element Msg
viewContentFlowToggle model =
  [ "Flow is "++(if isContentFlowEnabled model then "ON" else "OFF") |> bodyNoWrap [ width fill ]
  , viewToggleIndicator (isContentFlowEnabled model) ""
  ]
  |> row [ width fill, spacing 10, onClick ToggleContentFlow ]
