module View.PatchSvg exposing (..)

-- adding functionality that is missing from
-- https://package.elm-lang.org/packages/elm/svg/1.0.1/Svg

import Json.Decode

import Svg exposing (Attribute)
import Svg.Events


onMouseLeave : msg -> Attribute msg
onMouseLeave msg =
  Svg.Events.on "mouseleave" (Json.Decode.succeed msg)
