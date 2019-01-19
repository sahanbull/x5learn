module Model exposing (..)

import Browser
import Browser.Navigation as Navigation
import Url
import Time exposing (Posix)
import Element exposing (Color, rgb255)
import Dict exposing (Dict)


type alias Model =
  { nav : Nav
  , windowWidth : Int
  , windowHeight : Int
  , currentTime : Posix
  , searchInputTyping : String
  , userState : Maybe UserState
  , userMessage : Maybe String
  , hoveringOerUrl : Maybe String
  , timeOfLastMouseEnterOnCard : Posix
  }


type alias Flags =
  { windowWidth : Int
  , windowHeight : Int
  }


type alias Nav =
  { url : Url.Url
  , key : Navigation.Key
  }


type alias UserState =
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


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , currentTime = initialTime
  , searchInputTyping = ""
  , userState = Nothing
  , userMessage = Nothing
  , hoveringOerUrl = Nothing
  , timeOfLastMouseEnterOnCard = initialTime
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


modalHtmlId =
  "modalHtmlId"
