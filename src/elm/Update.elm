module Update exposing (update)

import Browser
import Browser.Navigation as Navigation
import Url
import Json.Decode as Decode
import Json.Encode as Encode
import Dict
import Set
import Time exposing (Posix)
-- import Debug

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

    ClockTick time ->
      ( { model | currentTime = time }, Cmd.none )

    AnimationTick time ->
      ( { model | currentTime = time } |> incrementFrameCountInModalAnimation, Cmd.none )

    ChangeSearchText str ->
      ( { model | searchInputTyping = str }, Cmd.none )

    NewUserFromSearch ->
      ( { model | searchState = newUserFromSearch model.searchInputTyping |> Just }, searchOers model.searchInputTyping )

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y }, Cmd.none )

    InspectSearchResult oer ->
      ( { model | animationsPending = model.animationsPending |> Set.insert modalId } |> updateSearch (setInspectedSearchResult <| Just oer), openModalAnimation modalId)

    UninspectSearchResult ->
      ( model |> updateSearch (setInspectedSearchResult <| Nothing), Cmd.none)

    ModalAnimationStart animation ->
      ( { model | modalAnimation = Just animation }, Cmd.none )

    ModalAnimationStop dummy ->
      ( { model | modalAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove modalId }, Cmd.none )

    RequestOerSearch (Ok results) ->
      ( model |> updateSearch (insertSearchResults results), Cmd.none )

    RequestOerSearch (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOerSearch"
      -- in
          ( { model | userMessage = Just "Error in RequestOerSearch" }, Cmd.none )

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


incrementFrameCountInModalAnimation : Model -> Model
incrementFrameCountInModalAnimation model =
  case model.modalAnimation of
    Nothing ->
      model

    Just animation ->
      { model | modalAnimation = Just { animation | frameCount = animation.frameCount + 1 } }
