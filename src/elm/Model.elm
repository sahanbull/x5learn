module Model exposing (..)

{-| This module holds the Model type
    as well as auxiliary types and helper functions
-}


import Browser
import Browser.Navigation as Navigation
import Url
import Time exposing (Posix, posixToMillis, millisToPosix)
import Dict exposing (Dict)
import Set exposing (Set)
import Regex
import List.Extra

import Animation exposing (..)


{-| The Model contains the ENTIRE state of the frontend at any point in time.

    Naturally, it is a huge type with lots of fields and some nesting.
    There is an obvious trade-off between the number of fields and the depth of nesting.
    Sometimes deeper nesting can be preferable, in cases when things need to change as one,
    e.g. searchState contains fields that share a common lifetime and context.
    On the other hand, sometimes you want to avoid nesting to keep update simple.
    e.g. course could be nested into the session, but then updating it would be
    significantly more complex, while the benefits would arguably be small.

    It's a long and interesting discussion.
    https://discourse.elm-lang.org/t/updating-nested-records-again/1488/9

    Also note that in some cases, it simply comes down to convenience,
    E.g. Should windowWidth and windowHeight be combined into a single field
    that holds two integers? Sure, why not. This one is almost a matter of taste.
    In my experience, having lots of fields in the Model doesn't come at a real cost.
-}
type alias Model =
  { nav : Nav -- Elm structure for managing the browser's navigation bar. https://package.elm-lang.org/packages/elm/browser/1.0.1/Browser-Navigation
  , subpage : Subpage -- custom type, indicating which subpage to render
  , session : Maybe Session -- custom type, loaded from server initially
  , windowWidth : Int -- width of the browser window in pixels
  , windowHeight : Int -- height of the browser window in pixels
  , mousePositionXwhenOnChunkTrigger : Float -- crude method to determine whether the ContentFlow menu should open to the left or right (to prevent exceeding the screen borders)
  , currentTime : Posix -- updated a few times a second. Mind the limited precision
  , searchInputTyping : String -- text the user types into the search field
  , searchState : Maybe SearchState -- custom type, see definition below
  , inspectorState : Maybe InspectorState -- custom type, see definition below
  , snackbar : Maybe Snackbar -- brief message at the bottom of the screen. https://material.io/components/snackbars/
  , course : Course -- essentially a list of commentable OER snippets that the user has bookmarked
  , hoveringOerId : Maybe OerId -- When the mouse is hovering over an OER card then we store its ID here
  , timeOfLastMouseEnterOnCard : Posix -- When the mouse starts hovering over an OER card then we keep track of the time in order to cycle through multiple images (if any).
  , modalAnimation : Maybe BoxAnimation -- When the user clicks on an OER card then the inspector modal doesn't just appear instantly - there is a bit of a zooming effect.
  , animationsPending : Set String -- Keeping track of multiple GUI animations, including the inspector modal. We're using a Set of Strings, assuming that there can be multiple animations in parallel, each having a unique String ID.
  , popup : Maybe Popup -- There can be different types of popups, see type definition below.
  , requestingWikichunkEnrichments : Bool -- true while waiting for a response from the server. This is to avoid simultaneous requests.
  , wikichunkEnrichments : Dict OerId WikichunkEnrichment -- enrichment data cached on the frontend
  , enrichmentsAnimating : Bool -- when the enrichments are loaded, some of the bubblogram visualisations come in with a zooming/sliding effect
  , tagClouds : Dict String (List String)
  , autocompleteTerms : List String
  , autocompleteSuggestions : List String
  , selectedSuggestion : String
  , suggestionSelectionOnHoverEnabled : Bool
  , timeOfLastSearch : Posix
  , userProfileForm : UserProfileForm
  , userProfileFormSubmitted : Maybe UserProfileForm
  -- , oerNoteForms : Dict OerId String
  , feedbackForms : Dict OerId String
  , cachedOers : Dict OerId Oer
  , requestingOers : Bool
  , hoveringTagEntityId : Maybe String
  , entityDefinitions : Dict String EntityDefinition
  , requestingEntityDefinitions : Bool
  , wikichunkEnrichmentRequestFailCount : Int
  , wikichunkEnrichmentRetryTime : Posix
  , timeOfLastUrlChange : Posix
  , startedLabStudyTask : Maybe (LabStudyTask, Posix)
  , currentResource : Maybe CurrentResource
  , resourceSidebarTab : ResourceSidebarTab
  , resourceRecommendations : List Oer
  , timeOfLastFeedbackRecorded : Posix
  -- , oerNoteboards : Dict OerId Noteboard
  , videoUsages : Dict OerId VideoUsage
  , oerCardPlaceholderPositions : List OerCardPlaceholderPosition
  , overviewType : OverviewType
  , selectedMentionInStory : Maybe (OerId, MentionInOer)
  , pageScrollState : PageScrollState
  , favorites : List OerId
  , removedFavorites : Set OerId -- keep a client-side record of "unliked" oers so that cards on the favorites page don't simply disappear when unliked
  , hoveringHeart : Maybe OerId
  , flyingHeartAnimation : Maybe FlyingHeartAnimation
  , flyingHeartAnimationStartPoint : Maybe Point
  , featuredOers : Maybe (List OerId)
  , timelineHoverState : Maybe TimelineHoverState
  , courseNeedsSaving : Bool
  , courseChangesSaved : Bool
  , lastTimeCourseChanged : Posix
  , loggedEvents : List String
  , lastTimeLoggedEventsSaved : Posix
  , timeWhenSessionLoaded : Posix
  }


