module Model exposing (..)

import Browser
import Browser.Navigation as Navigation
import Url
import Time exposing (Posix, posixToMillis)
import Element exposing (Color, rgb255)
import Dict exposing (Dict)
import Set exposing (Set)

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
  , playlists : List Playlist
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
  , activeMenu : Maybe SearchStateMenu
  }


type alias Oer =
  { url : String
  , provider : String
  , date : String
  , title : String
  , duration : String
  , description : String
  , imageUrls : List String
  , youtubeVideoVersions : Dict String String -- key: language, value: youtubeId
  }


type alias Playlist =
  { title : String
  , oers : List Oer
  }


type AnimationStatus
  = Inactive
  | Prestart
  | Started


type SearchStateMenu
  = SaveToPlaylistMenu


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
  , playlists = [ Playlist "Watch later" [] ]
  }


initialTime =
  Time.millisToPosix 0


newSearch str =
  { lastSearch = str
  , searchResults = Nothing
  }


newInspectorState : Oer -> InspectorState
newInspectorState oer =
  InspectorState oer Nothing


hasVideo : Oer -> Bool
hasVideo oer =
  (oer.youtubeVideoVersions |> Dict.isEmpty |> not) || (isFromVideoLecturesNet oer)


getYoutubeId : Oer -> Maybe String
getYoutubeId oer =
  oer.youtubeVideoVersions
  |> Dict.get "English"


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
