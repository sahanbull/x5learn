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

{-| The Msg type specifies all the actions that can occur in the app.
-}
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
  | RequestResourceRecommendations (Result Http.Error (List Oer))
  | RequestSaveAction (Result Http.Error String)
  | RequestLoadCourse (Result Http.Error Course)
  | RequestSaveCourse (Result Http.Error String)
  | RequestSaveLoggedEvents (Result Http.Error String)
  | RequestCourseOptimization (Result Http.Error (List OerId))
  -- | RequestSaveNote (Result Http.Error String)
  | SetHover (Maybe OerId)
  | SetPopup Popup
  | ClosePopup
  | CloseInspector
  | TriggerSearch String Bool
  | ClickedOnDocument
  | SelectSuggestion String
  | MouseOverChunkTrigger Float
  -- | YoutubeSeekTo Float
  | EditUserProfile UserProfileField String
  | SubmittedUserProfile
  -- | ChangedTextInNewNoteFormInOerNoteboard OerId String
  | ChangedTextInResourceFeedbackForm OerId String
  -- | SubmittedNewNoteInOerNoteboard OerId
  | SubmittedResourceFeedback OerId String
  -- | PressedKeyInNewNoteFormInOerNoteboard OerId Int
  -- | ClickedQuickNoteButton OerId String
  -- | RemoveNote Note
  | YoutubeVideoIsPlayingAtPosition Float
  | BubblogramTopicMouseOver EntityId OerId
  | BubblogramTopicMouseOut
  | BubblogramTopicLabelMouseOver EntityId OerId
  | BubblogramTopicLabelClicked OerId
  | PageScrolled PageScrollState
  | OerCardPlaceholderPositionsReceived (List OerCardPlaceholderPosition)
  | SelectInspectorSidebarTab InspectorSidebarTab OerId
  | MouseMovedOnTopicLane Float
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
  | Html5VideoAspectRatio Float
  | StartCurrentHtml5Video Float
  | ToggleContentFlow
  | ToggleExplainer
  | OpenExplanationPopup String
  | AddedOerToCourse OerId Range
  | RemovedOerFromCourse OerId
  | MovedCourseItemDown Int
  | PressedOptimiseLearningPath
  | PressedUndoCourse Course
  | SubmittedCourseItemComment
  | ChangedCommentTextInCourseItem OerId String
  | StartTask String
  | CompleteTask
  | OpenedOverviewTypeMenu
  | PressedReadMore InspectorState
  | ToggleDataCollectionConsent Bool


type UserProfileField
  = FirstName
  | LastName


{-| Subscribe to: incoming data from ports, time, and resizing the browser window.
    The corresponding Msg events are handled in Update.elm
-}
subscriptions : Model -> Sub Msg
subscriptions model =
  ([ Browser.Events.onResize ResizeBrowser
  , Ports.modalAnimationStart ModalAnimationStart
  , Ports.modalAnimationStop ModalAnimationStop
  , Ports.closePopup (\_ -> ClosePopup)
  , Ports.closeInspector (\_ -> CloseInspector)
  , Ports.clickedOnDocument (\_ -> ClickedOnDocument)
  , Ports.mouseOverChunkTrigger MouseOverChunkTrigger
  , Ports.mouseMovedOnTopicLane MouseMovedOnTopicLane
  , Ports.timelineMouseEvent TimelineMouseEvent
  -- , Ports.youtubeVideoIsPlayingAtPosition YoutubeVideoIsPlayingAtPosition
  , Ports.html5VideoStarted Html5VideoStarted
  , Ports.html5VideoPaused Html5VideoPaused
  , Ports.html5VideoSeeked Html5VideoSeeked
  , Ports.html5VideoStillPlaying Html5VideoStillPlaying
  , Ports.pageScrolled PageScrolled
  , Ports.receiveCardPlaceholderPositions OerCardPlaceholderPositionsReceived
  , Ports.receiveFlyingHeartRelativeStartPosition FlyingHeartRelativeStartPositionReceived
  , Time.every (if model.currentTime==initialTime then 1 else if model.timelineHoverState==Nothing then 500 else 200) ClockTick
  ] ++ (if anyBubblogramsAnimating model || isModalAnimating model || isFlyingHeartAnimating model then [ Browser.Events.onAnimationFrame AnimationTick ] else []))
  |> Sub.batch
