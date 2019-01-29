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
  , viewedFragments : List Fragment
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


type alias Fragment =
  { url : String
  , startPosition : Float -- from 0 to 1
  , endPosition : Float
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
  , playlists = initialPlaylists
  , viewedFragments = [ Fragment bishopBook.url 0.2 0.5, Fragment bishopBook.url 0.6 0.7 ]
  }


bishopBook =
  { url = "https://www.microsoft.com/en-us/research/people/cmbishop/#!prml-book"
  , provider = "https://www.microsoft.com"
  , date = "2006"
  , title = "Pattern Recognition and Machine Learning"
  , duration = ""
  , description = "This leading textbook provides a comprehensive introduction to the fields of pattern recognition and machine learning. It is aimed at advanced undergraduates or first-year PhD students, as well as researchers and practitioners. No previous knowledge of pattern recognition or machine learning concepts is assumed. This is the first machine learning textbook to include a comprehensive coverage of recent developments such as probabilistic graphical models and deterministic inference methods, and to emphasize a modern Bayesian perspective. It is suitable for courses on machine learning, statistics, computer science, signal processing, computer vision, data mining, and bioinformatics. This hard cover book has 738 pages in full colour, and there are 431 graded exercises (with solutions available below). Extensive support is provided for course instructors."
  , imageUrls = [ "https://www.microsoft.com/en-us/research/wp-content/uploads/2016/06/Springer-Cover-Image-752x1024.jpg" ]
  , youtubeVideoVersions = Dict.singleton "English" ""
  }


initialTime =
  Time.millisToPosix 0


initialPlaylists =
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
