port module Ports exposing (..)

-- import Json.Encode as Encode
import Json.Decode as Decode

import Animation exposing (..)

import Model exposing (..)

port setBrowserFocus : String -> Cmd msg
port copyClipboard : String -> Cmd msg
port openModalAnimation : YoutubeEmbedParams -> Cmd msg
-- port embedYoutubePlayerOnResourcePage : YoutubeEmbedParams -> Cmd msg
-- port youtubeSeekTo : Float -> Cmd msg
-- port youtubeDestroyPlayer : Bool -> Cmd msg
port getOerCardPlaceholderPositions : Bool -> Cmd msg
port askPageScrollState : Bool -> Cmd msg
port startCurrentHtml5Video : Float -> Cmd msg

port modalAnimationStart : (BoxAnimation -> msg) -> Sub msg
port modalAnimationStop : (Int -> msg) -> Sub msg
port closePopup : (Int -> msg) -> Sub msg
port closeInspector : (Int -> msg) -> Sub msg
port popupTriggerPosition : (Point -> msg) -> Sub msg
port clickedOnDocument : (Int -> msg) -> Sub msg
port mouseOverChunkTrigger : (Float -> msg) -> Sub msg
-- port mouseMovedOnStoryTag : (Float -> msg) -> Sub msg
port timelineMouseEvent : (EventNameAndPosition -> msg) -> Sub msg
-- port youtubeVideoIsPlayingAtPosition : (Float -> msg) -> Sub msg
port html5VideoStarted : (Float -> msg) -> Sub msg
port html5VideoPaused : (Float -> msg) -> Sub msg
port html5VideoSeeked : (Float -> msg) -> Sub msg
port html5VideoStillPlaying : (Float -> msg) -> Sub msg
port html5VideoDuration : (Float -> msg) -> Sub msg
port pageScrolled : (PageScrollState -> msg) -> Sub msg
port receiveCardPlaceholderPositions : ((List OerCardPlaceholderPosition) -> msg) -> Sub msg
port receiveFlyingHeartRelativeStartPosition : (Point -> msg) -> Sub msg


type alias YoutubeEmbedParams =
  { modalId : String
  , videoId : String
  , videoStartPosition : Float
  , playWhenReady : Bool
  }
