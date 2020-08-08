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
import View.Utility exposing (..)
import View.Card exposing (..)
import View.Inspector exposing (..)

import Msg exposing (..)

import Json.Decode as Decode

import I18Next exposing ( t, Delims(..) )


{-| Render a message saying that the site is down.
    Let's hope we'll never need this.
-}
viewMaintenancePage : Model -> PageWithInspector
viewMaintenancePage model =
  let
      message =
        [ (t model.translations "generic.lbl_greeting") ++ " 😊" |> headlineWrap []
        , (t model.translations "generic.lbl_website_maintenance_page") |> bodyWrap []
        ]
        |> column [ padding 20, spacing 30, width (px 440) ]

      page =
        message
        |> milkyWhiteCenteredContainer
  in
      (page, [])
