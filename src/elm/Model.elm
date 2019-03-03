module Model exposing (..)

import Browser
import Browser.Navigation as Navigation
import Url
import Time exposing (Posix, posixToMillis)
import Element exposing (Color, rgb255)
import Dict exposing (Dict)
import Set exposing (Set)
import Regex
import List.Extra

import Animation exposing (..)


type alias Model =
  { nav : Nav
  , windowWidth : Int
  , windowHeight : Int
  , currentTime : Posix
  , searchInputTyping : String
  , searchState : Maybe SearchState
  , inspectorState : Maybe InspectorState
  , userMessage : Maybe String
  , hoveringOerUrl : Maybe String
  , timeOfLastMouseEnterOnCard : Posix
  , modalAnimation : Maybe BoxAnimation
  , animationsPending : Set String
  , bookmarklists : List Playlist
  , viewedFragments : Maybe (List Fragment)
  , nextSteps : Maybe (List Pathway)
  , popup : Maybe Popup
  , entityLabels : Dict String String
  , entityDescriptions : Dict String String
  , requestingEntityLabels : Bool
  , floatingDefinition : Maybe String
  -- , requestingEntityDefinition : Bool
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
  , activeMenu : Maybe InspectorMenu
  }


type alias Oer =
  { date : String
  , description : String
  , duration : String
  , images : List String
  , provider : String
  , title : String
  , transcript : String
  , url : String
  , wikichunks : List Chunk
  }


type alias Chunk =
  { start : Float -- 0 to 1
  , length : Float -- 0 to 1
  , entities : List String
  }


type Popup
  = ChunkOnBar ChunkPopup


type alias ChunkPopup = { barId : String, oer : Oer, chunk : Chunk, entityPopup : Maybe EntityPopup }

type alias EntityPopup = { entityId : String, hoveringAction : Maybe String }


type alias Fragment =
  { oer : Oer
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
  = SaveToBookmarklistMenu


type alias OerSearchResponse =
  { oers : List Oer
  , entityLabels : Dict String String
  }


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , currentTime = initialTime
  , searchInputTyping = ""
  , searchState = Nothing
  , inspectorState = Nothing
  , userMessage = Nothing
  , hoveringOerUrl = Nothing
  , timeOfLastMouseEnterOnCard = initialTime
  , modalAnimation = Nothing
  , animationsPending = Set.empty
  , bookmarklists = initialBookmarklists
  , viewedFragments = Nothing
  , nextSteps = Nothing
  , popup = Nothing
  , entityLabels = Dict.empty
  , entityDescriptions = Dict.empty
  , requestingEntityLabels = False
  , floatingDefinition = Nothing
  -- , requestingEntityDefinition = False
  }


initialTime =
  Time.millisToPosix 0


initialBookmarklists =
  [ Playlist "Statistics" []
  , Playlist "Python" []
  , Playlist "Fun stuff" []
  , Playlist "Machine learning in Music" []
  , Playlist "Shared with Alice" []
  ]


newSearch str =
  { lastSearch = str
  , searchResults = Nothing
  }


newInspectorState : Oer -> InspectorState
newInspectorState oer =
  InspectorState oer Nothing


hasVideo : Oer -> Bool
hasVideo oer =
  case getYoutubeId oer of
    Nothing ->
      isFromVideoLecturesNet oer

    Just _ ->
      True


getYoutubeId : Oer -> Maybe String
getYoutubeId oer =
  oer.url
  |> String.split "="
  |> List.drop 1
  |> List.head
  |> Maybe.withDefault ""
  |> String.split "&"
  |> List.head


modalId =
  "modalId"


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
