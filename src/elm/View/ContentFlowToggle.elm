module View.ContentFlowToggle exposing (viewContentFlowToggle)

import Html
import Html.Attributes as Attributes
import Html.Events as Events

import Element exposing (..)
import Element.Events as Events exposing (onClick)

import Model exposing (..)
import Msg exposing (..)
import View.Utility exposing (..)


viewContentFlowToggle : Model -> Element Msg
viewContentFlowToggle model =
  [ "ContentFlow is "++(if isContentFlowEnabled model then "ON" else "OFF") |> bodyNoWrap [ width fill ]
  , viewSwitch <| isContentFlowEnabled model
  ]
  |> row [ width fill, spacing 10, onClick ToggleContentFlow ]


viewSwitch : Bool -> Element Msg
viewSwitch isEnabled =
  Html.label [ Attributes.class "ToggleSwitch" ]
    [ Html.div (if isEnabled then [ Attributes.class "ToggleEnabled" ] else []) []
    , Html.span [ Attributes.class "ToggleSlider ToggleSliderRound" ] []
    ]
  |> html
