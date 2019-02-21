module View.PageHeader exposing (viewPageHeader)

import Html
import Html.Attributes
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)

import Model exposing (..)

import View.Shared exposing (..)

import Msg exposing (..)


viewPageHeader : Model -> Element Msg
viewPageHeader model =
  let
      userMessage =
        case model.userMessage of
          Nothing ->
            []

          Just str ->
            [ str |> text |> el [ Background.color <| rgb 1 0.5 0.5, paddingXY 30 10, centerX ] |> below ]

      attrs =
        [ width fill
        , height (px pageHeaderHeight)
        , spacing 20
        , paddingEach { allSidesZero | top = 0, left = 16 }
        , Background.color <| rgb 1 1 1
        , borderBottom 1
        , Border.color <| rgb 0.8 0.8 0.8
        ] ++ userMessage
  in
      [ link [] { url = "/", label = image [ height (px 26) ] { src = imgPath "x5learn_logo.png", description = "X5Learn logo" } }
      ]
      |> row attrs
