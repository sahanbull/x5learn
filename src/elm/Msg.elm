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
  = Initialized Url.Url
  | LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ClockTick Posix
  | AnimationTick Posix
  | ChangeSearchText String
  | ResizeBrowser Int Int
  | InspectSearchResult Oer Float
  | UninspectSearchResult
  | ModalAnimationStart BoxAnimation
  | ModalAnimationStop Int
  | RequestSession (Result Http.Error Session)
  | RequestOerSearch (Result Http.Error (List Oer))
  | RequestNextSteps (Result Http.Error (List Pathway))
  | RequestViewedFragments (Result Http.Error (List Fragment))
  | RequestGains (Result Http.Error (List Gain))
  | RequestEntityDescriptions (Result Http.Error (Dict String String))
  | RequestSearchSuggestions (Result Http.Error (List String))
  | RequestSaveUserProfile (Result Http.Error String)
  | SetHover (Maybe String)
  | OpenSaveToBookmarklistMenu InspectorState
  | AddToBookmarklist Playlist Oer
  | RemoveFromBookmarklist Playlist Oer
  | SetPopup Popup
  | ClosePopup
  | CloseInspector
  | TriggerSearch String
  | ClickedOnDocument
  | SelectSuggestion String
  | MouseOverChunkTrigger Float
  | YoutubeSeekTo Float
  | EditUserProfile UserProfileField String
  | ClickedSaveUserProfile
  | EditDiaryEntry String String
  | SaveDiaryEntry String
  | KeyPressOnDiary String Int


type UserProfileField
  = FirstName
  | LastName


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
      , Ports.clickedOnDocument (\_ -> ClickedOnDocument)
      , Ports.mouseOverChunkTrigger MouseOverChunkTrigger
      , Time.every 500 ClockTick
      ] ++ anim)
      |> Sub.batch
