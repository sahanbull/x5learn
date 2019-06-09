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
  | InspectOer Oer Float Float Bool
  | UninspectSearchResult
  | ModalAnimationStart BoxAnimation
  | ModalAnimationStop Int
  | RequestSession (Result Http.Error Session)
  | RequestOerSearch (Result Http.Error (List Oer))
  -- | RequestNextSteps (Result Http.Error (List Pathway))
  | RequestOers (Result Http.Error (Dict String Oer))
  | RequestGains (Result Http.Error (List Gain))
  | RequestWikichunkEnrichments (Result Http.Error (Dict OerUrl WikichunkEnrichment))
  | RequestSearchSuggestions (Result Http.Error (List String))
  | RequestSaveUserProfile (Result Http.Error String)
  | RequestSaveUserState (Result Http.Error String)
  | SetHover (Maybe String)
  | SetPopup Popup
  | ClosePopup
  | CloseInspector
  | TriggerSearch String
  | ClickedOnDocument
  | SelectSuggestion String
  | MouseOverChunkTrigger Float
  | YoutubeSeekTo Float
  | EditUserProfile UserProfileField String
  | SubmittedUserProfile
  | ChangedTextInNewNoteFormInOerNoteboard String String
  | SubmittedNewNoteInOerNoteboard String
  | PressedKeyInNewNoteFormInOerNoteboard String Int
  | ClickedQuickNoteButton String String
  | RemoveNote Posix
  | VideoIsPlayingAtPosition Float
  | SubmitPostRegistrationForm Bool
  | MouseOverEntity (Maybe String)
  | BubbleClicked Entity Int


type UserProfileField
  = FirstName
  | LastName


subscriptions : Model -> Sub Msg
subscriptions model =
  let
      isModalAnimating =
        if model.animationsPending |> Set.isEmpty then
           False
        else
          case model.modalAnimation of
            Nothing ->
              True

            Just animation ->
              if animation.frameCount<2 then
                True
              else
                False
  in
      ([ Browser.Events.onResize ResizeBrowser
      , Ports.modalAnimationStart ModalAnimationStart
      , Ports.modalAnimationStop ModalAnimationStop
      , Ports.closePopup (\_ -> ClosePopup)
      , Ports.closeInspector (\_ -> CloseInspector)
      , Ports.clickedOnDocument (\_ -> ClickedOnDocument)
      , Ports.mouseOverChunkTrigger MouseOverChunkTrigger
      , Ports.videoIsPlayingAtPosition VideoIsPlayingAtPosition
      , Time.every 500 ClockTick
      ] ++ (if anyEnrichmentsLoadedRecently model || isModalAnimating then [ Browser.Events.onAnimationFrame AnimationTick ] else []))
      |> Sub.batch