type EntityDefinition
  = DefinitionScheduledForLoading
  | DefinitionLoaded String
  -- | DefinitionUnavailable -- TODO consider appropriate error handling

type ResourceSidebarTab
  = RecommendationsTab
  | FeedbackTab

type CurrentResource
  = Loaded OerId
  | Error

type OverviewType
  = ImageOverview
  | BubblogramOverview BubblogramType

type BubblogramType
  = TopicNames
  | TopicConnections
  | TopicMentions

type alias VideoUsage = List Range

type alias FlyingHeartAnimation =
  { startTime : Posix
  }

type alias LabStudyTask =
  { title : String
  , durationInMinutes : Int
  , dataset : String
  }

type alias Bubble =
  { entity : Entity
  , index : Int
  , hue : Float
  , alpha : Float
  , saturation : Float
  , initialCoordinates : BubbleCoordinates
  , finalCoordinates : BubbleCoordinates
  }

type alias BubbleCoordinates =
  { posX : Float
  , posY : Float
  , size : Float
  }

type alias Occurrence =
  { entity : Entity
  , approximatePositionInText : Float
  , rank : Float
  }


type alias Bubblogram =
  { createdAt : Posix
  , bubbles : List Bubble
  }

type alias OerUrl = String

type alias OerId = Int

type alias EntityId = String

type alias EntityTitle = String

type alias Noteboard = List Note

type alias PageScrollState =
  { scrollTop : Float
  , viewHeight : Float
  , contentHeight : Float
  , requestedByElm : Bool -- for analytics
  }


type alias Snackbar =
  { startTime : Posix
  , text : String
  }

type alias OerCardPlaceholderPosition =
  { x : Float
  , y : Float
  , oerId : Int
  }


type alias Note =
  { text : String
  , time : Posix
  , oerId : OerId
  , id : Int
  }


type alias UserProfileForm =
  { userProfile : UserProfile
  , saved : Bool
  }


type alias UserProfile =
  { email : String
  , firstName : String
  , lastName : String
  }


type alias Flags =
  { windowWidth : Int
  , windowHeight : Int
  }


type alias Nav =
  { url : Url.Url
  , key : Navigation.Key
  }


type Subpage
  = Home
  | Profile
  | Search
  -- | Favorites
  -- | Notes
  -- | Viewed
  | Resource


type alias SearchState =
  { lastSearch : String
  , searchResults : Maybe (List OerId)
  }


type alias InspectorState =
  { oer : Oer
  , fragmentStart : Float
  , activeMenu : Maybe InspectorMenu
  , videoPlayer : Maybe Html5VideoPlayer
  }


type alias Html5VideoPlayer =
  { isPlaying : Bool
  , currentTime : Float
  , duration : Float
  }



