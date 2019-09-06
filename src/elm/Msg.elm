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
  | RequestRecentViews (Result Http.Error (List OerId))
  | RequestNotes (Result Http.Error (List Note))
  | RequestDeleteNote (Result Http.Error String)
  | RequestOerSearch (Result Http.Error (List Oer))
  | RequestOers (Result Http.Error (List Oer))
  | RequestGains (Result Http.Error (List Gain))
  | RequestWikichunkEnrichments (Result Http.Error (List WikichunkEnrichment))
  | RequestEntityDefinitions (Result Http.Error (Dict String String))
  | RequestAutocompleteTerms (Result Http.Error (List String))
  | RequestSaveUserProfile (Result Http.Error String)
  | RequestLabStudyLogEvent (Result Http.Error String)
  | RequestResource (Result Http.Error Oer)
  | RequestResourceRecommendations (Result Http.Error (List Oer))
  | RequestCollectionsSearchPrediction (Result Http.Error CollectionsSearchPredictionResponse)
  | RequestSendResourceFeedback (Result Http.Error String)
  | RequestSaveAction (Result Http.Error String)
  | RequestSaveNote (Result Http.Error String)
  | SetHover (Maybe OerId)
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
  | ChangedTextInNewNoteFormInOerNoteboard OerId String
  | ChangedTextInResourceFeedbackForm OerId String
  | SubmittedNewNoteInOerNoteboard OerId
  | SubmittedResourceFeedback OerId String
  | PressedKeyInNewNoteFormInOerNoteboard OerId Int
  | ClickedQuickNoteButton OerId String
  | RemoveNote Note
  | VideoIsPlayingAtPosition Float
  | OverviewTagMouseOver EntityId OerId
  | OverviewTagMouseOut
  | OverviewTagLabelMouseOver EntityId OerId
  | OverviewTagLabelClicked OerId
  | PageScrolled PageScrollState
  | OerCardPlaceholderPositionsReceived (List OerCardPlaceholderPosition)
  | StartLabStudyTask LabStudyTask
  | StoppedLabStudyTask
  | SelectResourceSidebarTab ResourceSidebarTab
  | MouseMovedOnStoryTag Float
  | SelectedOverviewType OverviewType
  | SelectedOerCollection String Bool
  | ToggledAllOerCollections Bool
  | MouseEnterMentionInBubbblogramOverview OerId EntityId MentionInOer
  | ToggleCollectionsMenu


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
      , Ports.mouseMovedOnStoryTag MouseMovedOnStoryTag
      , Ports.videoIsPlayingAtPosition VideoIsPlayingAtPosition
      , Ports.pageScrolled PageScrolled
      , Ports.receiveCardPlaceholderPositions OerCardPlaceholderPositionsReceived
      , Time.every 500 ClockTick
      ] ++ (if anyBubblogramsAnimating model || isModalAnimating then [ Browser.Events.onAnimationFrame AnimationTick ] else []))
      |> Sub.batch
