module Update exposing (update)

import Browser
import Browser.Navigation as Navigation
import Url
import Url.Builder
import Json.Decode as Decode
import Json.Encode as Encode
import Dict
import Set
import Time exposing (Posix)

import Debug

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
      ( { model | currentTime = time }, Cmd.none)
      |> requestEntityLabelsIfNeeded

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

    RequestOerSearch (Ok oers) ->
      ( model |> updateSearch (insertSearchResults oers) |> includeEntityIds oers, Navigation.pushUrl nav.key "/search" )
      |> requestEntityLabelsIfNeeded

    RequestOerSearch (Err err) ->
      ( { model | userMessage = Just "There was a problem with the search data" }, Cmd.none )

    RequestNextSteps (Ok playlists) ->
      ( { model | nextSteps = Just playlists } |> includeEntityIds (playlists |> List.concatMap .oers), Cmd.none)
      |> requestEntityLabelsIfNeeded

    RequestNextSteps (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestNextSteps"
      -- in
          ( { model | userMessage = Just "There was a problem with the recommendations data" }, Cmd.none )

    RequestViewedFragments (Ok fragments) ->
      ( { model | viewedFragments = Just fragments } |> includeEntityIds (fragments |> List.map .oer), Cmd.none )
      |> requestEntityLabelsIfNeeded

    RequestViewedFragments (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestViewedFragments"
      -- in
      ( { model | userMessage = Just "There was a problem with the history data" }, Cmd.none)

    RequestEntityLabels (Ok incomingNames) ->
      ( { model | entityLabels = model.entityLabels |> Dict.union incomingNames, requestingEntityLabels = False }, Cmd.none )
      |> requestEntityLabelsIfNeeded

    RequestEntityLabels (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestViewedFragments"
      -- in
      ( { model | userMessage = Just "There was a problem with the wiki entity data", requestingEntityLabels = False }, Cmd.none )

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )

    OpenSaveToBookmarklistMenu inspectorState ->
      ( { model | inspectorState = Just { inspectorState | activeMenu = Just SaveToBookmarklistMenu } }, Cmd.none )

    AddToBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = oer :: p.oers } else p)}, Cmd.none )

    RemoveFromBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = p.oers |> List.filter (\o -> o.url /= oer.url) } else p)}, Cmd.none )

    SetPopMenuPath path ->
      let
          inspectorState =
            if path==[] then Nothing else model.inspectorState
      in
          ( { model | menuPath = path, inspectorState = inspectorState }, Cmd.none )


updateSearch : (SearchState -> SearchState) -> Model -> Model
updateSearch transformFunction model =
  case model.searchState of
    Nothing ->
      model

    Just searchState ->
      { model | searchState = Just (searchState |> transformFunction) }


insertSearchResults oers searchState =
  { searchState | searchResults = Just oers }


incrementFrameCountInModalAnimation : Model -> Model
incrementFrameCountInModalAnimation model =
  case model.modalAnimation of
    Nothing ->
      model

    Just animation ->
      { model | modalAnimation = Just { animation | frameCount = animation.frameCount + 1 } }


requestEntityLabelsIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
requestEntityLabelsIfNeeded (oldModel, oldCmd) =
  if oldModel.requestingEntityLabels then
    (oldModel, oldCmd)
  else
     let
         newModel =
           { oldModel | requestingEntityLabels = True }

         entityIds =
           oldModel.entityLabels
           |> Dict.filter (\_ name -> name=="")
           |> Dict.keys
           |> List.take 50 -- 50 is the current limit according to https://www.wikidata.org/w/api.php?action=help&modules=wbgetentities
     in
         if List.isEmpty entityIds then
           (oldModel, oldCmd)
         else
           (newModel, [ oldCmd, requestEntityLabels entityIds ] |> Cmd.batch)


includeEntityIds : List Oer -> Model -> Model
includeEntityIds incomingOers model =
  let
      entityLabels =
        incomingOers
        |> List.concatMap .wikichunks
        |> List.concatMap .entities
        |> Set.fromList
        |> Set.foldl (\entityId result -> if model.entityLabels |> Dict.member entityId then result else (result |> Dict.insert entityId "") ) model.entityLabels
  in
      { model | entityLabels = entityLabels }
