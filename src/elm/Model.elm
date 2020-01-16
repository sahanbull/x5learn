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
  , entityDefinitions : Dict EntityTitle EntityDefinition -- wikipedia definitions loaded from the server
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
  , currentTaskName : Maybe String
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
  , minWindowWidth : Int -- minimum recommended browser width for the interface to work properly
  , minWindowHeight : Int -- minimum recommended browser height for the interface to work properly
  -- scrolling and scrubbing
  , pageScrollState : PageScrollState -- vertical page scrolling. NB This value can also change when resizing the window or rotating the device.
  , mousePositionXwhenOnChunkTrigger : Float -- crude method to determine whether the ContentFlow menu should open to the left or right (to prevent exceeding the screen borders)
  , timelineHoverState : Maybe TimelineHoverState -- used for scrubbing and defining ranges
  -- additional screen elements
  , snackbar : Maybe Snackbar -- brief message at the bottom of the screen. https://material.io/components/snackbars/
  , popup : Maybe Popup -- There can be only one popup at a time. See the type definition below.
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

{-| Sidebar in inspector
-}
type InspectorSidebarTab
  = RecommendationsTab
  | FeedbackTab

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

{-| when the user likes an OER (favorites)
-}
type alias FlyingHeartAnimation =
  { startTime : Posix
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

{-| Occurrence of an entity in an enrichment.
    Not to be confused with MentionInOer
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


{-| Knowing what part of the page the user is seeing
-}
type alias PageScrollState =
  { scrollTop : Float
  , viewHeight : Float
  , contentHeight : Float
  , requestedByElm : Bool -- for analytics
  }


{-| Brief message at the bottom of the screen
    https://material.io/components/snackbars/
-}
type alias Snackbar =
  { startTime : Posix
  , text : String
  }


{-| Screen layout
-}
type alias OerCardPlaceholderPosition =
  { x : Float
  , y : Float
  , oerId : Int
  }


{-| User comments on OER
-}
type alias Note =
  { text : String
  , time : Posix
  , oerId : OerId
  , id : Int
  }


{-| Allowing the user to enter their profile information
-}
type alias UserProfileForm =
  { userProfile : UserProfile
  , saved : Bool
  }


{-| User profile information
-}
type alias UserProfile =
  { email : String
  , firstName : String
  , lastName : String
  }


{-| Data passed to the Elm app from JS as initial parameters
-}
type alias Flags =
  { windowWidth : Int
  , windowHeight : Int
  , minWindowWidth : Int
  , minWindowHeight : Int
  }


{-| Browser data
-}
type alias Nav =
  { url : Url.Url
  , key : Navigation.Key
  }


{-| Page (rlative URL) within the application
-}
type Subpage
  = Home
  | Profile
  | Search
  -- | Favorites
  -- | Notes


{-| Search for OERs
-}
type alias SearchState =
  { lastSearch : String
  , searchResults : Maybe (List OerId)
  }


{-| Content of the OER inspector modal
-}
type alias InspectorState =
  { oer : Oer
  , fragmentStart : Float
  , videoPlayer : Maybe Html5VideoPlayer
  , inspectorSidebarTab : InspectorSidebarTab -- switch between sidebar contents, such as feedback and recommendations
  , resourceRecommendations : List Oer -- OER recommendations in the sidebar tab
  }


{-|  HTML5 video player
-}
type alias Html5VideoPlayer =
  { isPlaying : Bool
  , currentTime : Float
  , duration : Float
  , aspectRatio : Float
  }


{-| OER basic metadata
-}
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
  , translations : Dict String String
  }


{-| Enrichment based on Wikification
-}
type alias WikichunkEnrichment =
  { bubblogram : Maybe Bubblogram
  , mentions : Dict EntityId (List MentionInOer)
  , chunks : List Chunk
  , clusters : List Cluster
  , errors : Bool
  , oerId : OerId
  }


{-| In some kinds of Bubblogram, the bubbles are grouped into Clusters
-}
type alias Cluster = List EntityTitle


{-| A Chunk is an enriched portion of an OER
-}
type alias Chunk =
  { start : Float -- 0 to 1
  , length : Float -- 0 to 1
  , entities : List Entity
  , text : String -- raw text extracted from the resource
  }


{-| An Entity is a wikipedia topic.
    The reason we call it Entity is partly historical
    as earlier versions relied more strongly on Wikidata entities.
    https://www.wikidata.org/wiki/Q32753077
-}
type alias Entity =
  { id : String
  , title : String
  , url : String
  }


{-| Popups can come in different shapes for different purposes.
    (They are mutually exclusive, i.e. only one popup can be open at any time)
-}
type Popup
  = ContentFlowPopup ChunkPopup -- chunk on ContentFlowBar
  | UserMenu -- when the user clicks on the avatar icon at the top right
  | BubblePopup BubblePopupState -- Certain types of bubblograms open a popup when the mouse hovers over a bubble
  | OverviewTypePopup -- Allowing the user to toggle between thumbnails and bubblograms


{-| Cascading menu containing wikipedia topics
-}
type alias ChunkPopup =
  { barId : String
  , oer : Oer
  , chunk : Chunk
  , entityPopup : Maybe EntityPopup
  }


{-| Nested menu when hovering over an entity
-}
type alias EntityPopup =
  { entityId : String
  , hoveringAction : Maybe String
  }


{-| Popups in bubblograms can have different content
-}
type alias BubblePopupState =
  { oerId : OerId
  , entityId : String
  , content : BubblePopupContent
  , nextContents : List BubblePopupContent
  }


{-| Popups in bubblograms can have different content
-}
type BubblePopupContent
  = DefinitionInBubblePopup
  | MentionInBubblePopup MentionInOer


{-| Literal mention of an entity's name in an OER transcript
-}
type alias MentionInOer =
  { positionInResource : Float
  , sentence : String
  }

{-| Ranges from 0 to 1 are usually used to specify sections of content within an OER.
-}
type alias Range =
  { start : Float -- 0 to 1
  , length : Float -- 0 to 1
  }

{-| TimelineHoverState relates to the ContentFlowBar and serves 2 purposes:
    1. scrubbing to preview video content
    2. specifying a range for a CourseItem by dragging
-}
type alias TimelineHoverState =
  { position : Float
  , mouseDownPosition : Maybe Float
  }

{-| used in connection with timelineMouseEvent
-}
type alias EventNameAndPosition =
  { eventName : String
  , position : Float
  }

{-| A Course is a list of commentable OER snippets selected by the user.
    Aka the user's workspace
-}
type alias Course =
  { items : List CourseItem
  }

{-| CourseItem is a snippet of an OER (specified by a Range) that the has added to a Course.
    The user can add a comment to a CourseItem.
-}
type alias CourseItem =
  { oerId : OerId
  , range : Range
  , comment : String
  }


{-| Playlist is a historical name for: a list of OERs with a title.
    The name Playlist doesn't fit as well as it used to in earlier versions.
    Not to be confused with Course.
    TODO reactor to rename this type
-}
type alias Playlist =
  { title : String
  , oerIds : List OerId
  }


{-| Used to control the zoom animation when opening the inspector modal
-}
type AnimationStatus
  = Inactive
  | Prestart
  | Started


{-| Represents a user (who may or may not be logged in) and some extra settings
-}
type alias Session =
  { loginState : LoginState
  , isContentFlowEnabled : Bool
  , overviewTypeId : String
  }


{-| Represents a user (who may or may not be logged in)
-}
type LoginState
  = GuestUser
  | LoggedInUser UserProfile


{-| VideoEmbedParams is a helper type for embedding YouTube or HTML5 videos.
-}
type alias VideoEmbedParams =
  { modalId : String
  , videoId : String
  , videoStartPosition : Float
  , playWhenReady : Bool
  }


{-| Initial model state
-}
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
  , minWindowWidth = flags.minWindowWidth
  , minWindowHeight = flags.minWindowHeight
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
  , currentTaskName = Nothing
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
            , aspectRatio = 1.3
            }
        else
          Nothing
  in
      InspectorState oer fragmentStart videoPlayer FeedbackTab []


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
  "InspectorModal"


