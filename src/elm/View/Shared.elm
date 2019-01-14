module View.Shared exposing (..)

import Html.Attributes
import Html.Events

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Json.Decode

import Model exposing (..)
import Msg exposing (..)


jumboText =
  Font.size 48


largeText =
  Font.size 24


mediumText =
  Font.size 18


smallText =
  Font.size 16


primaryDark =
  Font.color <| rgba 0 0 0 0.87


primaryWhite =
  Font.color white


x5color =
  Font.color <| rgb255 82 134 148


pageHeaderHeight =
  40


paddingTop px =
  paddingEach { allSidesZero | top = px }


paddingBottom px =
  paddingEach { allSidesZero | bottom = px }


bigButtonPadding =
  paddingXY 13 10


borderBottom px =
  Border.widthEach { allSidesZero | bottom = px }


allSidesZero =
  { top = 0
  , right = 0
  , bottom = 0
  , left = 0
  }


navLink url label =
  link [] { url = url, label = label }


wrap attrs str =
  [ text str ] |> paragraph attrs


white =
  rgb 1 1 1


orange =
  rgb255 255 150 0


grey80 =
  grey 80


grey160 =
  grey 160


grey value =
  rgb255 value value value


style propertyName value =
  Html.Attributes.style propertyName value
  |> htmlAttribute


pageBodyBackground =
  Background.image <| imgPath "bg.jpg"


imgPath str =
  "static/dist/img/" ++ str


svgPath str =
  "static/dist/img_svg/" ++ str ++ ".svg"


onEnter : Msg -> Attribute Msg
onEnter msg =
  let
      isEnter code =
        if code == 13 then
          Json.Decode.succeed msg
        else
          Json.Decode.fail "not ENTER"
  in
      Html.Events.on "keydown" (Json.Decode.andThen isEnter Html.Events.keyCode)
      |> htmlAttribute
