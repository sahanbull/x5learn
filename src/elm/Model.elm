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
  , userMessage : Maybe String
  , hoveringOerUrl : Maybe String
  , timeOfLastMouseEnterOnCard : Posix
  , modalAnimation : Maybe BoxAnimation
  , animationsPending : Set String
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
  , inspectedSearchResult : Maybe Oer
  , searchResults : Maybe (List Oer)
  }


type alias Oer =
  { url : String
  , provider : String
  , title : String
  , description : String
  , imageUrls : List String
  , youtubeVideoVersions : Dict String String -- key: language, value: youtubeId
  }


type AnimationStatus
  = Inactive
  | Prestart
  | Started


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , currentTime = initialTime
  , searchInputTyping = ""
  , searchState = Nothing
  , userMessage = Nothing
  , hoveringOerUrl = Nothing
  , timeOfLastMouseEnterOnCard = initialTime
  , modalAnimation = Nothing
  , animationsPending = Set.empty
  }


initialTime =
  Time.millisToPosix 0


newUserFromSearch str =
  { lastSearch = str
  , inspectedSearchResult = Nothing
  , searchResults = Nothing
  }


hasVideo : Oer -> Bool
hasVideo oer =
  oer.youtubeVideoVersions |> Dict.isEmpty |> not


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