type alias Oer =
  { id : Int
  , date : String
  , description : String
  , duration : String
  , durationInSeconds : Float
  , images : List String
  , provider : String
  , title : String
  , url : String
  , mediatype : String
  }


type alias WikichunkEnrichment =
  { bubblogram : Maybe Bubblogram
  , mentions : Dict EntityId (List MentionInOer)
  , chunks : List Chunk
  , clusters : List Cluster
  , errors : Bool
  , oerId : OerId
  }


type alias Cluster = List EntityTitle

type alias Chunk =
  { start : Float -- 0 to 1
  , length : Float -- 0 to 1
  , entities : List Entity
  , text : String -- raw text extracted from the resource
  }


type alias Entity =
  { id : String
  , title : String
  , url : String
  }


type Popup
  = ChunkOnBar ChunkPopup
  | UserMenu
  | BubblePopup BubblePopupState


type alias ChunkPopup = { barId : String, oer : Oer, chunk : Chunk, entityPopup : Maybe EntityPopup }

type alias EntityPopup = { entityId : String, hoveringAction : Maybe String }

type alias BubblePopupState = { oerId : OerId, entityId : String, content : BubblePopupContent, nextContents : List BubblePopupContent }


type BubblePopupContent
  = DefinitionInBubblePopup
  | MentionInBubblePopup MentionInOer

type alias MentionInOer =
  { positionInResource : Float
  , sentence : String
  }

type alias Range =
  { start : Float -- 0 to 1
  , length : Float -- 0 to 1
  }

type alias TimelineHoverState =
  { position : Float
  , mouseDownPosition : Maybe Float
  }

type alias EventNameAndPosition =
  { eventName : String
  , position : Float
  }

type alias Course =
  { items : List CourseItem
  }

type alias CourseItem =
  { oerId : OerId
  , range : Range
  , comment : String
  }

type alias Playlist =
  { title : String
  , oerIds : List OerId
  }


type AnimationStatus
  = Inactive
  | Prestart
  | Started


type InspectorMenu
  = QualitySurvey -- TODO


type alias Session =
  { loginState : LoginState
  , isContentFlowEnabled : Bool
  }


type LoginState
  = GuestUser
  | LoggedInUser UserProfile


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
  , subpage = Home
  , session = Nothing
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , mousePositionXwhenOnChunkTrigger = 0
  , currentTime = initialTime
  , searchInputTyping = ""
  , searchState = Nothing
  , inspectorState = Nothing
  , snackbar = Nothing
  , course = Course []
  , hoveringOerId = Nothing
  , timeOfLastMouseEnterOnCard = initialTime
  , modalAnimation = Nothing
  , animationsPending = Set.empty
  , popup = Nothing
  , requestingWikichunkEnrichments = False
  , wikichunkEnrichments = Dict.empty
  , enrichmentsAnimating = False
  , tagClouds = Dict.empty
  , autocompleteTerms = []
  , autocompleteSuggestions = []
  , selectedSuggestion = ""
  , suggestionSelectionOnHoverEnabled = True -- prevent accidental selection when user doesn't move the pointer but the menu appears on the pointer
  , timeOfLastSearch = initialTime
  , userProfileForm = freshUserProfileForm (initialUserProfile "")
  , userProfileFormSubmitted = Nothing
  -- , oerNoteForms = Dict.empty
  , feedbackForms = Dict.empty
  , cachedOers = Dict.empty
  , requestingOers = False
  , hoveringTagEntityId = Nothing
  , entityDefinitions = Dict.empty
  , requestingEntityDefinitions = False
  , wikichunkEnrichmentRequestFailCount = 0
  , wikichunkEnrichmentRetryTime = initialTime
  , timeOfLastUrlChange = initialTime
  , startedLabStudyTask = Nothing
  , currentResource = Nothing
  , resourceSidebarTab = initialResourceSidebarTab
  , resourceRecommendations = []
  , timeOfLastFeedbackRecorded = initialTime
  -- , oerNoteboards = Dict.empty
  , videoUsages = Dict.empty
  , oerCardPlaceholderPositions = []
  , overviewType = ImageOverview
  , selectedMentionInStory = Nothing
  , pageScrollState = PageScrollState 0 0 0 False
  , favorites = []
  , removedFavorites = Set.empty
  , hoveringHeart = Nothing
  , flyingHeartAnimation = Nothing
  , flyingHeartAnimationStartPoint = Nothing
  , featuredOers = Nothing
  , timelineHoverState = Nothing
  , courseNeedsSaving = False
  , courseChangesSaved = False
  , lastTimeCourseChanged = initialTime
  , loggedEvents = []
  , lastTimeLoggedEventsSaved = initialTime
  , timeWhenSessionLoaded = initialTime
  }


