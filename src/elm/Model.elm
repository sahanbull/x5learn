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
  }


type alias Oer =
  { title : String
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
  }


mockSearchResults =
  [ Oer "A discussion about ML"
  , Oer "PANEL: Experiences in research, teaching, and applications of ML"
  , Oer "Interview with Tom Mitchell"
  , Oer "Introduction to the Machine Learning over Text & Images - Autumn School by Eric Xing"
  , Oer "What Semantic Web researchers need to know about Machine Learning?"
  , Oer "Algorithmic Aspects of Machine Learning"
  , Oer "Relations Betweeen Machine Learning Problems"
  , Oer "Lecture 1 - The Motivation & Applications of Machine Learning"
  , Oer "What can machine learning do for open education?"
  ]
