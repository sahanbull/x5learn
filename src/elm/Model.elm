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
  , entityDescriptions : Dict String String
  , requestingEntityDescriptions : Bool
  , tagClouds : Dict String (List String)
  , searchSuggestions : List String
  , selectedSuggestion : String
  , suggestionSelectionOnHoverEnabled : Bool
  , timeOfLastSearch : Posix
  , userProfileForm : UserProfileForm
  , userProfileFormSubmitted : Maybe UserProfileForm
  , oerNoteForms : Dict String String
  , cachedOers : Dict String Oer
  , requestingOers : Bool
  }


-- persisted on server
type alias UserState =
  { fragmentAccesses : Dict Int Fragment
  , oerNoteboards : Dict String (List Note)
  }


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
  , searchResults : Maybe (List Oer)
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
  , wikichunks : List Chunk
  , mediatype : String
  }


type alias Chunk =
  { start : Float -- 0 to 1
  , length : Float -- 0 to 1
  , entities : List Entity
  }


type alias Entity =
  { id : String
  , title : String
  , url : String
  }


type Popup
  = ChunkOnBar ChunkPopup
  | UserMenu


type alias ChunkPopup = { barId : String, oer : Oer, chunk : Chunk, entityPopup : Maybe EntityPopup }

type alias EntityPopup = { entityId : String, hoveringAction : Maybe String }

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
  , oers : List Oer
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
  , entityDescriptions = Dict.empty
  , requestingEntityDescriptions = False
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
  }


initialUserState =
  { fragmentAccesses = Dict.empty
  , oerNoteboards = Dict.empty
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


isInPlaylist : Oer -> Playlist -> Bool
isInPlaylist oer playlist =
  List.member oer playlist.oers


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
  , wikichunks = []
  , mediatype = ""
  }


mostRecentFragmentAccess : Dict Int Fragment -> Maybe (Int, Fragment)
mostRecentFragmentAccess fragmentAccesses =
  fragmentAccesses
  |> Dict.toList
  |> List.reverse
  |> List.head
