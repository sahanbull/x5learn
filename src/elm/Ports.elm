port module Ports exposing (..)

-- import Json.Encode as Encode
import Json.Decode as Decode

import Animation exposing (BoxAnimation)

port copyClipboard : String -> Cmd msg
port openModalAnimation : String -> Cmd msg
port modalAnimationStart : (BoxAnimation -> msg) -> Sub msg
port modalAnimationStop : (Int -> msg) -> Sub msg
