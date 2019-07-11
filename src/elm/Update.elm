module Update exposing (update)

import Browser
import Browser.Navigation as Navigation
import Url exposing (Url)
import Url.Builder
-- import Url.Parser
-- import Url.Parser.Query
import Json.Decode as Decode
import Json.Encode as Encode
import Dict exposing (Dict)
import Set
import Time exposing (Posix, millisToPosix, posixToMillis)
import List.Extra

import Model exposing (..)
import Update.BubblePopup exposing (..)
import Update.Bubblogram exposing (..)
import Msg exposing (..)
import Ports exposing (..)
import Request exposing (..)
import ActionApi exposing (..)
import NotesApi exposing (..)


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
          (subpage, (newModel, cmd)) =
            if path |> String.startsWith profilePath then
              (Profile, (model, Cmd.none))
            else if path |> String.startsWith notesPath then
              (Notes, (model, Cmd.none))
            else if path |> String.startsWith recentPath then
              (Recent, (model, ActionApi.requestRecentViews))
            else if path |> String.startsWith searchPath then
              (Search, executeSearchAfterUrlChanged model url)
            else if path |> String.startsWith resourcePath then
              (Resource, model |> requestResourceAfterUrlChanged url)
            else
              (Home, (model, Cmd.none))
      in
          ({ newModel | nav = { nav | url = url }, inspectorState = Nothing, timeOfLastUrlChange = model.currentTime, subpage = subpage } |> closePopup |> resetUserProfileForm, cmd)
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
      let
          searchUrl =
            Url.Builder.relative [ searchPath ] [ Url.Builder.string "q" str ]
      in
          (model, Navigation.pushUrl nav.key searchUrl)

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y } |> closePopup, Cmd.none )

    InspectOer oer fragmentStart fragmentLength playWhenReady ->
      let
          youtubeEmbedParams : YoutubeEmbedParams
          youtubeEmbedParams =
            { modalId = modalId
            , videoId = getYoutubeVideoId oer.url |> Maybe.withDefault ""
            , fragmentStart = fragmentStart
            , playWhenReady = playWhenReady
            }
      in
          ( { model | inspectorState = Just <| newInspectorState oer fragmentStart, animationsPending = model.animationsPending |> Set.insert modalId } |> closePopup |> addFragmentAccess (Fragment oer.url fragmentStart fragmentLength) model.currentTime, openModalAnimation youtubeEmbedParams)
      |> saveAction 1 [ ("oerId", Encode.int oer.id), ("oerUrl", Encode.string oer.url) ]
      |> logEventForLabStudy "InspectOer" [ oer.url ]

    UninspectSearchResult ->
      ( { model | inspectorState = Nothing}, Cmd.none)
      |> logEventForLabStudy "UninspectSearchResult" []

    ModalAnimationStart animation ->
      ( { model | modalAnimation = Just animation }, Cmd.none )

    ModalAnimationStop dummy ->
      ( { model | modalAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove modalId }, Cmd.none )

    RequestSession (Ok session) ->
      ( { model | session = Just session } |> resetUserProfileForm, requestOersAsNeeded model)
      |> logEventForLabStudy "RequestSession" []

    RequestSession (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSession"
      -- in
      ( { model | userMessage = Just "An error occurred. Please reload the page." }, Cmd.none )

    RequestRecentViews (Ok oerUrls) ->
      let
          newModel =
            oerUrls
            |> List.indexedMap (\index oerUrl -> (100000-index, oerUrl)) -- lazy trick to avoid having to decode the date from the JSON (which we don't really need at this point)
            |> List.foldl (\(index, oerUrl) resultingModel -> resultingModel |> addFragmentAccess (Fragment oerUrl 0 0.01) (millisToPosix index)) model
      in
          ( newModel, requestOersAsNeeded newModel)
          |> logEventForLabStudy "RequestRecentViews" []

    RequestRecentViews (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestRecentViews"
      -- in
      ( { model | userMessage = Just "An error occurred. Please reload the page." }, Cmd.none )

    RequestOerSearch (Ok oers) ->
      ( model |> updateSearch (insertSearchResults (oers |> List.map .url)) |> cacheOersFromList oers, setBrowserFocus "SearchField")
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

    RequestLabStudyLogEvent (Ok _) ->
      (model, Cmd.none)

    RequestLabStudyLogEvent (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestLabStudyLogEvent"
      -- in
      ( { model | userMessage = Just "Some logs were not saved" }, Cmd.none )

    RequestSendResourceFeedback (Ok _) ->
      (model, Cmd.none)

    RequestSendResourceFeedback (Err err) ->
      (model, Cmd.none)

    RequestSaveAction (Ok _) ->
      (model, Cmd.none)

    RequestSaveAction (Err err) ->
      ( { model | userMessage = Just "Some changes were not saved" }, Cmd.none )

    RequestSaveNote (Ok _) ->
      (model, Cmd.none)

    RequestSaveNote (Err err) ->
      ( { model | userMessage = Just "Some changes were not saved" }, Cmd.none )

    RequestResource (Ok oer) ->
      let
          cmdYoutube =
            case getYoutubeVideoId oer.url of
              Nothing ->
                youtubeDestroyPlayer True

              Just videoId ->
                let
                    youtubeEmbedParams : YoutubeEmbedParams
                    youtubeEmbedParams =
                      { modalId = ""
                      , videoId = videoId
                      , fragmentStart = 0
                      , playWhenReady = False
                      }
                in
                    embedYoutubePlayerOnResourcePage youtubeEmbedParams

          newModel =
            { model | currentResource = Just <| Loaded oer.url } |> cacheOersFromList [ oer ]
      in
          (newModel, [ cmdYoutube, requestResourceRecommendations <| relatedSearchStringFromOer newModel oer.url ] |> Cmd.batch )

    RequestResource (Err err) ->
      ( { model | currentResource = Just Error }, Cmd.none )

    RequestResourceRecommendations (Ok oersUnfiltered) ->
      let
          oers =
            oersUnfiltered |> List.filter (\oer -> model.currentResource /= Just (Loaded oer.url)) -- ensure that the resource itself isn't included in the recommendations
      in
          ({ model | resourceRecommendations = oers } |> cacheOersFromList oers, setBrowserFocus "")
          |> requestWikichunkEnrichmentsIfNeeded
          |> logEventForLabStudy "RequestResourceRecommendations" (oers |> List.map .url)

    RequestResourceRecommendations (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestResourceRecommendations"
      -- in
      ( { model | resourceRecommendations = [], userMessage = Just "An error occurred while loading recommendations" }, Cmd.none )

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

    ChangedTextInResourceFeedbackForm oerId str ->
      ( model |> setTextInResourceFeedbackForm oerId str, Cmd.none)

    SubmittedNewNoteInOerNoteboard oerUrl ->
      let
          text =
            getOerNoteForm model oerUrl

          oerId =
            getOerIdFromOerUrl model oerUrl
      in
      (model |> addNoteToOer oerUrl text |> setTextInNoteForm oerUrl "", [ setBrowserFocus "textInputFieldForNotesOrFeedback", saveNote oerId text ] |> Cmd.batch)
      |> logEventForLabStudy "SubmittedNewNoteInOerNoteboard" [ oerUrl, getOerNoteForm model oerUrl ]

    SubmittedResourceFeedback oerId text ->
      ({ model | timeOfLastFeedbackRecorded = model.currentTime } |> setTextInResourceFeedbackForm oerId "", requestSendResourceFeedback oerId text)
      |> logEventForLabStudy "SubmittedResourceFeedback" [ oerId |> String.fromInt, getResourceFeedbackFormValue model oerId ]

    PressedKeyInNewNoteFormInOerNoteboard oerUrl keyCode ->
      if keyCode==13 then
        model |> update (SubmittedNewNoteInOerNoteboard oerUrl)
      else
        (model, Cmd.none)

    ClickedQuickNoteButton oerUrl text ->
      let
          oerId =
            getOerIdFromOerUrl model oerUrl
      in
      (model |> addNoteToOer oerUrl text |> setTextInNoteForm oerUrl "" , saveNote oerId text)
      |> logEventForLabStudy "ClickedQuickNoteButtond" [ oerUrl, text ]

    RemoveNote time ->
      (model |> removeNoteAtTime time, Cmd.none)
      |> logEventForLabStudy "RemoveNote" [ time |> posixToMillis |> String.fromInt ]

    VideoIsPlayingAtPosition position ->
      (model |> expandCurrentFragmentOrCreateNewOne position model.inspectorState, Cmd.none)
      |> logEventForLabStudy "VideoIsPlayingAtPosition" [ position |> String.fromFloat]

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

    PageScrolled {scrollTop, viewHeight, contentHeight} ->
      (model, Cmd.none)
      |> logEventForLabStudy "PageScrolled" [ scrollTop |> String.fromFloat, viewHeight |> String.fromFloat, contentHeight |> String.fromFloat ]

    StartLabStudyTask task ->
      { model | startedLabStudyTask = Just (task, model.currentTime) }
      |> update (TriggerSearch task.dataset)
      |> logEventForLabStudy "StartLabStudyTask" [ task.title, task.durationInMinutes |> String.fromInt ]

    StoppedLabStudyTask ->
      ({ model | startedLabStudyTask = Nothing }, setBrowserFocus "")
      |> logEventForLabStudy "StoppedLabStudyTask" []

    SelectResourceSidebarTab tab ->
      ({ model | resourceSidebarTab = tab }, setBrowserFocus "textInputFieldForNotesOrFeedback")
      |> logEventForLabStudy "SelectResourceSidebarTab" []


addNoteToOer : OerUrl -> String -> Model -> Model
addNoteToOer oerUrl text model =
  let
      newNote =
        Note text model.currentTime

      oldNoteboard =
        getOerNoteboard model oerUrl

      newNoteboard =
        newNote :: oldNoteboard
  in
      { model | oerNoteboards = model.oerNoteboards |> Dict.insert oerUrl newNoteboard }


removeNoteAtTime : Posix -> Model -> Model
removeNoteAtTime time model =
  let
      filter : OerUrl -> Noteboard -> Noteboard
      filter _ notes =
        notes
        |> List.filter (\note -> note.time /= time)
  in
     { model | oerNoteboards = model.oerNoteboards |> Dict.map filter }


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


requestOersAsNeeded : Model -> Cmd Msg
requestOersAsNeeded model =
  let
      neededUrls =
        case model.subpage of
          Notes ->
            model.oerNoteboards |> Dict.keys

          Recent ->
            model.fragmentAccesses |> Dict.values |> List.map .oerUrl

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


addFragmentAccess : Fragment -> Posix -> Model -> Model
addFragmentAccess fragment time model =
  if List.member fragment (Dict.values model.fragmentAccesses) then
    model
  else
      let
          maxNumberOfItemsToKeep =
            30 -- arbitrary value. There used to be some performance implications associated with this number but I forgot what the issue was and I'm unsure whether it still applies. Should test empirically.

          fragmentAccesses =
            model.fragmentAccesses
            |> Dict.toList
            |> List.reverse
            |> List.take maxNumberOfItemsToKeep
            |> List.reverse
            |> Dict.fromList
            |> Dict.insert (posixToMillis time) fragment
      in
          { model | fragmentAccesses = fragmentAccesses }


setTextInNoteForm : OerUrl -> String -> Model -> Model
setTextInNoteForm oerUrl str model =
  { model | oerNoteForms = model.oerNoteForms |> Dict.insert oerUrl str }


setTextInResourceFeedbackForm : OerId -> String -> Model -> Model
setTextInResourceFeedbackForm oerId str model =
  { model | feedbackForms = model.feedbackForms |> Dict.insert oerId str }


expandCurrentFragmentOrCreateNewOne : Float -> Maybe InspectorState -> Model -> Model
expandCurrentFragmentOrCreateNewOne position inspectorState model =
  case inspectorState of
    Nothing ->
      model

    Just {oer} ->
      case mostRecentFragmentAccess model.fragmentAccesses of
        Nothing ->
          model

        Just (time, fragment) ->
          let
              fragmentEnd =
                fragment.start + fragment.length

              newFragmentAccesses =
                if position >= fragmentEnd && position < fragmentEnd + 0.05 then
                  -- The video appears to be playing normally.
                  -- -> Extend the current fragment to the current play position.
                  model.fragmentAccesses
                  |> Dict.insert time { fragment | length = position - fragment.start }
                else
                  -- The user appears to have skipped within the video, using the player's controls (rather than the fragmentsBar)
                  -- -> Create a new fragment, starting with the current position
                  model.fragmentAccesses
                  |> Dict.insert time (Fragment oer.url position 0)
          in
              { model | fragmentAccesses = newFragmentAccesses }


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


executeSearchAfterUrlChanged : Model -> Url -> (Model, Cmd Msg)
executeSearchAfterUrlChanged model url =
  let
      str =
        url.query
        |> Maybe.withDefault ""
        |> String.dropLeft 2 -- TODO A much cleaner method is to use Url.Query.parser
  in
      if str=="" then
        ( model, setBrowserFocus "SearchField")
      else
        ( { model | searchInputTyping = str, searchState = Just <| newSearch str, searchSuggestions = [], timeOfLastSearch = model.currentTime, userMessage = Nothing } |> closePopup, searchOers str)
        |> logEventForLabStudy "executeSearchAfterUrlChanged" [ str ]


requestResourceAfterUrlChanged : Url -> Model -> (Model, Cmd Msg)
requestResourceAfterUrlChanged url model =
  let
      resourceId =
        url.path
        |> String.dropLeft 10 -- TODO A much cleaner method is to use Url.Query.parser
        |> String.toInt
  in
      case resourceId of
        Nothing ->
          ({ model | currentResource = Just Error }, Cmd.none)

        Just oerId ->
          (model, requestResource oerId)



saveAction : Int -> List (String, Encode.Value) -> (Model, Cmd Msg)-> (Model, Cmd Msg)
saveAction actionTypeId params (model, oldCmd) =
  let
      cmd =
        ActionApi.saveAction actionTypeId params
  in
      (model, [ oldCmd, cmd ] |> Cmd.batch)
