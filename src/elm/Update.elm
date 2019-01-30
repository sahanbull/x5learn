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
import Request exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({nav} as model) =
  case msg of
    NoOp ->
      (model, Cmd.none)

    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Navigation.pushUrl model.nav.key (Url.toString url) )

        Browser.External href ->
          ( model, Navigation.load href )

    UrlChanged url ->
      let
          cmd =
            if url.path == "/next_steps" then
              requestNextSteps
            else if url.path == "/history" then
              requestViewedFragments
            else
              Cmd.none
      in
          ( { model | nav = { nav | url = url }, inspectorState = Nothing }, cmd )

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
      |> loadChunksIfNeeded

    RequestOerSearch (Err err) ->
      ( { model | userMessage = Just "There was a problem with the search data" }, Cmd.none )

    RequestNextSteps (Ok playlists) ->
      ( { model | nextSteps = Just playlists }, Cmd.none )
      |> loadChunksIfNeeded

    RequestNextSteps (Err err) ->
      ( { model | userMessage = Just "There was a problem with the recommendations data" }, Cmd.none )

    RequestViewedFragments (Ok fragments) ->
      ( { model | viewedFragments = Just fragments }, Cmd.none )
      |> loadChunksIfNeeded

    RequestViewedFragments (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestViewedFragments"
      -- in
      ( { model | userMessage = Just "There was a problem with the history data" }, Cmd.none )

    RequestChunks (Ok chunks) ->
      ( { model | oerChunks = model.oerChunks |> Dict.union chunks }, Cmd.none )

    RequestChunks (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestChunks"
      -- in
      ( { model | userMessage = Just "There was a problem with the chunk data" }, Cmd.none )

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )

    OpenSaveToBookmarklistMenu inspectorState ->
      ( { model | inspectorState = Just { inspectorState | activeMenu = Just SaveToBookmarklistMenu } }, Cmd.none )

    AddToBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = oer :: p.oers } else p)}, Cmd.none )

    RemoveFromBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = p.oers |> List.filter (\o -> o.url /= oer.url) } else p)}, Cmd.none )

    SetChunkPopover maybeTopics ->
      ( { model | chunkPopover = maybeTopics }, Cmd.none )


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


loadChunksIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
loadChunksIfNeeded (model, cmd) =
  let
      searchResults =
        case model.searchState of
          Nothing ->
            []

          Just searchState ->
            searchState.searchResults
            |> Maybe.withDefault []

      missingUrls =
        [ model.viewedFragments |> Maybe.withDefault [] |> List.map (\fragment -> fragment.oer)
        , model.nextSteps |> Maybe.withDefault [] |> List.map (\playlist -> playlist.oers) |> List.concat
        , searchResults
        ]
        |> List.concat
        |> List.map (\oer -> oer.url)
        |> Set.fromList
        |> Set.filter (\url -> model.oerChunks |> Dict.member url |> not)
  in
      (model, (if Set.isEmpty missingUrls then Cmd.none else requestChunks (Set.toList missingUrls)))
