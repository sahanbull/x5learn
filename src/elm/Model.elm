module Model exposing (..)

import Browser
import Browser.Navigation as Navigation
import Url
import Time exposing (Posix, posixToMillis, millisToPosix)
import Element exposing (Color, rgb255)
import Dict exposing (Dict)
import Set exposing (Set)
import Regex
import List.Extra

import Animation exposing (..)


type alias Model =
  { nav : Nav
  , subpage : Subpage
  , session : Maybe Session
  , windowWidth : Int
  , windowHeight : Int
  , mousePositionXwhenOnChunkTrigger : Float
  , currentTime : Posix
  , searchInputTyping : String
  , searchState : Maybe SearchState
  , inspectorState : Maybe InspectorState
  , snackbar : Maybe Snackbar
  , hoveringOerId : Maybe OerId
  , timeOfLastMouseEnterOnCard : Posix
  , modalAnimation : Maybe BoxAnimation
  , animationsPending : Set String
  , gains : Maybe (List Gain)
  , nextSteps : Maybe (List Pathway)
  , popup : Maybe Popup
  , requestingWikichunkEnrichments : Bool
  , wikichunkEnrichments : Dict OerId WikichunkEnrichment
  , enrichmentsAnimating : Bool
  , tagClouds : Dict String (List String)
  , autocompleteTerms : List String
  , autocompleteSuggestions : List String
  , selectedSuggestion : String
  , suggestionSelectionOnHoverEnabled : Bool
  , timeOfLastSearch : Posix
  , userProfileForm : UserProfileForm
  , userProfileFormSubmitted : Maybe UserProfileForm
  , oerNoteForms : Dict OerId String
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
  , oerNoteboards : Dict OerId Noteboard
  , fragmentAccesses : Dict Int Fragment
  , oerCardPlaceholderPositions : List OerCardPlaceholderPosition
  , overviewType : OverviewType
  , selectedMentionInStory : Maybe (OerId, MentionInOer)
  , selectedOerCollections : Set String
  , pageScrollState : PageScrollState
  , collectionsMenuOpen : Bool
  , cachedCollectionsSearchPredictions : Dict String CollectionsSearchPrediction -- key = Search term
  , favorites : List OerId
  , hoveringHeart : Maybe OerId
  , flyingHeartAnimation : Maybe FlyingHeartAnimation
  , flyingHeartAnimationStartPoint : Maybe Point
  }


type alias CollectionsSearchPrediction = Dict String Int

type alias CollectionsSearchPredictionResponse =
  { searchText : String
  , prediction : CollectionsSearchPrediction
  }

type EntityDefinition
  = DefinitionScheduledForLoading
  | DefinitionLoaded String
  -- | DefinitionUnavailable -- TODO consider appropriate error handling

type ResourceSidebarTab
  = NotesTab
  | RecommendationsTab
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