initialUserProfile : String -> UserProfile
initialUserProfile email =
  UserProfile email "" ""


-- getOerNoteboard : Model -> OerId -> Noteboard
-- getOerNoteboard model oerId =
--   model.oerNoteboards
--   |> Dict.get oerId
--   |> Maybe.withDefault []


-- getOerNoteForm : Model -> OerId -> String
-- getOerNoteForm model oerId =
--   model.oerNoteForms
--   |> Dict.get oerId
--   |> Maybe.withDefault ""


-- getOerIdFromOerId : Model -> OerId -> OerId
-- getOerIdFromOerId model oerId =
--   case model.cachedOers |> Dict.get oerId of
--     Just oer ->
--       oer.id

    -- Nothing ->
    --   0


initialTime : Posix
initialTime =
  Time.millisToPosix 0


newSearch : String -> SearchState
newSearch str =
  { lastSearch = str
  , searchResults = Nothing
  }


newInspectorState : Oer -> Float -> InspectorState
newInspectorState oer fragmentStart =
  let
      videoPlayer =
        if oer.mediatype=="video" && (hasYoutubeVideo oer.url |> not) then
          Just <|
            { isPlaying = False
            , currentTime = 0
            , duration = 0
            }
        else
          Nothing
  in
      InspectorState oer fragmentStart Nothing videoPlayer


hasYoutubeVideo : OerUrl -> Bool
hasYoutubeVideo oerUrl =
  case getYoutubeVideoId oerUrl of
    Nothing ->
      False

    Just _ ->
      True


getYoutubeVideoId : OerUrl -> Maybe String
getYoutubeVideoId oerUrl =
  if (oerUrl |> String.contains "://youtu") || (oerUrl |> String.contains "://www.youtu") then
    oerUrl
    |> String.split "="
    |> List.drop 1
    |> List.head
    |> Maybe.withDefault ""
    |> String.split "&"
    |> List.head
  else
    Nothing


modalId : String
modalId =
  "inspectorModal"


millisSince : Model -> Posix -> Int
millisSince model pastPointInTime =
  (posixToMillis model.currentTime) - (posixToMillis pastPointInTime)


modalAnimationStatus : Model -> AnimationStatus
modalAnimationStatus model =
  if model.animationsPending |> Set.member modalId then
    case model.modalAnimation of
      Nothing ->
        Prestart

      Just _ ->
        Started
  else
    Inactive


currentUrlMatches : Model -> String -> Bool
currentUrlMatches model url =
  url == model.nav.url.path


isFromVideoLecturesNet : Oer -> Bool
isFromVideoLecturesNet oer =
  String.startsWith "http://videolectures.net/" oer.url


isInPlaylist : OerId -> Playlist -> Bool
isInPlaylist oerId playlist =
  List.member oerId playlist.oerIds


secondsFromTimeString : String -> Int
secondsFromTimeString time =
  let
      parts =
        time
        |> String.split ":"

      minutes =
        parts
        |> List.head
        |> Maybe.withDefault ""
        |> String.toInt
        |> Maybe.withDefault 0

      seconds =
        parts
        |> List.drop 1
        |> List.head
        |> Maybe.withDefault ""
        |> String.toInt
        |> Maybe.withDefault 0
  in
      minutes * 60 + seconds


secondsToString : Int -> String
secondsToString seconds =
  let
      secondsString =
        seconds |> modBy 60
        |> String.fromInt
        |> String.padLeft 2 '0'

      minutesString =
        seconds // 60
        |> String.fromInt
  in
      minutesString ++ ":" ++ secondsString


