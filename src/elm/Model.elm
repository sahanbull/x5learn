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
  , session : Maybe Session -- the Session represents a logged-in or guest user. We request this data initially from the server. Until the response arrives, the value defaults to Nothing.
  , subpage : Subpage -- custom type, indicating which subpage to render
  -- OER data
  , cachedOers : Dict OerId Oer -- OER data loaded from the server
  , requestingOers : Bool -- waiting for OER data from the server
  , featuredOers : Maybe (List OerId) -- a handful of OERs to display on the start page
  -- Course data
  , course : Course -- essentially a list of commentable OER snippets that the user has bookmarked
  , courseNeedsSaving : Bool -- true when the user changes any course items since last saving
  , courseChangesSaved : Bool -- used to display a message to the user
  , lastTimeCourseChanged : Posix -- wait a few seconds before saving changes, to avoid too frequent requests (e.g. while typing)
  -- Enrichments data
  , requestingWikichunkEnrichments : Bool -- true while waiting for a response from the server. This is to avoid simultaneous requests.
  , wikichunkEnrichments : Dict OerId WikichunkEnrichment -- enrichment data cached on the frontend
  , enrichmentsAnimating : Bool -- when the enrichments are loaded, some of the bubblogram visualisations come in with a zooming/sliding effect
  , wikichunkEnrichmentRequestFailCount : Int -- exponential(ish) backoff strategy: keep nagging the server for enrichments. count the attempts
  , wikichunkEnrichmentRetryTime : Posix -- exponential(ish) backoff strategy: wait a bit longer every time
  -- Wikipedia definitions data
  , entityDefinitions : Dict String EntityDefinition -- wikipedia definitions loaded from the server
  , requestingEntityDefinitions : Bool -- waiting for wikipedia definitions from the server
  -- OER cards
  , hoveringOerId : Maybe OerId -- When the mouse is hovering over an OER card then we store its ID here
  , timeOfLastMouseEnterOnCard : Posix -- When the mouse starts hovering over an OER card then we keep track of the time in order to cycle through multiple images (if any).
  , oerCardPlaceholderPositions : List OerCardPlaceholderPosition -- dynamic layout of the cards on the screen
  -- OER Bubblograms
  , overviewType : OverviewType -- thumbnail or bubblogram
  , hoveringTagEntityId : Maybe String -- when the user hovers over a topic in a bubblogram
  , timeOfLastUrlChange : Posix -- used to animate bubblograms
  , selectedMentionInStory : Maybe (OerId, MentionInOer) -- in bubblogram: hovering over a mention
  -- OER inspector modal
  , inspectorState : Maybe InspectorState -- custom type, see definition below
  , modalAnimation : Maybe BoxAnimation -- When the user clicks on an OER card then the inspector modal doesn't just appear instantly - there is a bit of a zooming effect.
  -- Autocomplete for suggested search terms
  , autocompleteTerms : List String -- list of wiki topics that may be used as autocompleteSuggestions
  , autocompleteSuggestions : List String -- when the user enters text in the search field, an earlier prototype version of the UI used to suggest wiki topics as search terms (currently disabled)
  , selectedSuggestion : String -- hovering over one of the autocompleteSuggestions selects the item
  , suggestionSelectionOnHoverEnabled : Bool -- dynamic flag to prevent accidental selection when the menu appears under the mouse pointer
  -- User profile
  , userProfileForm : UserProfileForm -- for the user to fill in their name etc
  , userProfileFormSubmitted : Bool -- show a loading spinner while waiting for HTTP response
  -- Lab study
  , startedLabStudyTask : Maybe (LabStudyTask, Posix) -- when the user presses button to start a task (lab study only)
  -- Full-page resource view
  , currentResource : Maybe CurrentResource -- in full-page view: the loaded OER e.g. x5learn.org/resource/12345
  , resourceSidebarTab : ResourceSidebarTab -- in full-page view: switch between recommendations, notes and feedback
  , resourceRecommendations : List Oer -- in full-page view: OER recommendations in the sidebar tab
  -- Explicit user feedback about OER content
  , feedbackForms : Dict OerId String -- allowing the user to type feedback on different OERs
  , timeOfLastFeedbackRecorded : Posix -- used to show a brief thank you message
  -- VideoUsages
  , videoUsages : Dict OerId VideoUsage -- for each (video) OER, which parts has the user watched
  -- favorites
  , favorites : List OerId -- OERs marked as favourite (heart icon)
  , removedFavorites : Set OerId -- keep a client-side record of removed items so that cards on the favorites page don't simply disappear when unliked
  , hoveringHeart : Maybe OerId -- if the user hovers over a heart, which OER is it
  , flyingHeartAnimation : Maybe FlyingHeartAnimation -- when the user likes an OER
  , flyingHeartAnimationStartPoint : Maybe Point -- when the user likes an OER
  -- screen dimensions
  , windowWidth : Int -- width of the browser window in pixels
  , windowHeight : Int -- height of the browser window in pixels
  -- scrolling and scrubbing
  , pageScrollState : PageScrollState -- vertical page scrolling. NB This value can also change when resizing the window or rotating the device.
  , mousePositionXwhenOnChunkTrigger : Float -- crude method to determine whether the ContentFlow menu should open to the left or right (to prevent exceeding the screen borders)
  , timelineHoverState : Maybe TimelineHoverState -- used for scrubbing and defining ranges
  -- additional screen elements
  , snackbar : Maybe Snackbar -- brief message at the bottom of the screen. https://material.io/components/snackbars/
  , popup : Maybe Popup -- There can be different types of popups, see type definition below.
  -- time
  , currentTime : Posix -- updated a few times a second. Mind the limited precision
  , animationsPending : Set String -- Keeping track of multiple GUI animations, including the inspector modal. We're using a Set of Strings, assuming that there can be multiple animations in parallel, each having a unique String ID.
  -- search
  , searchInputTyping : String -- text the user types into the search field
  , searchState : Maybe SearchState -- custom type, see definition below
  , timeOfLastSearch : Posix -- important to briefly disable autocomplete immediately after a search
  -- UI log events
  , loggedEvents : List String -- temporary buffer for frequent UI events that will be sent to the server in delayed batches
  , lastTimeLoggedEventsSaved : Posix -- wait a few seconds between batches
  , timeWhenSessionLoaded : Posix -- wait a few seconds before logging UI events
  -- deactivated code
  -- , oerNoteboards : Dict OerId Noteboard
  -- , oerNoteForms : Dict OerId String
  }


