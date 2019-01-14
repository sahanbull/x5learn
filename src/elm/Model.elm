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
  , searchText : String
  }


type alias Flags =
  { windowWidth : Int
  , windowHeight : Int
  }


type alias Nav =
  { url : Url.Url
  , key : Navigation.Key
  }


initialModel : Nav -> Flags -> Model
initialModel nav flags =
  { nav = nav
  , windowWidth = flags.windowWidth
  , windowHeight = flags.windowHeight
  , searchText = ""
  }
