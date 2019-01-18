port module Ports exposing (..)

import Json.Encode as Encode

port copyClipboard : String -> Cmd msg
port inspectSearchResult : String -> Cmd msg
port modalAnim : (Encode.Value -> msg) -> Sub msg