{-| We get the first sentence from the Wikipedia article
-}
type EntityDefinition
  = DefinitionScheduledForLoading
  | DefinitionLoaded String

{-| Sidebar in full-page view
-}
type ResourceSidebarTab
  = RecommendationsTab
  | FeedbackTab

{-| Current resource in full-page view
-}
type CurrentResource
  = Loaded OerId
  | Error

{-| Toggle between thumbnails and bubblograms
-}
type OverviewType
  = ImageOverview
  | BubblogramOverview BubblogramType

{-| Type of bubblogram to display
-}
type BubblogramType
  = TopicNames
  | TopicConnections
  | TopicMentions

{-| For any (video) OER, which parts has the user watched
-}
type alias VideoUsage = List Range

{-| when the user likes an OER
-}
type alias FlyingHeartAnimation =
  { startTime : Posix
  }

{-| when the user presses button to start a task (lab study only)
-}
type alias LabStudyTask =
  { title : String
  , durationInMinutes : Int
  , dataset : String
  }

{-| Item in a bubblogram representing an entity as a circle
-}
type alias Bubble =
  { entity : Entity
  , index : Int
  , hue : Float
  , alpha : Float
  , saturation : Float
  , initialCoordinates : BubbleCoordinates
  , finalCoordinates : BubbleCoordinates
  }

{-| Position and size of a bubble
-}
type alias BubbleCoordinates =
  { posX : Float
  , posY : Float
  , size : Float
  }

{-| Literal occurrence of an entity's name in an OER transcript
-}
type alias Occurrence =
  { entity : Entity
  , approximatePositionInText : Float
  , rank : Float
  }

{-| Bubblogram
-}
type alias Bubblogram =
  { createdAt : Posix
  , bubbles : List Bubble
  }


{-| An OER's URL is just a String. We use an alias to make it explicit, in order to make the code easier to read.
-}
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
  , session = Nothing
  , subpage = Home
  , cachedOers = Dict.empty
  , requestingOers = False
  , featuredOers = Nothing
  , course = Course []
  , courseNeedsSaving = False
  , courseChangesSaved = False
  , lastTimeCourseChanged = initialTime
  , requestingWikichunkEnrichments = False
  , wikichunkEnrichments = Dict.empty
  , enrichmentsAnimating = False
  , wikichunkEnrichmentRequestFailCount = 0
  , wikichunkEnrichmentRetryTime = initialTime
  , entityDefinitions = Dict.empty
  , requestingEntityDefinitions = False
  , hoveringOerId = Nothing
  , timeOfLastMouseEnterOnCard = initialTime
  , oerCardPlaceholderPositions = []
  , overviewType = ImageOverview
  , hoveringTagEntityId = Nothing
  , timeOfLastUrlChange = initialTime
  , selectedMentionInStory = Nothing
  , inspectorState = Nothing
  , modalAnimation = Nothing
  , autocompleteTerms = []
  , autocompleteSuggestions = []
  , selectedSuggestion = ""
  , suggestionSelectionOnHoverEnabled = True
  , userProfileForm = freshUserProfileForm (initialUserProfile "")
  , userProfileFormSubmitted = False
  , startedLabStudyTask = Nothing
  , currentResource = Nothing
  , resourceSidebarTab = initialResourceSidebarTab
  , resourceRecommendations = []
  , feedbackForms = Dict.empty
  , timeOfLastFeedbackRecorded = initialTime
  , videoUsages = Dict.empty
  , favorites = []
  , removedFavorites = Set.empty
  , hoveringHeart = Nothing
  , flyingHeartAnimation = Nothing
  , flyingHeartAnimationStartPoint = Nothing
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , pageScrollState = PageScrollState 0 0 0 False
  , mousePositionXwhenOnChunkTrigger = 0
  , timelineHoverState = Nothing
  , snackbar = Nothing
  , popup = Nothing
  , currentTime = initialTime
  , animationsPending = Set.empty
  , searchInputTyping = ""
  , searchState = Nothing
  , timeOfLastSearch = initialTime
  , loggedEvents = []
  , lastTimeLoggedEventsSaved = initialTime
  , timeWhenSessionLoaded = initialTime
  -- , oerNoteboards = Dict.empty
  -- , oerNoteForms = Dict.empty
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
