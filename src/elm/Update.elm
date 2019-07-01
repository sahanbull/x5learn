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
import Update.BubblePopup exposing (..)
import Update.Bubblogram exposing (..)
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
            |> logEventForLabStudy "LinkClickedInternal" [ url.path ]
          else
            ( model |> closePopup, Navigation.pushUrl model.nav.key (Url.toString url) )
            |> logEventForLabStudy "LinkClickedInternal" [ url.path ]

        Browser.External href ->
          ( model |> closePopup, Navigation.load href )
          |> logEventForLabStudy "LinkClickedExternal" [ href ]

    UrlChanged ({path} as url) ->
      let
          -- dummy =
          --   path |> Debug.log "UrlChanged"

          cmd =
            case model.session of
              Nothing ->
                Cmd.none

              Just session ->
                requestOersAsNeeded session.userState newModel

          subpage =
            if path |> String.startsWith profilePath then
              Profile
            else if path |> String.startsWith notesPath then
              Notes
            else if path |> String.startsWith recentPath then
              Recent
            else if path |> String.startsWith searchPath then
              Search
            else
              Home

          newModel =
            { model | nav = { nav | url = url }, inspectorState = Nothing, timeOfLastUrlChange = model.currentTime, subpage = subpage } |> closePopup |> resetUserProfileForm
      in
          ( newModel, cmd )
          |> logEventForLabStudy "UrlChanged" [ path ]

    ClockTick time ->
      ( { model | currentTime = time, enrichmentsAnimating = anyBubblogramsAnimating model }, Cmd.none)
      |> requestWikichunkEnrichmentsIfNeeded
      |> requestEntityDefinitionsIfNeeded

    AnimationTick time ->
      ( { model | currentTime = time } |> incrementFrameCountInModalAnimation, Cmd.none )

    ChangeSearchText str ->
      ( { model | searchInputTyping = str } |> closePopup, if String.length str > 1 then requestSearchSuggestions str else Cmd.none)
      |> logEventForLabStudy "ChangeSearchText" [ str ]

    TriggerSearch str ->
      if str=="" then
        ( model, setBrowserFocus "SearchField")
      else
        ( { model | searchInputTyping = str, searchState = Just <| newSearch str, searchSuggestions = [], timeOfLastSearch = model.currentTime, userMessage = Nothing } |> closePopup, searchOers str)
        |> logEventForLabStudy "TriggerSearch" [ str ]

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
      |> logEventForLabStudy "InspectOer" [ oer.url ]

    UninspectSearchResult ->
      ( { model | inspectorState = Nothing}, Cmd.none)
      |> logEventForLabStudy "UninspectSearchResult" []

    ModalAnimationStart animation ->
      ( { model | modalAnimation = Just animation }, Cmd.none )

    ModalAnimationStop dummy ->
      ( { model | modalAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove modalId }, Cmd.none )

    RequestSession (Ok session) ->
      ( { model | session = Just session } |> resetUserProfileForm, requestOersAsNeeded session.userState model)
      |> logEventForLabStudy "RequestSession" []

    RequestSession (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSession"
      -- in
      ( { model | userMessage = Just "There was a problem while requesting user data. Please try again later." }, Cmd.none )

    RequestOerSearch (Ok oers) ->
      ( model |> updateSearch (insertSearchResults (oers |> List.map .url)) |> cacheOersFromList oers, [ Navigation.pushUrl nav.key "/search", setBrowserFocus "SearchField" ] |> Cmd.batch )
      |> requestWikichunkEnrichmentsIfNeeded
      |> logEventForLabStudy "RequestOerSearch" (oers |> List.map .url)

    RequestOerSearch (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOerSearch"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the search data" }, Cmd.none )

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

    RequestWikichunkEnrichments (Ok enrichments) ->
      let
          failCount =
            if Dict.isEmpty enrichments then
              model.wikichunkEnrichmentRequestFailCount + 1
            else
              0

          retryTime =
            (posixToMillis model.currentTime) + (failCount*2000 |> min 10000) |> millisToPosix
      in
          ( { model | wikichunkEnrichments = model.wikichunkEnrichments |> Dict.union enrichments, requestingWikichunkEnrichments = False, enrichmentsAnimating = True, wikichunkEnrichmentRequestFailCount = failCount, wikichunkEnrichmentRetryTime = retryTime } |> registerUndefinedEntities (Dict.values enrichments), Cmd.none )

    RequestWikichunkEnrichments (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestWikichunkEnrichments"
      -- in
      ( { model | userMessage = Just "There was a problem. Please reload the page.", requestingWikichunkEnrichments = False }, Cmd.none )

    RequestEntityDefinitions (Ok definitionTexts) ->
      let
          entityDefinitions =
            model.entityDefinitions |> Dict.union (definitionTexts |> Dict.map (\_ text -> DefinitionLoaded text))
      in
          ( { model | entityDefinitions = entityDefinitions, requestingEntityDefinitions = False } |> updateBubblogramsIfNeeded, Cmd.none )
          |> requestEntityDefinitionsIfNeeded

    RequestEntityDefinitions (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestEntityDefinitions"
      -- in
      ( { model | userMessage = Just "There was a problem while fetching the wiki definitions data", requestingEntityDefinitions = False }, Cmd.none )

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

    RequestLabStudyLogEvent (Ok _) ->
      (model, Cmd.none)

    RequestLabStudyLogEvent (Err err) ->
      let
          dummy =
            err |> Debug.log "Error in RequestLabStudyLogEvent"
      in
      -- ( { model | userMessage = Just "Some changes were not saved" }, Cmd.none )
      (model, Cmd.none)

    SetHover maybeUrl ->
      ( { model | hoveringOerUrl = maybeUrl, timeOfLastMouseEnterOnCard = model.currentTime }, Cmd.none )
      |> logEventForLabStudy "SetHover" [ maybeUrl |> Maybe.withDefault "" ]

    SetPopup popup ->
      let
          newModel =
            { model | popup = Just popup }
      in
          (newModel, Cmd.none)
          |> logEventForLabStudy "SetPopup" (popupToStrings newModel.popup)

    ClosePopup ->
      ( model |> closePopup, Cmd.none )
      |> logEventForLabStudy "ClosePopup" []

    CloseInspector ->
      ( { model | inspectorState = Nothing }, Cmd.none )
      |> logEventForLabStudy "CloseInspector" []

    ClickedOnDocument ->
      ( { model | searchSuggestions = [] }, Cmd.none )

    SelectSuggestion suggestion ->
      ( { model | selectedSuggestion = suggestion }, Cmd.none )
      |> logEventForLabStudy "SelectSuggestion" [ suggestion ]

    MouseOverChunkTrigger mousePositionX ->
      ( { model | mousePositionXwhenOnChunkTrigger = mousePositionX }, Cmd.none )
      |> logEventForLabStudy "MouseOverChunkTrigger" [ mousePositionX |> String.fromFloat ]

    YoutubeSeekTo fragmentStart ->
      ( model, youtubeSeekTo fragmentStart)
      |> logEventForLabStudy "YoutubeSeekTo" [ fragmentStart |> String.fromFloat ]

    EditUserProfile field value ->
      let
          newForm =
            { userProfileForm | userProfile = userProfileForm.userProfile |> updateUserProfileField field value, saved = False }
      in
          ( { model | userProfileForm = newForm }, Cmd.none )
          |> logEventForLabStudy "EditUserProfile" []

    SubmittedUserProfile ->
      ( { model | userProfileFormSubmitted = Just userProfileForm }, requestSaveUserProfile model.userProfileForm.userProfile)
      |> logEventForLabStudy "SubmittedUserProfile" []

    ChangedTextInNewNoteFormInOerNoteboard oerUrl str ->
      ( model |> setTextInNoteForm oerUrl str, Cmd.none)

    SubmittedNewNoteInOerNoteboard oerUrl ->
      (model |> updateUserState (addNoteToOer oerUrl (getOerNoteForm model oerUrl) model) |> setTextInNoteForm oerUrl "", Cmd.none)
      |> saveUserState msg
      |> logEventForLabStudy "SubmittedNewNoteInOerNoteboard" [ oerUrl, getOerNoteForm model oerUrl ]

    PressedKeyInNewNoteFormInOerNoteboard oerUrl keyCode ->
      if keyCode==13 then
        model |> update (SubmittedNewNoteInOerNoteboard oerUrl)
      else
        (model, Cmd.none)

    ClickedQuickNoteButton oerUrl text ->
      (model |> updateUserState (addNoteToOer oerUrl text model) |> setTextInNoteForm oerUrl "" , Cmd.none)
      |> saveUserState msg
      |> logEventForLabStudy "ClickedQuickNoteButtond" [ oerUrl, text ]

    RemoveNote time ->
      (model |> updateUserState (removeNoteAtTime time), Cmd.none)
      |> saveUserState msg
      |> logEventForLabStudy "RemoveNote" [ time |> posixToMillis |> String.fromInt ]

    VideoIsPlayingAtPosition position ->
      (model |> updateUserState (expandCurrentFragmentOrCreateNewOne position model.inspectorState), Cmd.none)
      |> saveUserState msg
      |> logEventForLabStudy "VideoIsPlayingAtPosition" [ position |> String.fromFloat]

    SubmitPostRegistrationForm keepData ->
      (model |> updateUserState completeRegistration, Cmd.none)
      |> saveUserState msg

    BubbleMouseOver entityId ->
      let
          oerUrl =
            model.hoveringOerUrl
            |> Maybe.withDefault ""
      in
          ({model | hoveringBubbleEntityId = Just entityId }, Cmd.none)
          |> logEventForLabStudy "BubbleMouseOver" [ oerUrl, entityId ]

    BubbleMouseOut ->
      ({model | hoveringBubbleEntityId = Nothing } |> closePopup, Cmd.none)
      |> logEventForLabStudy "BubbleMouseOut" []

    BubbleClicked oerUrl ->
      let
          newModel =
            {model | popup = model.popup |> updateBubblePopupOnClick model oerUrl }
      in
          (newModel, Cmd.none)
          |> logEventForLabStudy "BubbleClicked" (popupToStrings newModel.popup)


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


insertSearchResults oerUrls searchState =
  { searchState | searchResults = Just oerUrls }


incrementFrameCountInModalAnimation : Model -> Model
incrementFrameCountInModalAnimation model =
  case model.modalAnimation of
    Nothing ->
      model

    Just animation ->
      { model | modalAnimation = Just { animation | frameCount = animation.frameCount + 1 } }


requestWikichunkEnrichmentsIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
requestWikichunkEnrichmentsIfNeeded (model, oldCmd) =
  if model.requestingWikichunkEnrichments || (model.wikichunkEnrichmentRequestFailCount>0 && (model.currentTime |> posixToMillis) < (model.wikichunkEnrichmentRetryTime |> posixToMillis)) then
    (model, oldCmd)
  else
    let
        missing =
          model.cachedOers
          |> Dict.keys
          |> List.filter (\url -> Dict.member url model.wikichunkEnrichments |> not)
    in
        if List.isEmpty missing then
          (model, oldCmd)
        else
          (model, [ oldCmd, requestWikichunkEnrichments missing ] |> Cmd.batch)


requestOersAsNeeded : UserState -> Model -> Cmd Msg
requestOersAsNeeded userState model =
  let
      neededUrls =
        case model.subpage of
          Notes ->
            userState.oerNoteboards |> Dict.keys

          Recent ->
            userState.fragmentAccesses |> Dict.values |> List.map .oerUrl

          _ ->
            []

      missingUrls =
        neededUrls
        |> Set.fromList
        |> Set.filter (\url -> not <| List.member url (model.cachedOers |> Dict.keys))
  in
      missingUrls
      |> requestOers


requestEntityDefinitionsIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
requestEntityDefinitionsIfNeeded (oldModel, oldCmd) =
  if oldModel.requestingEntityDefinitions then
    (oldModel, oldCmd)
  else
     let
         newModel =
           { oldModel | requestingEntityDefinitions = True }

         missingEntities =
           oldModel.entityDefinitions
           |> Dict.filter (\_ definition -> definition==DefinitionScheduledForLoading)
           |> Dict.keys
           |> List.take 50 -- arbitrary pagination
     in
         if List.isEmpty missingEntities then
           (oldModel, oldCmd)
         else
           (newModel, [ oldCmd, requestEntityDefinitions missingEntities ] |> Cmd.batch)


registerUndefinedEntities : List WikichunkEnrichment -> Model -> Model
registerUndefinedEntities enrichments model =
  let
      entityDefinitions =
        enrichments
        |> uniqueEntitiesFromEnrichments
        |> List.map .id
        |> List.foldl (\entityId output -> if model.entityDefinitions |> Dict.member entityId then output else (output |> Dict.insert entityId DefinitionScheduledForLoading)) model.entityDefinitions
  in
      { model | entityDefinitions = entityDefinitions }


closePopup : Model -> Model
closePopup model =
  { model | popup = Nothing, hoveringBubbleEntityId = Nothing }


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
        |> List.foldl (\oer output -> output |> Dict.insert oer.url oer) Dict.empty
  in
      { model | cachedOers = Dict.union oersDict model.cachedOers }


addFragmentAccess : Fragment -> Posix -> UserState -> UserState
addFragmentAccess fragment currentTime userState =
  if List.member fragment (Dict.values userState.fragmentAccesses) then
    userState
  else
      let
          maxNumberOfItemsToKeep =
            10 -- arbitrary value. I'm keeping this fairly small to avoid long loading times. At the time of writing, I figure that we could speed things up by removing redundant entity titles and urls from the chunk data. See issue #115

          fragmentAccesses =
            userState.fragmentAccesses
            |> Dict.toList
            |> List.drop ((Dict.size userState.fragmentAccesses) - maxNumberOfItemsToKeep)
            |> Dict.fromList
            |> Dict.insert (posixToMillis currentTime) fragment
      in
          { userState | fragmentAccesses = fragmentAccesses }


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


updateBubblogramsIfNeeded : Model -> Model
updateBubblogramsIfNeeded model =
  if model.entityDefinitions |> Dict.values |> List.any (\definition -> definition == DefinitionScheduledForLoading) then
    model
  else
    { model | wikichunkEnrichments = model.wikichunkEnrichments |> Dict.map (addBubblogram model) }


logEventForLabStudy eventType params (model, cmd) =
  if isLabStudy1 model then
    let
        time =
          model.currentTime |> posixToMillis
    in
        (model, [ cmd, requestLabStudyLogEvent time eventType params ] |> Cmd.batch)
  else
    (model, cmd)


popupToStrings : Maybe Popup -> List String
popupToStrings maybePopup =
  case maybePopup of
    Nothing ->
      []

    Just popup ->
      case popup of
        ChunkOnBar {barId, oer, chunk, entityPopup} ->
          let
              entityIdStr =
                case entityPopup of
                  Nothing ->
                    ""

                  Just {entityId} ->
                    entityId
          in
              [ "ChunkOnBar", barId, oer.url, chunk.entities |> List.map .id |> String.join ",", entityIdStr ]

        UserMenu ->
          [ "UserMenu" ]

        BubblePopup {oerUrl, entityId, content} ->
          let
              contentString =
                case content of
                  DefinitionInBubblePopup ->
                    "Definition"

                  MentionInBubblePopup {positionInResource, sentence} ->
                    "Mention " ++ (positionInResource |> String.fromFloat) ++ " " ++ sentence
          in
              [ oerUrl, entityId, contentString ]
