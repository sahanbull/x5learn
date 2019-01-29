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

    NewSearch ->
      ( { model | searchState = newSearch model.searchInputTyping |> Just }, searchOers model.searchInputTyping )

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y }, Cmd.none )

    InspectSearchResult oer ->
      ( { model | inspectorState = Just <| newInspectorState oer, animationsPending = model.animationsPending |> Set.insert modalId }, openModalAnimation modalId)

    UninspectSearchResult ->
      ( { model | inspectorState = Nothing}, Cmd.none)

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
      ( { model | userMessage = Just "There was a problem with the search data" }, Cmd.none )

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )

    OpenSaveToBookmarklistMenu inspectorState ->
      ( { model | inspectorState = Just { inspectorState | activeMenu = Just SaveToBookmarklistMenu } }, Cmd.none )

    AddToBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = oer :: p.oers } else p)}, Cmd.none )

    RemoveFromBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = p.oers |> List.filter (\o -> o.url /= oer.url) } else p)}, Cmd.none )


updateSearch : (SearchState -> SearchState) -> Model -> Model
updateSearch transformFunction model =
  case model.searchState of
    Nothing ->
      model

    Just searchState ->
      { model | searchState = Just (searchState |> transformFunction) }


insertSearchResults results searchState =
  { searchState | searchResults = Just results }


incrementFrameCountInModalAnimation : Model -> Model
incrementFrameCountInModalAnimation model =
  case model.modalAnimation of
    Nothing ->
      model

    Just animation ->
      { model | modalAnimation = Just { animation | frameCount = animation.frameCount + 1 } }