{-| Number of milliseconds that have passed since a certain point in time
-}
millisSince : Model -> Posix -> Int
millisSince model pastPointInTime =
  (posixToMillis model.currentTime) - (posixToMillis pastPointInTime)


{-| Status of the animation of the inspector modal
-}
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


{-| Convenience function to check whether the current URL equals a certain string
-}
currentUrlMatches : Model -> String -> Bool
currentUrlMatches model url =
  url == model.nav.url.path


isFromVideoLecturesNet : Oer -> Bool
isFromVideoLecturesNet oer =
  String.startsWith "http://videolectures.net/" oer.url


{-| Playlist: not to be confused with Course
-}
isInPlaylist : OerId -> Playlist -> Bool
isInPlaylist oerId playlist =
  List.member oerId playlist.oerIds


{-| Takes a String like "13:45" and returns the number of seconds (e.g. 45)
-}
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


{-| Convert a time duration to a String, e.g. 185 seconds -> "3:05"
-}
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


{-| How the user's name appears in the GUI
-}
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


{-| Check whether the inspector modal is currently animating.
    The inspector modal was designed to open with a short zoom animation.
-}
isModalAnimating : Model -> Bool
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


{-| Check whether the user is logged in
-}
isLoggedIn : Model -> Bool
isLoggedIn model =
  loggedInUserProfile model /= Nothing


