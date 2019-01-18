module Model exposing (..)

import Browser
import Browser.Navigation as Navigation
import Url
import Time exposing (Posix)
import Element exposing (Color, rgb255)

type alias Model =
  { nav : Nav
  , windowWidth : Int
  , windowHeight : Int
  , searchInputTyping : String
  , userState : Maybe UserState
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
  { title : String
  , hasVideo : Bool
  }


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , searchInputTyping = ""
  , userState = Nothing
  }


newUserFromSearch str =
  { lastSearch = str
  , inspectedSearchResult = Nothing
  , searchResults = Nothing
  }


modalHtmlId =
  "modalHtmlId"
