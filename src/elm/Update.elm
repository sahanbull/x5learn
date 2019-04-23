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
import List.Extra

-- import Debug exposing (log)

import Model exposing (..)
import Msg exposing (..)
import Ports exposing (..)
import Request exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({nav, userProfileForm} as model) =
  case msg of
    Initialized url ->
      let
          (newModel, cmd) =
            model |> update (UrlChanged url)
      in
          (newModel, [ cmd, requestSession ] |> Cmd.batch )

    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          if List.member (url.path |> String.dropLeft 1) ("login signup logout" |> String.split " ") then
            ( model |> closePopup, Navigation.load (Url.toString url) )
          else
            ( model |> closePopup, Navigation.pushUrl model.nav.key (Url.toString url) )

        Browser.External href ->
          ( model |> closePopup, Navigation.load href )

    UrlChanged url ->
      let
          cmd =
            if url.path == "/next_steps" then
              requestNextSteps
            else if url.path == "/history" then
              requestViewedFragments
            else if url.path == "/gains" then
              requestGains
            else
              Cmd.none
      in
          ( { model | nav = { nav | url = url }, inspectorState = Nothing } |> closePopup |> resetUserProfileForm, cmd )

    ClockTick time ->
      ( { model | currentTime = time }, Cmd.none)
      |> requestEntityDescriptionsIfNeeded

    AnimationTick time ->
      ( { model | currentTime = time } |> incrementFrameCountInModalAnimation, Cmd.none )

    ChangeSearchText str ->
      ( { model | searchInputTyping = str } |> closePopup, if String.length str > 1 then requestSearchSuggestions str else Cmd.none)

    TriggerSearch str ->
      ( { model | searchInputTyping = str, searchState = Just <| newSearch str, searchSuggestions = [], timeOfLastSearch = model.currentTime } |> closePopup, searchOers str)

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y } |> closePopup, Cmd.none )

    InspectSearchResult oer fragmentStart ->
      let
          inspectorParams =
            { modalId = modalId
            , videoId = getYoutubeVideoId oer |> Maybe.withDefault ""
            , fragmentStart = fragmentStart
            }
      in
          ( { model | inspectorState = Just <| newInspectorState oer fragmentStart, animationsPending = model.animationsPending |> Set.insert modalId } |> closePopup, openModalAnimation inspectorParams)

    UninspectSearchResult ->
      ( { model | inspectorState = Nothing}, Cmd.none)

    ModalAnimationStart animation ->
      ( { model | modalAnimation = Just animation }, Cmd.none )

    ModalAnimationStop dummy ->
      ( { model | modalAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove modalId }, Cmd.none )

    RequestSession (Ok session) ->
      ( { model | session = Just session } |> resetUserProfileForm, Cmd.none )

    RequestSession (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSession"
      -- in
      ( { model | userMessage = Just "There was a problem while requesting user data. Please try again later." }, Cmd.none )

    RequestOerSearch (Ok oers) ->
      ( model |> updateSearch (insertSearchResults oers) |> includeEntityIds oers, [ Navigation.pushUrl nav.key "/search", setBrowserFocus "SearchField" ] |> Cmd.batch )
      |> requestEntityDescriptionsIfNeeded

    RequestOerSearch (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOerSearch"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the search data" }, Cmd.none )

    RequestNextSteps (Ok pathways) ->
      let
          oers =
            pathways
            |> List.concatMap .fragments
            |> List.map .oer
      in
          ( { model | nextSteps = Just pathways } |> includeEntityIds oers, Cmd.none)
          |> requestEntityDescriptionsIfNeeded

    RequestNextSteps (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestNextSteps"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the recommendations data" }, Cmd.none )

    RequestViewedFragments (Ok fragments) ->
      ( { model | viewedFragments = Just fragments } |> includeEntityIds (fragments |> List.map .oer), Cmd.none )
      |> requestEntityDescriptionsIfNeeded

    RequestViewedFragments (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestViewedFragments"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the history data" }, Cmd.none)

    RequestGains (Ok gains) ->
      ( { model | gains = Just gains }, Cmd.none )

    RequestGains (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestGainsRequestViewedFragments"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the gains data" }, Cmd.none)

    RequestEntityDescriptions (Ok descriptions) ->
      let
          entityDescriptions =
            model.entityDescriptions |> Dict.union descriptions
      in
          ( { model | entityDescriptions = entityDescriptions, requestingEntityDescriptions = False }, Cmd.none )
          |> requestEntityDescriptionsIfNeeded

    RequestEntityDescriptions (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestEntityDescriptions"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the wiki descriptions data", requestingEntityDescriptions = False }, Cmd.none )

    RequestSearchSuggestions (Ok suggestions) ->
      if (millisSince model model.timeOfLastSearch) < 2000 then
        (model, Cmd.none)
      else
        ({ model | searchSuggestions = suggestions, suggestionSelectionOnHoverEnabled = False }, Cmd.none)

    RequestSearchSuggestions (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSearchSuggestions"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching search suggestions" }, Cmd.none )

    RequestSaveUserProfile (Ok _) ->
      ({ model | userProfileForm = { userProfileForm | saved = True }, userProfileFormSubmitted = Nothing }, Cmd.none)

    RequestSaveUserProfile (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSaveUserProfile"
      -- in
      ( { model | userMessage = Just "Some changes were not saved", userProfileFormSubmitted = Nothing }, Cmd.none )

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )

    OpenSaveToBookmarklistMenu inspectorState ->
      ( { model | inspectorState = Just { inspectorState | activeMenu = Just SaveToBookmarklistMenu } }, Cmd.none )

    AddToBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = oer :: p.oers } else p)}, Cmd.none )

    RemoveFromBookmarklist playlist oer ->
      ( { model | bookmarklists = model.bookmarklists |> List.map (\p -> if p.title==playlist.title then { p | oers = p.oers |> List.filter (\o -> o.url /= oer.url) } else p)}, Cmd.none )

    SetPopup popup ->
      ( { model | popup = Just popup }, Cmd.none)

    ClosePopup ->
      ( model |> closePopup, Cmd.none )

    CloseInspector ->
      ( { model | inspectorState = Nothing }, Cmd.none )

    ClickedOnDocument ->
      ( { model | searchSuggestions = [] }, Cmd.none )

    SelectSuggestion suggestion ->
      ( { model | selectedSuggestion = suggestion }, Cmd.none )

    MouseOverChunkTrigger mousePositionX ->
      ( { model | mousePositionXwhenOnChunkTrigger = mousePositionX }, Cmd.none )

    YoutubeSeekTo fragmentStart ->
      ( model, youtubeSeekTo fragmentStart)

    EditUserProfile field value ->
      let
          newForm =
            { userProfileForm | userProfile = userProfileForm.userProfile |> updateUserProfile field value, saved = False }
      in
          ( { model | userProfileForm = newForm }, Cmd.none )

    ClickedSaveUserProfile ->
      ( { model | userProfileFormSubmitted = Just userProfileForm } , requestSaveUserProfile model.userProfileForm.userProfile)


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


requestEntityDescriptionsIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
requestEntityDescriptionsIfNeeded (oldModel, oldCmd) =
  if oldModel.requestingEntityDescriptions then
    (oldModel, oldCmd)
  else
     let
         newModel =
           { oldModel | requestingEntityDescriptions = True }

         missingEntities =
           oldModel.entityDescriptions
           |> Dict.filter (\id description -> id/="" && description=="")
           |> Dict.keys
           |> List.take 50 -- 50 is the current limit according to https://www.wikidata.org/w/api.php?action=help&modules=wbgetentities
     in
         if List.isEmpty missingEntities then
           (oldModel, oldCmd)
         else
           (newModel, [ oldCmd, requestEntityDescriptions missingEntities ] |> Cmd.batch)


includeEntityIds : List Oer -> Model -> Model
includeEntityIds incomingOers model =
  let
      tagClouds =
        incomingOers
        |> List.foldl (\oer result -> if model.tagClouds |> Dict.member oer.url then result else (result |> Dict.insert oer.url (tagCloudFromOer oer))) model.tagClouds

      entityDescriptions =
        incomingOers
        |> List.concatMap .wikichunks
        |> List.concatMap .entities
        |> List.map .id
        |> List.foldl (\id result -> if model.entityDescriptions |> Dict.member id then result else (result |> Dict.insert id "")) model.entityDescriptions
  in
      { model | tagClouds = tagClouds, entityDescriptions = entityDescriptions }


tagCloudFromOer : Oer -> List String
tagCloudFromOer oer =
  let
      uniqueTitles : List String
      uniqueTitles =
        oer.wikichunks
        |> List.concatMap .entities
        |> List.map .title
        |> Set.fromList
        |> Set.toList

      titleRankings : List { title : String, rank : Int }
      titleRankings =
        uniqueTitles
        |> List.map (\title -> { title = title, rank = rankingForTitle title })


      rankingForTitle : String -> Int
      rankingForTitle title =
        oer.wikichunks
        |> List.concatMap .entities
        |> List.map .title
        |> List.filter ((==) title)
        |> List.length
  in
      titleRankings
      |> List.sortBy .rank
      |> List.map .title
      |> List.reverse
      |> List.take 5


closePopup : Model -> Model
closePopup model =
  { model | popup = Nothing }


resetUserProfileForm : Model -> Model
resetUserProfileForm model =
  case loggedInUser model of
    Just userProfile ->
      { model | userProfileForm = freshUserProfileForm userProfile }

    _ ->
      model


updateUserProfile : UserProfileField -> String -> UserProfile -> UserProfile
updateUserProfile field value userProfile =
  case field of
    FirstName ->
      { userProfile | firstName = value }

    LastName ->
      { userProfile | lastName = value }
