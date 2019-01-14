module View.PageHeader exposing (viewPageHeader)

import Html
import Html.Attributes
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font

import Model exposing (..)

import View.Shared exposing (..)

import Msg exposing (..)


viewPageHeader : Model -> Element Msg
viewPageHeader model =
  [ link [] { url = "/", label = image [ height (px 26) ] { src = imgPath "x5learn_logo.png", description = "X5Learn logo" } }
  ]
  |> row [ width fill, height (px pageHeaderHeight), spacing 20, paddingEach { allSidesZero | top = 0, left = 16 }, Background.color <| rgb 1 1 1, borderBottom 1, Border.color <| rgb 0.8 0.8 0.8 ]