type alias OerCollection =
  { title : String
  , description : String
  , url : String
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
  | Favorites
  | Notes
  | Viewed
  | Resource


type alias SearchState =
  { lastSearch : String
  , searchResults : Maybe (List OerId)
  }


type alias InspectorState =
  { oer : Oer
  , fragmentStart : Float
  , activeMenu : Maybe InspectorMenu
  }


type alias Oer =
  { id : Int
  , date : String
  , description : String
  , duration : String
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

type alias Gain =
  { title : String
  , level : Float
  , confidence : Float
  }


type alias Fragment =
  { oerId : OerId
  , start : Float -- 0 to 1
  , length : Float -- 0 to 1
  }


type alias Playlist =
  { title : String
  , oerIds : List OerId
  }


type alias Pathway =
  { rationale : String
  , fragments : List Fragment
  }


type AnimationStatus
  = Inactive
  | Prestart
  | Started


type InspectorMenu
  = QualitySurvey -- TODO


type alias Session =
  { loginState : LoginState
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
  , hoveringOerId = Nothing
  , timeOfLastMouseEnterOnCard = initialTime
  , modalAnimation = Nothing
  , animationsPending = Set.empty
  , gains = Nothing
  , nextSteps = Nothing
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
  , oerNoteForms = Dict.empty
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
  , resourceSidebarTab = NotesTab
  , resourceRecommendations = []
  , timeOfLastFeedbackRecorded = initialTime
  , oerNoteboards = Dict.empty
  , fragmentAccesses = Dict.empty
  , oerCardPlaceholderPositions = []
  , overviewType = ImageOverview
  , selectedMentionInStory = Nothing
  , selectedOerCollections = setOfAllCollectionTitles
  , pageScrollState = PageScrollState 0 0 0 False
  , collectionsMenuOpen = False
  , cachedCollectionsSearchPredictions = Dict.empty
  , favorites = []
  , hoveringHeart = Nothing
  , flyingHeartAnimation = Nothing
  , flyingHeartAnimationStartPoint = Nothing
  }


initialUserProfile email =
  UserProfile email "" ""


getOerNoteboard : Model -> OerId -> Noteboard
getOerNoteboard model oerId =
  model.oerNoteboards
  |> Dict.get oerId
  |> Maybe.withDefault []


getOerNoteForm : Model -> OerId -> String
getOerNoteForm model oerId =
  model.oerNoteForms
  |> Dict.get oerId
  |> Maybe.withDefault ""


-- getOerIdFromOerId : Model -> OerId -> OerId
-- getOerIdFromOerId model oerId =
--   case model.cachedOers |> Dict.get oerId of
--     Just oer ->
--       oer.id

    -- Nothing ->
    --   0


initialTime =
  Time.millisToPosix 0


newSearch str =
  { lastSearch = str
  , searchResults = Nothing
  }


newInspectorState : Oer -> Float -> InspectorState
newInspectorState oer fragmentStart =
  InspectorState oer fragmentStart Nothing


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


currentUrlMatches model url =
  url == model.nav.url.path


isFromVideoLecturesNet oer =
  String.startsWith "http://videolectures.net/" oer.url


isInPlaylist : OerId -> Playlist -> Bool
isInPlaylist oerId playlist =
  List.member oerId playlist.oerIds


durationInSecondsFromOer : Oer -> Int
durationInSecondsFromOer {duration} =
  let
      parts =
        duration
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


freshUserProfileForm userProfile =
  { userProfile = userProfile, saved = False }


mostRecentFragmentAccess : Dict Int Fragment -> Maybe (Int, Fragment)
mostRecentFragmentAccess fragmentAccesses =
  fragmentAccesses
  |> Dict.toList
  |> List.reverse
  |> List.head


chunksFromOerId : Model -> OerId -> List Chunk
chunksFromOerId model oerId =
  case model.wikichunkEnrichments |> Dict.get oerId of
    Nothing ->
      []

    Just enrichment ->
      enrichment.chunks


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


bubblogramAnimationPhase model createdAt =
  let
      millisSinceStart =
        millisSince model createdAt
        |> Basics.min (millisSinceLastUrlChange model)
        |> toFloat
  in
      millisSinceStart / enrichmentAnimationDuration * 2 |> Basics.min 1


millisSinceLastUrlChange model =
  (model.currentTime |> posixToMillis) - (model.timeOfLastUrlChange |> posixToMillis)


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

resourcePath =
  "/resource"

loginPath =
   "/login"

signupPath =
  "/signup"

logoutPath =
  "/logout"


averageOf getterFunction records =
  (records |> List.map getterFunction |> List.sum) / (records |> List.length |> toFloat)


interp : Float -> Float -> Float -> Float
interp phase a b =
  phase * b + (1-phase) * a


isLabStudy1 model =
  case loggedInUserProfile model of
    Nothing ->
      False

    Just {email} ->
      email |> String.endsWith ".lab"


listContainsBoth a b list =
  List.member a list && List.member b list


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


trimTailingEllipsisIfNeeded str = -- This function is a temporary patch to fix a mistake I made whereby an additional character was erroneously added to the provider field. Only the youtube videos for the first lab study are affected. Delete this function after re-ingesting or removing those oers.
  if str |> String.endsWith "…" then
    str |> String.dropRight 1
  else
    str


resourceUrlPath : OerId -> String
resourceUrlPath oerId =
  resourcePath ++ "/" ++ (String.fromInt oerId)


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


oerCollections =
  defaultOerCollection :: additionalOerCollections


defaultOerCollection =
  OerCollection "X5GON Platform" "Millions of lecture materials, videos and slide decks" "https://x5gon.org"


additionalOerCollections =
  [ OerCollection "Journal of Medical Internet Research (JMIR)" "Peer-reviewed Open Access Journal" "https://www.jmir.org/2019/8"
  , OerCollection "Mental Health Meetups London" "74 Meetup groups" "https://www.meetup.com/find/?allMeetups=false&keywords=mental+health&radius=5&userFreeform=Greater+London%2C+United+Kingdom&mcId=z2827702&mcName=Greater+London%2C+England%2C+GB&sort=default"
  , OerCollection "Mindfulness meditation" "Guided meditation videos on YouTube" "https://www.youtube.com/playlist?list=PLpb1DIPqFFN195vv7pnDFKtM9y5feLFp4"
  , OerCollection "National Institute of Mental Health (NIMH)" "180+ videos on YouTube" "https://www.youtube.com/user/NIMHgov/videos"
  , OerCollection "Alan Turing Institute" "350+ videos on YouTube" "https://www.youtube.com/channel/UCcr5vuAH5TPlYox-QLj4ySw/videos"
  , OerCollection "TED Talks" "2000+ videos on YouTube" "https://www.youtube.com/user/TEDtalksDirector/videos"
  , OerCollection "Numberphile" "400 videos on YouTube" "https://www.youtube.com/user/numberphile/videos"
  ]


getOerCollectionByTitle title =
  additionalOerCollections
  |> List.filter (\collection -> collection.title == title)
  |> List.head
  |> Maybe.withDefault defaultOerCollection


getPredictedNumberOfSearchResults : Model -> String -> Maybe Int
getPredictedNumberOfSearchResults model collectionTitle =
  case getCollectionsSearchPredictionOfLastSearch model of
    Nothing ->
      Nothing

    Just prediction ->
      Dict.get collectionTitle prediction


getCollectionsSearchPredictionOfLastSearch : Model -> Maybe CollectionsSearchPrediction
getCollectionsSearchPredictionOfLastSearch model =
  case model.searchState of
    Nothing ->
      Nothing

    Just {lastSearch} ->
      Dict.get lastSearch model.cachedCollectionsSearchPredictions


setOfAllCollectionTitles : Set String
setOfAllCollectionTitles =
  oerCollections
  |> List.map .title
  |> Set.fromList


selectedOerCollectionsToCommaSeparatedString : Model -> String
selectedOerCollectionsToCommaSeparatedString model =
  model.selectedOerCollections
  |> Set.toList
  |> String.join ","


selectedOerCollectionsToSummaryString : Model -> String
selectedOerCollectionsToSummaryString model =
  if model.selectedOerCollections == setOfAllCollectionTitles then
    "all collections"
  else
    case Set.toList model.selectedOerCollections of
      [ only ] ->
        only

      _ ->
        "selected collections"


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


isFavorite model oerId =
  List.member oerId model.favorites


isFlyingHeartAnimating model =
  model.flyingHeartAnimation /= Nothing


flyingHeartAnimationDuration =
  800
