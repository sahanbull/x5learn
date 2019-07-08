module View.Pages.Maintenance exposing (viewMaintenancePage)

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


viewMaintenancePage : PageWithModal
viewMaintenancePage =
  let
      note =
        [ "Hey 😊" |> headlineWrap []
        , "This website is currently undergoing a major update during which the site will be offline. Please check back in a few days." |> bodyWrap []
        ]
        |> column [ padding 20, spacing 30, width (px 440) ]

      page =
        note
        |> milkyWhiteCenteredContainer
  in
      (page, [])