displayName : UserProfile -> String
displayName userProfile =
  let
      name =
        userProfile.firstName ++ " " ++ userProfile.lastName
        |> String.trim
  in
      if (String.length name) < 2 then
        userProfile.email
      else
        name


isLoggedIn : Model -> Bool
isLoggedIn model =
  loggedInUserProfile model /= Nothing


loggedInUserProfile : Model -> Maybe UserProfile
loggedInUserProfile {session} =
  case session of
    Nothing ->
      Nothing

    Just {loginState} ->
      case loginState of
        GuestUser ->
          Nothing

        LoggedInUser userProfile ->
          Just userProfile


freshUserProfileForm : UserProfile -> UserProfileForm
freshUserProfileForm userProfile =
  { userProfile = userProfile, saved = False }


chunksFromOerId : Model -> OerId -> List Chunk
chunksFromOerId model oerId =
  case model.wikichunkEnrichments |> Dict.get oerId of
    Nothing ->
      []

    Just enrichment ->
      enrichment.chunks


enrichmentAnimationDuration : Float
enrichmentAnimationDuration =
  3000


anyBubblogramsAnimating : Model -> Bool
anyBubblogramsAnimating model =
  let
      isAnimating enrichment =
        case enrichment.bubblogram of
          Nothing ->
            False

          Just {createdAt} ->
            bubblogramAnimationPhase model createdAt < 1
  in
      model.wikichunkEnrichments
      |> Dict.values
      |> List.any isAnimating


bubblogramAnimationPhase : Model -> Posix -> Float
bubblogramAnimationPhase model createdAt =
  let
      millisSinceStart =
        millisSince model createdAt
        |> Basics.min (millisSinceLastUrlChange model)
        |> toFloat
  in
      millisSinceStart / enrichmentAnimationDuration * 2 |> Basics.min 1


millisSinceLastUrlChange : Model -> Int
millisSinceLastUrlChange model =
  (model.currentTime |> posixToMillis) - (model.timeOfLastUrlChange |> posixToMillis)


isEqualToSearchString : Model -> EntityTitle -> Bool
isEqualToSearchString model entityTitle =
  case model.searchState of
    Nothing ->
      False

    Just searchState ->
      (entityTitle |> String.toLower) == (searchState.lastSearch |> String.toLower)


getMentions : Model -> OerId -> String -> List MentionInOer
getMentions model oerId entityId =
  case model.wikichunkEnrichments |> Dict.get oerId of
    Nothing ->
      []

    Just enrichment ->
      enrichment.mentions
      |> Dict.get entityId
      |> Maybe.withDefault []


mentionInBubblePopup : Model -> Maybe MentionInOer
mentionInBubblePopup model =
  case model.popup of
    Just (BubblePopup state) ->
      case state.content of
        MentionInBubblePopup mention ->
          Just mention

        _ ->
          Nothing

    _ ->
      Nothing


uniqueEntitiesFromEnrichments : List WikichunkEnrichment -> List Entity
uniqueEntitiesFromEnrichments enrichments =
  enrichments
  |> List.concatMap .chunks
  |> List.concatMap .entities
  |> List.Extra.uniqueBy .id


getEntityTitleFromEntityId : Model -> EntityId -> Maybe String
getEntityTitleFromEntityId model entityId =
  let
      maybeEntity =
        model.wikichunkEnrichments
        |> Dict.values
        |> uniqueEntitiesFromEnrichments
        |> List.filter (\{id} -> id==entityId)
        |> List.head
  in
      case maybeEntity of
        Nothing ->
          Nothing

        Just entity ->
          Just entity.title


homePath =
  "/"

profilePath =
  "/profile"

searchPath =
  "/search"

notesPath =
  "/notes"

recentPath = -- deprecated
  "/recent"

viewedPath =
  "/viewed"

favoritesPath =
  "/favorites"

-- coursePath =
--   "/course"

resourcePath =
  "/resource"

loginPath =
   "/login"

signupPath =
  "/signup"

logoutPath =
  "/logout"


averageOf : (a -> Float) -> List a -> Float
averageOf getterFunction records =
  (records |> List.map getterFunction |> List.sum) / (records |> List.length |> toFloat)


