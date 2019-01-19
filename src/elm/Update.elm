module Update exposing (update)

import Browser
import Browser.Navigation as Navigation
import Url
import Json.Decode as Decode
import Json.Encode as Encode
import Dict
import Time exposing (Posix)
import Debug

import Model exposing (..)
import Msg exposing (..)
import Ports exposing (..)
import OerSearch exposing (searchOers)


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
      ( { model | searchState = newUserFromSearch model.searchInputTyping |> Just }, searchOers model.searchInputTyping )

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y }, Cmd.none )

    InspectSearchResult oer ->
      ( model |> updateSearch (setInspectedSearchResult <| Just oer), inspectSearchResult modalHtmlId)

    UninspectSearchResult ->
      ( model |> updateSearch (setInspectedSearchResult <| Nothing), inspectSearchResult modalHtmlId)

    TriggerAnim value ->
      -- let
      --     w 
      --       Decode.decodeValue value
      --       |> Result.withDefault 12345

      --     dummy =
      --       Debug.log "wwwwww" (String.fromFloat w)
      -- in
      ( model , Cmd.none )

    RequestOerSearch (Ok results) ->
      ( model |> updateSearch (insertSearchResults results), Cmd.none )

    RequestOerSearch (Err err) ->
      let
          dummy =
            err |> Debug.log "Error in RequestOerSearch"
      in
          ( { model | userMessage = Just "Error in RequestOerSearch" }, Cmd.none )

    ClockTick currentTime ->
      ( { model | currentTime = currentTime }, Cmd.none )

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )


updateSearch : (SearchState -> SearchState) -> Model -> Model
updateSearch transformFunction model =
  case model.searchState of
    Nothing ->
      model

    Just searchState ->
      { model | searchState = Just (searchState |> transformFunction) }


insertSearchResults results searchState =
  { searchState | searchResults = Just results }


setInspectedSearchResult maybeOer searchState =
  { searchState | inspectedSearchResult = maybeOer }
