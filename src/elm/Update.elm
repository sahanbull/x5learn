module Update exposing (update)

import Browser
import Browser.Navigation as Navigation
import Url

import Model exposing (..)
import Msg exposing (..)
import Ports exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({nav} as model) =
  case msg of
    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Navigation.pushUrl model.nav.key (Url.toString url) )

        Browser.External href ->
          ( model, Navigation.load href )

    UrlChanged url ->
      ( { model | nav = { nav | url = url } }, Cmd.none )

    ChangeSearchText str ->
      ( { model | searchInputTyping = str }, Cmd.none )

    NewUserFromSearch ->
      ( { model | userState = newUserFromSearch model.searchInputTyping |> Just }, Cmd.none )

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y }, Cmd.none )

    InspectSearchResult userState oer ->
      ( { model | userState = Just { userState | inspectedSearchResult = Just oer } }, Cmd.none )

    UninspectSearchResult userState ->
      ( { model | userState = Just { userState | inspectedSearchResult = Nothing } }, Cmd.none )