interp : Float -> Float -> Float -> Float
interp phase a b =
  phase * b + (1-phase) * a


isLabStudy1 : Model -> Bool
isLabStudy1 model =
  case loggedInUserProfile model of
    Nothing ->
      False

    Just {email} ->
      email |> String.contains "@" |> not


listContainsBoth : a -> a -> List a -> Bool
listContainsBoth a b list =
  List.member a list && List.member b list


bubbleZoom : Float
bubbleZoom =
  0.042


isVideoFile : OerUrl -> Bool
isVideoFile oerUrl =
  let
      lower =
        oerUrl |> String.toLower
  in
     String.endsWith ".mp4" lower || String.endsWith ".webm" lower || String.endsWith ".ogg" lower


isPdfFile : OerUrl -> Bool
isPdfFile oerUrl =
  String.endsWith ".pdf" (oerUrl |> String.toLower)


resourceUrlPath : OerId -> String
resourceUrlPath oerId =
  resourcePath ++ "/" ++ (String.fromInt oerId)


isSiteUnderMaintenance : Bool
isSiteUnderMaintenance =
  False


isOerLoaded : Model -> OerId -> Bool
isOerLoaded model oerId =
  case model.cachedOers |> Dict.get oerId of
    Nothing ->
      False

    Just _ ->
      True


relatedSearchStringFromOer : Model -> OerId -> String
relatedSearchStringFromOer model oerId =
  let
      fallbackString =
        case model.cachedOers |> Dict.get oerId of
          Nothing ->
            "learning" -- shouldn't happen

          Just {title} ->
            title
  in
      case model.wikichunkEnrichments |> Dict.get oerId of
        Nothing ->
          fallbackString

        Just {bubblogram, chunks} ->
          case bubblogram of
            Nothing ->
              fallbackString

            Just {bubbles} ->
              bubbles
              |> List.map .entity
              |> List.map .title
              |> String.join ","


getResourceFeedbackFormValue model oerId =
  model.feedbackForms |> Dict.get oerId |> Maybe.withDefault ""


snackbarDuration : Int
snackbarDuration =
  3000


indexOf : a -> List a -> Maybe Int
indexOf element list =
  let
      helper index xs =
        case xs of
          x::rest ->
            if x==element then
              Just index
            else
              helper (index+1) rest

          _ ->
            Nothing
  in
      helper 0 list


isMarkedAsFavorite : Model -> OerId -> Bool
isMarkedAsFavorite model oerId =
  List.member oerId model.favorites && (Set.member oerId model.removedFavorites |> not)


isFlyingHeartAnimating : Model -> Bool
isFlyingHeartAnimating model =
  model.flyingHeartAnimation /= Nothing


flyingHeartAnimationDuration : Int
flyingHeartAnimationDuration =
  900


initialResourceSidebarTab : ResourceSidebarTab
initialResourceSidebarTab =
  FeedbackTab


isHovering : Model -> Oer -> Bool
isHovering model oer =
  model.hoveringOerId == Just oer.id


isInspecting : Model -> Oer -> Bool
isInspecting model {id} =
  case model.inspectorState of
    Just {oer} ->
      oer.id==id
    _ ->
      False


isContentFlowEnabled : Model -> Bool
isContentFlowEnabled model =
  case model.session of
    Nothing ->
      False
    Just session ->
      session.isContentFlowEnabled


getCourseItem : Model -> Oer -> Maybe CourseItem
getCourseItem model oer =
  model.course.items
  |> List.filter (\{oerId} -> oerId == oer.id)
  |> List.head


swapListItemWithNext : Int -> List a -> List a
swapListItemWithNext index xs =
  let
      left =
        xs |> List.take index

      swapped =
        xs |> List.drop index |> List.take 2 |> List.reverse

      right =
        xs |> List.drop (index+2)
  in
      left ++ swapped ++ right


invertRangeIfNeeded : Range -> Range
invertRangeIfNeeded range =
  if range.length < 0 then
    { start = range.start + range.length
    , length = -range.length
    }
  else
    range


multiplyRange : Float -> Range -> Range
multiplyRange factor {start, length} =
  { start = start * factor
  , length = length * factor
  }
