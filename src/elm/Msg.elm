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
  | NewSearch
  | ResizeBrowser Int Int
  | InspectSearchResult Oer
  | UninspectSearchResult
  | ModalAnimationStart BoxAnimation
  | ModalAnimationStop Int
  | RequestOerSearch (Result Http.Error (List Oer))
  | RequestNextSteps (Result Http.Error (List Playlist))
  | RequestViewedFragments (Result Http.Error (List Fragment))
  | RequestChunks (Result Http.Error (Dict String (List Chunk)))
  | SetHover (Maybe String)
  | OpenSaveToBookmarklistMenu InspectorState
  | AddToBookmarklist Playlist Oer
  | RemoveFromBookmarklist Playlist Oer
  | SetChunkPopover (Maybe (List String))


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
      , Time.every 500 ClockTick
      ] ++ anim)
      |> Sub.batch
