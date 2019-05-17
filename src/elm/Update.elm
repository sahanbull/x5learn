module Update exposing (update)

import Browser
import Browser.Navigation as Navigation
import Url
import Url.Builder
import Json.Decode as Decode
import Json.Encode as Encode
import Dict exposing (Dict)
import Set
import Time exposing (Posix, millisToPosix, posixToMillis)
import List.Extra

-- import Debug exposing (log)

import Model exposing (..)
import Msg exposing (..)
import Ports exposing (..)
import Request exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({nav, userProfileForm} as model) =
  -- let
  --     actionlog =
  --       msg |> log "action"
  -- in
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
          -- logOutput =
          --   url.path |> log "UrlChanged"

          (newModel, cmd) =
            (model, Cmd.none)
            -- if url.path == "/next_steps" then
            --   (model, requestNextSteps)
            -- -- else if url.path == "/gains" then
            -- --   (model, requestGains)
            -- else
            --   (model, Cmd.none)
      in
          ( { newModel | nav = { nav | url = url }, inspectorState = Nothing } |> closePopup |> resetUserProfileForm, cmd )

    ClockTick time ->
      ( { model | currentTime = time }, Cmd.none)
      |> requestEntityDescriptionsIfNeeded

    AnimationTick time ->
      ( { model | currentTime = time } |> incrementFrameCountInModalAnimation, Cmd.none )

    ChangeSearchText str ->
      ( { model | searchInputTyping = str } |> closePopup, if String.length str > 1 then requestSearchSuggestions str else Cmd.none)

    TriggerSearch str ->
      if str=="" then
        ( model, setBrowserFocus "SearchField")
      else
        ( { model | searchInputTyping = str, searchState = Just <| newSearch str, searchSuggestions = [], timeOfLastSearch = model.currentTime } |> closePopup, searchOers str)

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y } |> closePopup, Cmd.none )

    InspectOer oer fragmentStart fragmentLength playWhenReady ->
      let
          inspectorParams =
            { modalId = modalId
            , videoId = getYoutubeVideoId oer.url |> Maybe.withDefault ""
            , fragmentStart = fragmentStart
            , playWhenReady = playWhenReady
            }
      in
          ( { model | inspectorState = Just <| newInspectorState oer fragmentStart, animationsPending = model.animationsPending |> Set.insert modalId } |> closePopup |> (updateUserState <| addFragmentAccess (Fragment oer.url fragmentStart fragmentLength) model.currentTime), openModalAnimation inspectorParams)
      |> saveUserState msg

    UninspectSearchResult ->
      ( { model | inspectorState = Nothing}, Cmd.none)

    ModalAnimationStart animation ->
      ( { model | modalAnimation = Just animation }, Cmd.none )

    ModalAnimationStop dummy ->
      ( { model | modalAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove modalId }, Cmd.none )

    RequestSession (Ok session) ->
      ( { model | session = Just session } |> resetUserProfileForm, requestOersAsNeeded session.userState model)

    RequestSession (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSession"
      -- in
      ( { model | userMessage = Just "There was a problem while requesting user data. Please try again later." }, Cmd.none )

    RequestOerSearch (Ok oers) ->
      ( model |> updateSearch (insertSearchResults oers) |> includeEntityIds oers |> cacheOersFromList oers, [ Navigation.pushUrl nav.key "/search", setBrowserFocus "SearchField" ] |> Cmd.batch )
      |> requestEntityDescriptionsIfNeeded

    RequestOerSearch (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOerSearch"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the search data" }, Cmd.none )

    -- RequestNextSteps (Ok pathways) ->
    --   let
    --       oers =
    --         pathways
    --         |> List.concatMap .fragments
    --         |> List.map .oerUrl
    --   in
    --       ( { model | nextSteps = Just pathways } |> includeEntityIds oers, Cmd.none)
    --       |> requestEntityDescriptionsIfNeeded

    -- RequestNextSteps (Err err) ->
    --   let
    --       dummy =
    --         err |> Debug.log "Error in RequestNextSteps"
    --   in
    --   ( { model | userMessage = Just "There was a problem while fetching the recommendations data" }, Cmd.none )

    RequestOers (Ok oers) ->
      ( { model | requestingOers = False } |> cacheOersFromDict oers, Cmd.none)

    RequestOers (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOers"
      -- in
      ( { model | requestingOers = False, userMessage = Just "There was a problem while fetching OER data" }, Cmd.none)

    RequestGains (Ok gains) ->
      ( { model | gains = Just gains }, Cmd.none )

    RequestGains (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestGains"
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

    RequestSaveUserState (Ok _) ->
      (model, Cmd.none)

    RequestSaveUserState (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSaveUserState"
      -- in
      ( { model | userMessage = Just "Some changes were not saved" }, Cmd.none )

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )

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
            { userProfileForm | userProfile = userProfileForm.userProfile |> updateUserProfileField field value, saved = False }
      in
          ( { model | userProfileForm = newForm }, Cmd.none )

    SubmittedUserProfile ->
      ( { model | userProfileFormSubmitted = Just userProfileForm }, requestSaveUserProfile model.userProfileForm.userProfile)

    ChangedTextInNewNoteFormInOerNoteboard oerUrl str ->
      ( model |> setTextInNoteForm oerUrl str, Cmd.none)

    SubmittedNewNoteInOerNoteboard oerUrl ->
      -- let
      --     dummy =
      --       oerUrl |> log "SubmittedNewNoteInOerNoteboard"
      -- in
      (model |> updateUserState (addNoteToOer oerUrl (getOerNoteForm model oerUrl) model) |> setTextInNoteForm oerUrl "", Cmd.none)
      |> saveUserState msg

    PressedKeyInNewNoteFormInOerNoteboard oerUrl keyCode ->
      if keyCode==13 then
        model |> update (SubmittedNewNoteInOerNoteboard oerUrl)
      else
        (model, Cmd.none)

    ClickedQuickNoteButton oerUrl text ->
      (model |> updateUserState (addNoteToOer oerUrl text model) |> setTextInNoteForm oerUrl "" , Cmd.none)
      |> saveUserState msg

    RemoveNote time ->
      (model |> updateUserState (removeNoteAtTime time), Cmd.none)
      |> saveUserState msg

    VideoIsPlayingAtPosition position ->
      (model |> updateUserState (expandCurrentFragmentOrCreateNewOne position model.inspectorState), Cmd.none)
      |> saveUserState msg

    SubmitPostRegistrationForm keepData ->
      (model |> updateUserState completeRegistration, Cmd.none)
      |> saveUserState msg


updateUserState : (UserState -> UserState) -> Model -> Model
updateUserState fn model =
  case model.session of
    Nothing ->
      model

    Just session ->
      { model | session = Just { session | userState = session.userState |> fn } }


addNoteToOer : String -> String -> Model -> UserState -> UserState
addNoteToOer oerUrl text {currentTime} userState =
  let
      newNote =
        Note text currentTime

      oldNoteboard =
        getOerNoteboard userState oerUrl

      newNoteboard =
        newNote :: oldNoteboard
  in
      { userState | oerNoteboards = userState.oerNoteboards |> Dict.insert oerUrl newNoteboard }


removeNoteAtTime : Posix -> UserState -> UserState
removeNoteAtTime time userState =
  let
      filter : OerUrl -> Noteboard -> Noteboard
      filter _ notes =
        notes
        |> List.filter (\note -> note.time /= time)
  in
     { userState | oerNoteboards = userState.oerNoteboards |> Dict.map filter }


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


requestOersAsNeeded : UserState -> Model -> Cmd Msg
requestOersAsNeeded userState model =
  let
      neededUrls =
        [ userState.oerNoteboards |> Dict.keys
        , userState.fragmentAccesses |> Dict.values |> List.map .oerUrl
        ]
        |> List.concat

      missingUrls =
        neededUrls
        |> Set.fromList
        |> Set.filter (\url -> not <| List.member url (model.cachedOers |> Dict.keys))
  in
      missingUrls
      |> requestOers


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
  case loggedInUserProfile model of
    Just userProfile ->
      { model | userProfileForm = freshUserProfileForm userProfile }

    _ ->
      model


updateUserProfileField : UserProfileField -> String -> UserProfile -> UserProfile
updateUserProfileField field value userProfile =
  case field of
    FirstName ->
      { userProfile | firstName = value }

    LastName ->
      { userProfile | lastName = value }


saveUserState lastAction (model, cmd) =
  case model.session of
    Nothing ->
      (model, cmd)

    Just session ->
      (model, [ cmd, requestSaveUserState session.userState ] |> Cmd.batch)


cacheOersFromDict : Dict OerUrl Oer -> Model -> Model
cacheOersFromDict oers model =
  { model | cachedOers = Dict.union oers model.cachedOers }


cacheOersFromList : List Oer -> Model -> Model
cacheOersFromList oers model =
  let
      oersDict =
        oers
        |> List.foldl (\oer result -> result |> Dict.insert oer.url oer) Dict.empty
  in
      { model | cachedOers = Dict.union oersDict model.cachedOers }


addFragmentAccess : Fragment -> Posix -> UserState -> UserState
addFragmentAccess fragment currentTime userState =
  { userState | fragmentAccesses = userState.fragmentAccesses |> Dict.insert (posixToMillis currentTime) fragment }


setTextInNoteForm : OerUrl -> String -> Model -> Model
setTextInNoteForm oerUrl str model =
  { model | oerNoteForms = model.oerNoteForms |> Dict.insert oerUrl str }


expandCurrentFragmentOrCreateNewOne : Float -> Maybe InspectorState -> UserState -> UserState
expandCurrentFragmentOrCreateNewOne position inspectorState userState =
  case inspectorState of
    Nothing ->
      userState

    Just {oer} ->
      case mostRecentFragmentAccess userState.fragmentAccesses of
        Nothing ->
          userState

        Just (time, fragment) ->
          let
              fragmentEnd =
                fragment.start + fragment.length

              newFragmentAccesses =
                if position >= fragmentEnd && position < fragmentEnd + 0.05 then
                  -- The video appears to be playing normally.
                  -- -> Extend the current fragment to the current play position.
                  userState.fragmentAccesses
                  |> Dict.insert time { fragment | length = position - fragment.start }
                else
                  -- The user appears to have skipped within the video, using the player's controls (rather than the fragmentsBar)
                  -- -> Create a new fragment, starting with the current position
                  userState.fragmentAccesses
                  |> Dict.insert time (Fragment oer.url position 0)
          in
              { userState | fragmentAccesses = newFragmentAccesses }


completeRegistration : UserState -> UserState
completeRegistration userState =
  { userState | registrationComplete = True }
