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
  | InspectOer Oer Float Bool
  | InspectCourseItem Oer
  | UninspectSearchResult
  | ModalAnimationStart BoxAnimation
  | ModalAnimationStop Int
  | RequestSession (Result Http.Error Session)
  -- | RequestFavorites (Result Http.Error (List OerId))
  | RequestVideoUsages (Result Http.Error (Dict String (List Range)))
  -- | RequestNotes (Result Http.Error (List Note))
  -- | RequestDeleteNote (Result Http.Error String)
  | RequestOerSearch (Result Http.Error (List Oer))
  | RequestOers (Result Http.Error (List Oer))
  | RequestFeatured (Result Http.Error (List Oer))
  | RequestWikichunkEnrichments (Result Http.Error (List WikichunkEnrichment))
  | RequestEntityDefinitions (Result Http.Error (Dict String String))
  -- | RequestAutocompleteTerms (Result Http.Error (List String))
  | RequestSaveUserProfile (Result Http.Error String)
  | RequestLabStudyLogEvent (Result Http.Error String)
  -- | RequestResource (Result Http.Error Oer)
  -- | RequestResourceRecommendations (Result Http.Error (List Oer))
  -- | RequestSendResourceFeedback (Result Http.Error String)
  | RequestSaveAction (Result Http.Error String)
  -- | RequestSaveNote (Result Http.Error String)
  | SetHover (Maybe OerId)
  | SetPopup Popup
  | ClosePopup
  | CloseInspector
  | TriggerSearch String
  | ClickedOnDocument
  | SelectSuggestion String
  | MouseOverChunkTrigger Float
  -- | YoutubeSeekTo Float
  | EditUserProfile UserProfileField String
  | SubmittedUserProfile
  -- | ChangedTextInNewNoteFormInOerNoteboard OerId String
  -- | ChangedTextInResourceFeedbackForm OerId String
  -- | SubmittedNewNoteInOerNoteboard OerId
  -- | SubmittedResourceFeedback OerId String
  -- | PressedKeyInNewNoteFormInOerNoteboard OerId Int
  -- | ClickedQuickNoteButton OerId String
  -- | RemoveNote Note
  | YoutubeVideoIsPlayingAtPosition Float
  | OverviewTagMouseOver EntityId OerId
  | OverviewTagMouseOut
  | OverviewTagLabelMouseOver EntityId OerId
  | OverviewTagLabelClicked OerId
  | PageScrolled PageScrollState
  | OerCardPlaceholderPositionsReceived (List OerCardPlaceholderPosition)
  | StartLabStudyTask LabStudyTask
  | StoppedLabStudyTask
  -- | SelectResourceSidebarTab ResourceSidebarTab OerId
  -- | MouseMovedOnStoryTag Float
  | SelectedOverviewType OverviewType
  | MouseEnterMentionInBubbblogramOverview OerId EntityId MentionInOer
  -- | ClickedHeart OerId
  | FlyingHeartRelativeStartPositionReceived Point
  | TimelineMouseEvent EventNameAndPosition
  | TimelineMouseLeave
  | Html5VideoStarted Float
  | Html5VideoPaused Float
  | Html5VideoSeeked Float
  | Html5VideoStillPlaying Float
  | Html5VideoDuration Float
  | StartCurrentHtml5Video Float
  | ToggleContentFlow
  | AddedOerToCourse OerId Range
  | RemovedOerFromCourse OerId
  | MovedCourseItemDown Int
  | SubmittedCourseItemComment
  | ChangedCommentTextInCourseItem OerId String


type UserProfileField
  = FirstName
  | LastName


subscriptions : Model -> Sub Msg
subscriptions model =
  ([ Browser.Events.onResize ResizeBrowser
  , Ports.modalAnimationStart ModalAnimationStart
  , Ports.modalAnimationStop ModalAnimationStop
  , Ports.closePopup (\_ -> ClosePopup)
  , Ports.closeInspector (\_ -> CloseInspector)
  , Ports.clickedOnDocument (\_ -> ClickedOnDocument)
  , Ports.mouseOverChunkTrigger MouseOverChunkTrigger
  -- , Ports.mouseMovedOnStoryTag MouseMovedOnStoryTag
  , Ports.timelineMouseEvent TimelineMouseEvent
  -- , Ports.youtubeVideoIsPlayingAtPosition YoutubeVideoIsPlayingAtPosition
  , Ports.html5VideoStarted Html5VideoStarted
  , Ports.html5VideoPaused Html5VideoPaused
  , Ports.html5VideoSeeked Html5VideoSeeked
  , Ports.html5VideoStillPlaying Html5VideoStillPlaying
  , Ports.html5VideoDuration Html5VideoDuration
  , Ports.pageScrolled PageScrolled
  , Ports.receiveCardPlaceholderPositions OerCardPlaceholderPositionsReceived
  , Ports.receiveFlyingHeartRelativeStartPosition FlyingHeartRelativeStartPositionReceived
  , Time.every 500 ClockTick
  ] ++ (if anyBubblogramsAnimating model || isModalAnimating model || isFlyingHeartAnimating model then [ Browser.Events.onAnimationFrame AnimationTick ] else []))
  |> Sub.batch


isModalAnimating model =
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
