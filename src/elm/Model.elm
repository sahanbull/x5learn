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
  , userMessage : Maybe String
  , hoveringOerUrl : Maybe String
  , timeOfLastMouseEnterOnCard : Posix
  , modalAnimation : Maybe BoxAnimation
  , animationsPending : Set String
  , gains : Maybe (List Gain)
  , nextSteps : Maybe (List Pathway)
  , popup : Maybe Popup
  , requestingWikichunkEnrichments : Bool
  , wikichunkEnrichments : Dict OerUrl WikichunkEnrichment
  , enrichmentsAnimating : Bool
  , tagClouds : Dict String (List String)
  , searchSuggestions : List String
  , selectedSuggestion : String
  , suggestionSelectionOnHoverEnabled : Bool
  , timeOfLastSearch : Posix
  , userProfileForm : UserProfileForm
  , userProfileFormSubmitted : Maybe UserProfileForm
  , oerNoteForms : Dict OerUrl String
  , feedbackForms : Dict OerId String
  , cachedOers : Dict OerUrl Oer
  , requestingOers : Bool
  , hoveringBubbleEntityId : Maybe String
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
  , oerNoteboards : Dict String (List Note)
  , fragmentAccesses : Dict Int Fragment
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
  = Loaded OerUrl
  | Error

type alias LabStudyTask =
  { title : String
  , durationInMinutes : Int
  , dataset : String
  }

type alias Bubble =
  { entity : Entity
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

type alias ScrollData =
  { scrollTop : Float
  , viewHeight : Float
  , contentHeight : Float
  }


type alias Note =
  { text : String
  , time : Posix
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
  | Notes
  | Recent
  | Resource


type alias SearchState =
  { lastSearch : String
  , searchResults : Maybe (List OerUrl)
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

type alias BubblePopupState = { oerUrl : OerUrl, entityId : String, content : BubblePopupContent, nextContents : List BubblePopupContent }

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
  { oerUrl : OerUrl
  , start : Float -- 0 to 1
  , length : Float -- 0 to 1
  }


type alias Playlist =
  { title : String
  , oerUrls : List OerUrl
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
  , userMessage = Nothing
  , hoveringOerUrl = Nothing
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
  , searchSuggestions = []
  , selectedSuggestion = ""
  , suggestionSelectionOnHoverEnabled = True -- prevent accidental selection when user doesn't move the pointer but the menu appears on the pointer
  , timeOfLastSearch = initialTime
  , userProfileForm = freshUserProfileForm (initialUserProfile "")
  , userProfileFormSubmitted = Nothing
  , oerNoteForms = Dict.empty
  , feedbackForms = Dict.empty
  , cachedOers = Dict.empty
  , requestingOers = False
  , hoveringBubbleEntityId = Nothing
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
  }


initialUserProfile email =
  UserProfile email "" ""


getOerNoteboard : Model -> String -> Noteboard
getOerNoteboard model oerUrl =
  model.oerNoteboards
  |> Dict.get oerUrl
  |> Maybe.withDefault []


getOerNoteForm : Model -> OerUrl -> String
getOerNoteForm model oerUrl =
  model.oerNoteForms
  |> Dict.get oerUrl
  |> Maybe.withDefault ""


getOerIdFromOerUrl : Model -> OerUrl -> OerId
getOerIdFromOerUrl model oerUrl =
  case model.cachedOers |> Dict.get oerUrl of
    Just oer ->
      oer.id

    Nothing ->
      0


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


isInPlaylist : OerUrl -> Playlist -> Bool
isInPlaylist oerUrl playlist =
  List.member oerUrl playlist.oerUrls


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


getCachedOerWithBlankDefault : Model -> OerUrl -> Oer
getCachedOerWithBlankDefault model oerUrl =
  model.cachedOers
  |> Dict.get oerUrl
  |> Maybe.withDefault (blankOer oerUrl)


-- temporary solution. TODO: refactor Oer data type
blankOer oerUrl =
  { id = 0
  , date = ""
  , description = ""
  , duration = ""
  , images = []
  , provider = ""
  , title = ""
  , url = oerUrl
  , mediatype = ""
  }


mostRecentFragmentAccess : Dict Int Fragment -> Maybe (Int, Fragment)
mostRecentFragmentAccess fragmentAccesses =
  fragmentAccesses
  |> Dict.toList
  |> List.reverse
  |> List.head


chunksFromUrl : Model -> OerUrl -> List Chunk
chunksFromUrl model oerUrl =
  case model.wikichunkEnrichments |> Dict.get oerUrl of
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


getMentions : Model -> OerUrl -> String -> List MentionInOer
getMentions model oerUrl entityId =
  case model.wikichunkEnrichments |> Dict.get oerUrl of
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


homePath =
  "/"

profilePath =
  "/profile"

searchPath =
  "/search"

notesPath =
  "/notes"

recentPath =
  "/recent"

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


trimTailingEllipsisIfNeeded str = -- This function is a temporary patch to fix a mistake I made whereby an additional character was erroneously added to the provider field. Only the youtube videos for the first lab study are affected. Delete this function after re-ingesting or removing those oers.
  if str |> String.endsWith "…" then
    str |> String.dropRight 1
  else
    str


resourceUrlPath oerId =
  resourcePath ++ "/" ++ (String.fromInt oerId)


isSiteUnderMaintenance =
  False


relatedSearchStringFromOer : Model -> OerUrl -> String
relatedSearchStringFromOer model oerUrl =
  case model.cachedOers |> Dict.get oerUrl of
    Nothing ->
      "kittens" -- this really shouldn't happen

    Just {title} ->
      title

  -- case model.wikichunkEnrichments |> Dict.get oerUrl of
  --   Nothing ->
  --     case model.cachedOers |> Dict.get oerUrl of
  --       Nothing ->
  --         "kittens" -- this really shouldn't happen

  --   Just {bubblogram, chunks} ->
  --     case bubblogram of
  --       Nothing ->

  --     enrichment.BubblePopup


getResourceFeedbackFormValue model oerId =
  model.feedbackForms |> Dict.get oerId |> Maybe.withDefault ""
