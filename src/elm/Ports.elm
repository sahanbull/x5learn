port module Ports exposing (..)

-- import Json.Encode as Encode
import Json.Decode as Decode

import Animation exposing (..)

import Model exposing (..)

{-|  This module defines the ports for communication with JavaScript.
     Outgoing ports are defined below.
-}
port setBrowserFocus : String -> Cmd msg
port copyClipboard : String -> Cmd msg
port openInspectorAnimation : VideoEmbedParams -> Cmd msg
port embedYoutubePlayerOnResourcePage : VideoEmbedParams -> Cmd msg
-- port youtubeSeekTo : Float -> Cmd msg
-- port youtubeDestroyPlayer : Bool -> Cmd msg
port getOerCardPlaceholderPositions : Bool -> Cmd msg
port askPageScrollState : Bool -> Cmd msg
port startCurrentHtml5Video : Float -> Cmd msg


{-| Incoming ports are defined below
-}
port inspectorAnimationStart : (BoxAnimation -> msg) -> Sub msg
port inspectorAnimationStop : (Int -> msg) -> Sub msg
port closePopup : (Int -> msg) -> Sub msg
port closeInspector : (Int -> msg) -> Sub msg
port popupTriggerPosition : (Point -> msg) -> Sub msg
port mouseOverChunkTrigger : (Float -> msg) -> Sub msg
port mouseMovedOnTopicLane : (Float -> msg) -> Sub msg
port timelineMouseEvent : (EventNameAndPosition -> msg) -> Sub msg
port youtubeVideoIsPlayingAtPosition : (Float -> msg) -> Sub msg
port html5VideoStarted : (Float -> msg) -> Sub msg
port html5VideoPaused : (Float -> msg) -> Sub msg
port html5VideoSeeked : (Float -> msg) -> Sub msg
port html5VideoStillPlaying : (Float -> msg) -> Sub msg
port pageScrolled : (PageScrollState -> msg) -> Sub msg
port receiveCardPlaceholderPositions : ((List OerCardPlaceholderPosition) -> msg) -> Sub msg
