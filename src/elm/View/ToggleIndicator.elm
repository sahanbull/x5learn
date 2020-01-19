module View.ToggleIndicator exposing (viewToggleIndicator)

import Html
import Html.Attributes as Attributes
import Html.Events as Events

import Element exposing (..)
import Element.Events as Events exposing (onClick)

import Model exposing (..)
import Msg exposing (..)
import View.Utility exposing (..)


{-| Render a label for the user see whether a toggle is switched  on or off
-}
viewToggleIndicator : Bool -> String -> Element Msg
viewToggleIndicator isEnabled sliderClassAttr =
  Html.label [ Attributes.class "ToggleSwitch" ]
    [ Html.div (if isEnabled then [ Attributes.class "ToggleEnabled" ] else []) []
    , Html.span [ Attributes.class ("ToggleSlider ToggleSliderRound "++sliderClassAttr) ] []
    ]
  |> html