{-| Get the profile of the logged-in user (if applicable, otherwise return Nothing)
-}
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


{-| Default profile info for the user to change
-}
freshUserProfileForm : UserProfile -> UserProfileForm
freshUserProfileForm userProfile =
  { userProfile = userProfile, saved = False }


{-| Get all available chunks for a particular OER
-}
chunksFromOerId : Model -> OerId -> List Chunk
chunksFromOerId model oerId =
  case model.wikichunkEnrichments |> Dict.get oerId of
    Nothing ->
      []

    Just enrichment ->
      enrichment.chunks


{-| In certain types of bubblogram, the bubbles animate into position.
    This is the duration of the animation in milliseconds.
-}
enrichmentAnimationDuration : Float
enrichmentAnimationDuration =
  3000


{-| Check whether a bubblogram animation is currently running
-}
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


{-| In certain types of bubblogram, the bubbles animate into position.
    This function returns the phase of the animation between 0 (start) and 1 (end).
-}
bubblogramAnimationPhase : Model -> Posix -> Float
bubblogramAnimationPhase model createdAt =
  let
      millisSinceStart =
        millisSince model createdAt
        |> Basics.min (millisSinceLastUrlChange model)
        |> toFloat
  in
      millisSinceStart / enrichmentAnimationDuration * 2 |> Basics.min 1


{-| The time of switching pages within the app is used to control the Bubblogram animation.
    Check whether this still makes sense.
-}
millisSinceLastUrlChange : Model -> Int
millisSinceLastUrlChange model =
  (model.currentTime |> posixToMillis) - (model.timeOfLastUrlChange |> posixToMillis)


{-| Convenience function to check whether a string equals the current search query
-}
isEqualToSearchString : Model -> EntityTitle -> Bool
isEqualToSearchString model entityTitle =
  case model.searchState of
    Nothing ->
      False

    Just searchState ->
      (entityTitle |> String.toLower) == (searchState.lastSearch |> String.toLower)


{-| Returns all the mentions of a particular Entity in a particular OER
-}
getMentions : Model -> OerId -> String -> List MentionInOer
getMentions model oerId entityId =
  case model.wikichunkEnrichments |> Dict.get oerId of
    Nothing ->
      []

    Just enrichment ->
      enrichment.mentions
      |> Dict.get entityId
      |> Maybe.withDefault []


{-| Returns the currently selected Mention (if any) in the Bubblogram popup (if any)
-}
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


