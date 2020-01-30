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
  = ModelInitialized Url.Url -- Called only once, right after starting the app
  | LinkClicked Browser.UrlRequest -- User clicked on an internal link
  | UrlChanged Url.Url -- The browser URL changed for some reason, e.g. link or pushUrl
  | ClockTicked Posix -- Called a few times per second
  | AnimationTick Posix -- Called once per animation frame (e.g. 60-ish times per second), only while something is animating
  | SearchFieldChanged String -- User changed the text in the search field, e.g. typing, paste, undo...
  | BrowserResized Int Int -- User changed the width/height of the browser window, or rotated the device
  | InspectOer Oer Float Bool -- User did something that should open the Inspector
  | ClickedOnCourseItem Oer -- User clicked on a course item, causing it to open in the Inspector
  | PressedCloseButtonInInspector -- User pressed the X button
  | InspectorAnimationStart BoxAnimation
  | InspectorAnimationStop Int
  | RequestSession (Result Http.Error Session)
  | RequestVideoUsages (Result Http.Error (Dict String (List Range)))
  | RequestOerSearch (Result Http.Error (List Oer))
  | RequestOers (Result Http.Error (List Oer))
  | RequestFeatured (Result Http.Error (List Oer))
  | RequestWikichunkEnrichments (Result Http.Error (List WikichunkEnrichment))
  | RequestEntityDefinitions (Result Http.Error (Dict String String))
  | RequestSaveUserProfile (Result Http.Error String)
  | RequestLabStudyLogEvent (Result Http.Error String)
  | RequestResourceRecommendations (Result Http.Error (List Oer))
  | RequestSaveAction (Result Http.Error String)
  | RequestLoadCourse (Result Http.Error Course)
  | RequestSaveCourse (Result Http.Error String)
  | RequestSaveLoggedEvents (Result Http.Error String)
  | RequestCourseOptimization (Result Http.Error (List OerId))
  | SetHover (Maybe OerId)
  | SetPopup Popup
  | ClosePopup
  | CloseInspector
  | TriggerSearch String Bool
  | MouseOverChunkTrigger Float
  | EditUserProfile UserProfileField String
  | SubmittedUserProfile
  | ChangedTextInResourceFeedbackForm OerId String
  | SubmittedResourceFeedback OerId String
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
  | ClickedOnContentFlowBar Oer Float Bool


type UserProfileField
  = FirstName
  | LastName


{-| Subscribe to: incoming data from ports, time, and resizing the browser window.
    The corresponding Msg events are handled in Update.elm
-}
subscriptions : Model -> Sub Msg
subscriptions model =
  ([ Browser.Events.onResize BrowserResized
  , Ports.inspectorAnimationStart InspectorAnimationStart
  , Ports.inspectorAnimationStop InspectorAnimationStop
  , Ports.closePopup (\_ -> ClosePopup)
  , Ports.closeInspector (\_ -> CloseInspector)
  , Ports.mouseOverChunkTrigger MouseOverChunkTrigger
  , Ports.mouseMovedOnTopicLane MouseMovedOnTopicLane
  , Ports.timelineMouseEvent TimelineMouseEvent
  , Ports.html5VideoStarted Html5VideoStarted
  , Ports.html5VideoPaused Html5VideoPaused
  , Ports.html5VideoSeeked Html5VideoSeeked
  , Ports.html5VideoStillPlaying Html5VideoStillPlaying
  , Ports.pageScrolled PageScrolled
  , Ports.receiveCardPlaceholderPositions OerCardPlaceholderPositionsReceived
  , Time.every (if model.currentTime==initialTime then 1 else if model.timelineHoverState==Nothing then 500 else 200) ClockTicked
  ] ++ (if anyBubblogramsAnimating model || isInspectorAnimating model then [ Browser.Events.onAnimationFrame AnimationTick ] else []))
  |> Sub.batch
