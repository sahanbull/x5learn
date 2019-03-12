module Msg exposing (..)

import Browser
import Browser.Events
import Url
import Json.Encode as Encode
import Http
import Time exposing (Posix)
import Dict exposing (Dict)
import Set

import Animation exposing (..)
import Model exposing (..)
import Ports

type Msg
  = NoOp
  | LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ClockTick Posix
  | AnimationTick Posix
  | ChangeSearchText String
  | SubmitSearch
  | ResizeBrowser Int Int
  | InspectSearchResult Oer
  | UninspectSearchResult
  | ModalAnimationStart BoxAnimation
  | ModalAnimationStop Int
  | RequestOerSearch (Result Http.Error (List Oer))
  | RequestNextSteps (Result Http.Error (List Pathway))
  | RequestViewedFragments (Result Http.Error (List Fragment))
  | RequestGains (Result Http.Error (List Gain))
  | RequestEntityDescriptions (Result Http.Error (Dict String String))
  | SetHover (Maybe String)
  | OpenSaveToBookmarklistMenu InspectorState
  | AddToBookmarklist Playlist Oer
  | RemoveFromBookmarklist Playlist Oer
  | SetPopup Popup
  | ClosePopup
  | CloseInspector
  | ShowFloatingDefinition String
  | TriggerSearch String


subscriptions : Model -> Sub Msg
subscriptions model =
  let
      anim =
        if model.animationsPending |> Set.isEmpty then
          []
        else
          case model.modalAnimation of
            Nothing ->
              [ Browser.Events.onAnimationFrame AnimationTick ] --- TODO consider switching off when no animations are playing

            Just animation ->
              if animation.frameCount<2 then
                [ Browser.Events.onAnimationFrame AnimationTick ] --- TODO consider switching off when no animations are playing
              else
                []
  in
      ([ Browser.Events.onResize ResizeBrowser
      , Ports.modalAnimationStart ModalAnimationStart
      , Ports.modalAnimationStop ModalAnimationStop
      , Ports.closePopup (\_ -> ClosePopup)
      , Ports.closeInspector (\_ -> CloseInspector)
      , Time.every 500 ClockTick
      ] ++ anim)
      |> Sub.batch