{-| Used in order to look up wikipedia definitions
-}
uniqueEntitiesFromEnrichments : List WikichunkEnrichment -> List Entity
uniqueEntitiesFromEnrichments enrichments =
  enrichments
  |> List.concatMap .chunks
  |> List.concatMap .entities
  |> List.Extra.uniqueBy .id


{-| Look up an Entity's title by the Entity's id
-}
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


{-| Relative page URL within the application
-}
homePath =
  "/"

profilePath =
  "/profile"

searchPath =
  "/search"

-- notesPath =
--   "/notes"

favoritesPath =
  "/favorites"

loginPath =
   "/login"

signupPath =
  "/signup"

logoutPath =
  "/logout"


{-| Takes a getter function (such as .price) and a collection (such as cars)
    Returns the mean (e.g. the average price of all the cars)
-}
averageOf : (a -> Float) -> List a -> Float
averageOf getterFunction records =
  (records |> List.map getterFunction |> List.sum) / (records |> List.length |> toFloat)


{-| Interpolate between two numbers a and b, using "phase" to crossfade
-}
interp : Float -> Float -> Float -> Float
interp phase a b =
  phase * b + (1-phase) * a


{-| Check whether the current user is a participant in a scientific experiment.
    By convention, lab study participants use researcher-created accounts that have short identifiers such as "p1", "p2"... instead of an email address.
-}
isLabStudy1 : Model -> Bool
isLabStudy1 model =
  case loggedInUserProfile model of
    Nothing ->
      False

    Just {email} ->
      email |> String.contains "@" |> not


{-| Check whether a list contains both elements x and y
-}
listContainsBoth : a -> a -> List a -> Bool
listContainsBoth x y list =
  List.member x list && List.member y list


{-| Arbitrary factor controlling the size of bubbles
-}
bubbleZoom : Float
bubbleZoom =
  0.042


{-| Check if the OER is a video file
-}
isVideoFile : OerUrl -> Bool
isVideoFile oerUrl =
  let
      lower =
        oerUrl |> String.toLower
  in
     String.endsWith ".mp4" lower || String.endsWith ".webm" lower || String.endsWith ".ogg" lower


{-| Check it the OER is a pdf file
-}
isPdfFile : OerUrl -> Bool
isPdfFile oerUrl =
  String.endsWith ".pdf" (oerUrl |> String.toLower)


{-| Relative URL of the full-page OER view
-}
resourceUrlPath : OerId -> String
resourceUrlPath oerId =
  searchPath ++ "?q=" ++ (String.fromInt oerId) ++ "&i=" ++ (String.fromInt oerId)


{-| In an emergency, temporarily set this to true, then compile and redeploy
-}
isSiteUnderMaintenance : Bool
isSiteUnderMaintenance =
  False


{-| Check whether a particular OER's metadata has been loaded from the server
-}
isOerLoaded : Model -> OerId -> Bool
isOerLoaded model oerId =
  case model.cachedOers |> Dict.get oerId of
    Nothing ->
      False

    Just _ ->
      True


{-| Read the value from a user feedback form
    Defaults to empty String
-}
getResourceFeedbackFormValue : Model -> OerId -> String
getResourceFeedbackFormValue model oerId =
  model.feedbackForms |> Dict.get oerId |> Maybe.withDefault ""


{-| How long (in milliseconds) the snackbar message should be visible to the user.
-}
snackbarDuration : Int
snackbarDuration =
  3000


{-| Return the N-th element from a list (if available).
    Elm doesn't have a built-in function for this because it's considered bad practice.
    I needed it for the occasional workaround, for lack of a more elegant method. Apologies.
-}
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


{-| Check whether a particular OER is one of the user's favourites
-}
isMarkedAsFavorite : Model -> OerId -> Bool
isMarkedAsFavorite model oerId =
  List.member oerId model.favorites && (Set.member oerId model.removedFavorites |> not)


{-| Check whether the user has just "favorited" an OER in the last second or so
-}
isFlyingHeartAnimating : Model -> Bool
isFlyingHeartAnimating model =
  model.flyingHeartAnimation /= Nothing


