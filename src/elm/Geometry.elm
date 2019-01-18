module Geometry exposing (..)

import Json.Decode as Decode exposing (Decoder, float)


type alias ModalAnimationCoordinates =
  { card: BoxCoordinates
  , modal: BoxCoordinates
  }


type alias BoxCoordinates =
  { x : Float
  , y : Float
  }


widthDecoder : Decoder Float
widthDecoder =
  float
