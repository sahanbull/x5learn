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
  , wikichunkEnrichmentLoadTimes : Dict OerUrl Posix
  , enrichmentsAnimating : Bool
  , tagClouds : Dict String (List String)
  , searchSuggestions : List String
  , selectedSuggestion : String
  , suggestionSelectionOnHoverEnabled : Bool
  , timeOfLastSearch : Posix
  , userProfileForm : UserProfileForm
  , userProfileFormSubmitted : Maybe UserProfileForm
  , oerNoteForms : Dict OerUrl String
  , cachedOers : Dict OerUrl Oer
  , requestingOers : Bool
  , hoveringBubbleEntityId : Maybe String
  , cachedMentions : MentionsDict
  , entityDefinitions : Dict String EntityDefinition
  , requestingEntityDefinitions : Bool
  , wikichunkEnrichmentRequestFailCount : Int
  , wikichunkEnrichmentRetryTime : Posix
  , timeOfLastUrlChange : Posix
  }


-- persisted on backend
type alias UserState =
  { fragmentAccesses : Dict Int Fragment
  , oerNoteboards : Dict String (List Note)
  , registrationComplete : Bool
  }

type EntityDefinition
  = DefinitionScheduledForLoading
  | DefinitionLoaded String
  -- | DefinitionUnavailable -- TODO consider appropriate error handling

type alias OerUrl = String

type alias Noteboard = List Note

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
  { date : String
  , description : String
  , duration : String
  , images : List String
  , provider : String
  , title : String
  , url : String
  , mediatype : String
  }


type alias WikichunkEnrichment =
  { chunks : List Chunk
  , errors : Bool
  }

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

type alias MentionsDict = Dict (OerUrl,String) (List MentionInOer)

type alias MentionInOer =
  { chunkIndex : Int
  , indexInChunk : Int
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
  { userState : UserState
  , loginState : LoginState
  }


type LoginState
  = GuestUser
  | LoggedInUser UserProfile


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
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
  , wikichunkEnrichmentLoadTimes = Dict.empty
  , enrichmentsAnimating = False
  , tagClouds = Dict.empty
  , searchSuggestions = []
  , selectedSuggestion = ""
  , suggestionSelectionOnHoverEnabled = True -- prevent accidental selection when user doesn't move the pointer but the menu appears on the pointer
  , timeOfLastSearch = initialTime
  , userProfileForm = freshUserProfileForm (initialUserProfile "")
  , userProfileFormSubmitted = Nothing
  , oerNoteForms = Dict.empty
  , cachedOers = Dict.empty
  , requestingOers = False
  , hoveringBubbleEntityId = Nothing
  , cachedMentions = Dict.empty
  , entityDefinitions = Dict.empty
  , requestingEntityDefinitions = False
  , wikichunkEnrichmentRequestFailCount = 0
  , wikichunkEnrichmentRetryTime = initialTime
  , timeOfLastUrlChange = initialTime
  }


initialUserState =
  { fragmentAccesses = Dict.empty
  , oerNoteboards = Dict.empty
  , registrationComplete = False
  }


initialUserProfile email =
  UserProfile email "" ""


getOerNoteboard : UserState -> String -> Noteboard
getOerNoteboard userState oerUrl =
  userState.oerNoteboards
  |> Dict.get oerUrl
  |> Maybe.withDefault []


getOerNoteForm : Model -> String -> String
getOerNoteForm model oerUrl =
  model.oerNoteForms
  |> Dict.get oerUrl
  |> Maybe.withDefault ""


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
  { date = ""
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
chunksFromUrl model url =
  case model.wikichunkEnrichments |> Dict.get url of
    Nothing ->
      []

    Just enrichment ->
      enrichment.chunks


enrichmentAnimationDuration =
  5000


anyUrlChangeOrEnrichmentsLoadedRecently : Model -> Bool
anyUrlChangeOrEnrichmentsLoadedRecently model =
  if millisSinceLastUrlChange model < enrichmentAnimationDuration then
    True
  else
    model.wikichunkEnrichmentLoadTimes
    |> Dict.values
    |> List.any (\loadTime -> (posixToMillis model.currentTime) - (posixToMillis loadTime) < enrichmentAnimationDuration)


millisSinceEnrichmentLoaded model url =
  case model.wikichunkEnrichmentLoadTimes |> Dict.get url of
    Nothing -> -- shouldn't happen
      100000000

    Just time ->
      (model.currentTime |> posixToMillis) - (time |> posixToMillis)


millisSinceLastUrlChange model =
  (model.currentTime |> posixToMillis) - (model.timeOfLastUrlChange |> posixToMillis)


isEqualToSearchString model entityTitle =
  case model.searchState of
    Nothing ->
      False

    Just searchState ->
      (entityTitle |> String.toLower) == (searchState.lastSearch |> String.toLower)


getMentions : Model -> OerUrl -> String -> Maybe (List MentionInOer)
getMentions model oerUrl entityId =
  model.cachedMentions |> Dict.get (oerUrl, entityId)


hasMentions : Model -> OerUrl -> String -> Bool
hasMentions model oerUrl entityId =
  case getMentions model oerUrl entityId of
    Nothing ->
      False

    Just mentions ->
      mentions
      |> List.isEmpty
      |> not


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
