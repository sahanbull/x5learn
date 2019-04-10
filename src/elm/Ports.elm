port module Ports exposing (..)

-- import Json.Encode as Encode
import Json.Decode as Decode

import Animation exposing (..)

port setBrowserFocus : String -> Cmd msg
port copyClipboard : String -> Cmd msg
port openModalAnimation : InspectorParams -> Cmd msg
port modalAnimationStart : (BoxAnimation -> msg) -> Sub msg
port modalAnimationStop : (Int -> msg) -> Sub msg
port closePopup : (Int -> msg) -> Sub msg
port closeInspector : (Int -> msg) -> Sub msg
port popupTriggerPosition : (Point -> msg) -> Sub msg
port clickedOnDocument : (Int -> msg) -> Sub msg
port mouseOverChunkTrigger : (Float -> msg) -> Sub msg


type alias InspectorParams =
  { modalId : String
  , videoId : String
  , startSeconds : Float
  }
