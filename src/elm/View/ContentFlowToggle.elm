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

import I18Next exposing ( t, Delims(..) )


{-| Render the widget for the user to switch ContentFlow on and off
-}
viewContentFlowToggle : Model -> Element Msg
viewContentFlowToggle model =
  [ (t model.translations "generic.lbl_content_flow") ++(if isContentFlowEnabled model then (t model.translations "generic.btn_content_flow_on") else (t model.translations "generic.btn_content_flow_off")) |> bodyNoWrap [ width fill ]
  , viewToggleIndicator (isContentFlowEnabled model) ""
  ]
  |> row [ width fill, spacing 10, onClick ToggleContentFlow ]