{-| When the user adds an OER to their favorites, there is a short animation.
    This is the duration in milliseconds.
-}
flyingHeartAnimationDuration : Int
flyingHeartAnimationDuration =
  900


{-| Check whether the mouse is hovering over a particular OER
    TODO refactor to rename this function
-}
isHovering : Model -> Oer -> Bool
isHovering model oer =
  model.hoveringOerId == Just oer.id


{-| Check whether a particular OER is currently in the open inspector modal
-}
isInspecting : Model -> Oer -> Bool
isInspecting model {id} =
  case model.inspectorState of
    Just {oer} ->
      oer.id==id
    _ ->
      False


{-| Check whether the user has ContentFlow enabled
-}
isContentFlowEnabled : Model -> Bool
isContentFlowEnabled model =
  case model.session of
    Nothing ->
      False
    Just session ->
      session.isContentFlowEnabled


{-| If the OER has been added to a course, return the corresponding CourseItem.
    Otherwise, return Nothing
-}
getCourseItem : Model -> Oer -> Maybe CourseItem
getCourseItem model oer =
  model.course.items
  |> List.filter (\{oerId} -> oerId == oer.id)
  |> List.head


{-| Change the order of two elements in a list.
    Used for changing the order of CourseItems in a Course
-}
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


{-| Ensure that the length of a range is always positive.
    Flip start and end point if necessary.
-}
invertRangeIfNeeded : Range -> Range
invertRangeIfNeeded range =
  if range.length < 0 then
    { start = range.start + range.length
    , length = -range.length
    }
  else
    range


{-| Scale a given Range by a given factor.
    Used to convert relative to absolute time segments
-}
multiplyRange : Float -> Range -> Range
multiplyRange factor {start, length} =
  { start = start * factor
  , length = length * factor
  }


{-| The interface works best on large screens.
    Users with screens that are too small should see a warning.
-}
isBrowserWindowTooSmall : Model -> Bool
isBrowserWindowTooSmall model =
  model.windowWidth < model.minWindowWidth || model.windowHeight < model.minWindowHeight


{-| Display names of overview types.
    These are the names as they appear in the GUI, not necessarily in the database.
-}
overviewTypeDisplayName : OverviewType -> String
overviewTypeDisplayName overviewType =
  case overviewTypes |> List.filter (\entry -> entry.overviewType == overviewType) |> List.head of
    Nothing ->
      "Unknown OverviewType" -- make sure this never happens

    Just entry ->
      entry.displayName


{-| Permanent IDs of overview types.
    These are the names as they appear in the database, not necessarily in the GUI.
-}
overviewTypeId : OverviewType -> String
overviewTypeId overviewType =
  case overviewTypes |> List.filter (\entry -> entry.overviewType == overviewType) |> List.head of
    Nothing ->
      "unknown" -- make sure this never happens

    Just entry ->
      entry.id


{-| This function takes an id (as in the database) and returns the corresponding Elm value.
-}
overviewTypeFromId : String -> OverviewType
overviewTypeFromId id =
  case overviewTypes |> List.filter (\entry -> entry.id == id) |> List.head of
    Nothing ->
      ImageOverview -- Default to thumbnails

    Just entry ->
      entry.overviewType


{-| For each value of OverviewType, we need a displayName (as shown in the GUI) and a permanent ID (for the database).
    Two things are essential here:
    1. You MUST include every possible value of OverviewType in this list.
    2. You MUST keep the values for ID the same, in order to prevent inconsistent states on the server.
    In contrast, feel free to change the values for displayName as needed: These affect only the GUI.
-}
overviewTypes : List { id : String, displayName : String, overviewType : OverviewType }
overviewTypes =
  [ { id = "thumbnail", displayName = "Thumbnail", overviewType = ImageOverview }
  , { id = "topicnames", displayName = "Topic Names", overviewType = BubblogramOverview TopicNames }
  , { id = "bubbles", displayName = "Bubbles", overviewType = BubblogramOverview TopicConnections }
  , { id = "swimlanes", displayName = "Swimlanes", overviewType = BubblogramOverview TopicMentions }
  ]
