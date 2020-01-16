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
-- import NotesApi exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({nav, userProfileForm} as model) =
  -- let
  --     actionlog =
  --       msg |> Debug.log "action"
  -- in
  case msg of
    Initialized url ->
      let
          (newModel, cmd) =
            model |> update (UrlChanged url)
      in
          (newModel, [ cmd, requestSession, requestLoadCourse, askPageScrollState True ] |> Cmd.batch )

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
            -- else if path |> String.startsWith notesPath then
            --   (Notes, ({ model | oerCardPlaceholderPositions = [] }, [ getOerCardPlaceholderPositions True, askPageScrollState True ] |> Cmd.batch))
            -- else if path |> String.startsWith favoritesPath then
            --   (Favorites, (model, askPageScrollState True))
            else if path |> String.startsWith searchPath then
              (Search, executeSearchAfterUrlChanged model url)
            else
              (Home, (model, (if model.featuredOers==Nothing then requestFeaturedOers else Cmd.none)))
      in
          ({ newModel | nav = { nav | url = url }, inspectorState = Nothing, timeOfLastUrlChange = model.currentTime, subpage = subpage } |> closePopup |> resetUserProfileForm, cmd)
          |> logEventForLabStudy "UrlChanged" [ path, url.query |> Maybe.withDefault "" ]

    ClockTick time ->
      ( { model | currentTime = time, enrichmentsAnimating = anyBubblogramsAnimating model, snackbar = updateSnackbar model }, getOerCardPlaceholderPositions True)
      |> requestWikichunkEnrichmentsIfNeeded
      |> requestEntityDefinitionsIfNeeded
      |> saveCourseIfNeeded
      |> saveLoggedEventsIfNeeded

    AnimationTick time ->
      let
          newModel =
            case model.flyingHeartAnimation of
              Nothing ->
                model

              Just {startTime} ->
                if millisSince model startTime > flyingHeartAnimationDuration then
                  { model | flyingHeartAnimation = Nothing }
                else
                  model
      in
          ( { newModel | currentTime = time } |> incrementFrameCountInModalAnimation, Cmd.none )

    ChangeSearchText str ->
      let
          autocompleteSuggestions =
            model.autocompleteTerms
            |> List.filter (\term -> String.startsWith (String.toLower str) (String.toLower term))
      in
          ( { model | searchInputTyping = str, autocompleteSuggestions = autocompleteSuggestions } |> closePopup, Cmd.none)
          |> logEventForLabStudy "ChangeSearchText" [ str ]

    TriggerSearch str ->
      let
          searchUrl =
            Url.Builder.relative [ searchPath ] [ Url.Builder.string "q" (String.trim str) ]
      in
          ({ model | inspectorState = Nothing } |> closePopup, Navigation.pushUrl nav.key searchUrl)
          |> logEventForLabStudy "TriggerSearch" [ str ]

    ResizeBrowser x y ->
      ( { model | windowWidth = x, windowHeight = y } |> closePopup, askPageScrollState True)

    InspectOer oer fragmentStart playWhenReady ->
      inspectOer model oer fragmentStart playWhenReady
      |> saveAction 1 [ ("oerId", Encode.int oer.id) ]
      |> logEventForLabStudy "InspectOer" [ oer.id |> String.fromInt, fragmentStart |> String.fromFloat, "playWhenReady:"++(if playWhenReady then "True" else "False") ]

    InspectCourseItem oer ->
      model
      |> update (InspectOer oer 0 False)
      |> logEventForLabStudy "InspectCourseItem" [ oer.id |> String.fromInt ]

    UninspectSearchResult ->
      ( { model | inspectorState = Nothing}, Cmd.none)
      |> logEventForLabStudy "UninspectSearchResult" []

    ModalAnimationStart animation ->
      ( { model | modalAnimation = Just animation }, Cmd.none )

    ModalAnimationStop dummy ->
      ( { model | modalAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove modalId }, Cmd.none )

    RequestSession (Ok session) ->
      let
          newModel =
            { model | session = Just session, timeWhenSessionLoaded = model.currentTime, overviewType = overviewTypeFromId session.overviewTypeId }

          cmd =
            case session.loginState of
              GuestUser ->
                Cmd.none

              LoggedInUser userProfile ->
                [ requestVideoUsages ] |> Cmd.batch
      in
          ( newModel |> resetUserProfileForm, cmd)
          |> logEventForLabStudy "RequestSession" []

    RequestSession (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSession"
      -- in
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    RequestVideoUsages (Ok dictWithStringKeys) ->
      let
          videoUsages =
            dictWithStringKeys
            |> Dict.foldl (\k v result -> result |> Dict.insert (k |> String.toInt |> Maybe.withDefault 0) v) Dict.empty
      in
          ({ model | videoUsages = videoUsages }, Cmd.none)

    RequestVideoUsages (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestVideoUsages"
      -- in
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    -- RequestUpdatePlayingVideo (Ok _) ->
    --   let
    --       dummy =
    --         model.playingVideo |> Debug.log "playingVideo"
    --   in
    --   (model, Cmd.none)

    -- RequestUpdatePlayingVideo (Err err) ->
    --   let
    --       dummy =
    --         err |> Debug.log "Error in RequestUpdatePlayingVideo"
    --   in
    --   ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    -- RequestNotes (Ok notes) ->
    --   let
    --       addNoteToNoteboard : Note -> Dict OerId Noteboard -> Dict OerId Noteboard
    --       addNoteToNoteboard note oerNoteboards =
    --         let
    --             oldNoteboard =
    --               oerNoteboards |> Dict.get note.oerId |> Maybe.withDefault []
    --         in
    --             oerNoteboards |> Dict.insert note.oerId (note::oldNoteboard)

    --       newOerNoteboards : Dict OerId Noteboard
    --       newOerNoteboards =
    --         notes
    --         |> List.foldl (\note noteboards -> noteboards |> addNoteToNoteboard note) Dict.empty

    --       newModel =
    --         { model | oerNoteboards = newOerNoteboards}

    --       oerIds =
    --         notes
    --         |> List.map .oerId
    --         |> List.Extra.unique
    --   in
    --       ( newModel, requestOersByIds newModel oerIds)
    --       |> logEventForLabStudy "RequestNotes" []

    -- RequestNotes (Err err) ->
    --   -- let
    --   --     dummy =
    --   --       err |> Debug.log "Error in RequestNotes"
    --   -- in
    --   -- ( { model | snackbar = createSnackbar model "An error occurred. Please reload the page." }, Cmd.none )
    --   ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    -- RequestDeleteNote (Ok _) ->
    --   ( model, requestNotes)
    --   |> logEventForLabStudy "RequestDeleteNote" []

    -- RequestDeleteNote (Err err) ->
    --   -- let
    --   --     dummy =
    --   --       err |> Debug.log "Error in RequestDeleteNote"
    --   -- in
    --   -- ( { model | snackbar = createSnackbar model "Some changes were not saved." }, Cmd.none )
    --   ( { model | snackbar = createSnackbar model "Some changes were not saved." }, Cmd.none )

    RequestOerSearch (Ok oers) ->
      let
          (newModel, cmd) =
            model
            |> updateSearch (insertSearchResults (oers |> List.map .id))
            |> cacheOersFromList oers
            |> inspectOerBasedOnUrlParameter
      in
          (newModel, [ cmd, setBrowserFocus "SearchField", getOerCardPlaceholderPositions True, askPageScrollState True ] |> Cmd.batch)
          |> requestWikichunkEnrichmentsIfNeeded
          |> logEventForLabStudy "RequestOerSearch" (oers |> List.map .id |> List.map String.fromInt)

    RequestOerSearch (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOerSearch"
      -- in
      -- ( { model | snackbar = createSnackbar model "There was a problem while fetching the search data" }, Cmd.none )
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    RequestOers (Ok oers) ->
      ( { model | requestingOers = False } |> cacheOersFromList oers, Cmd.none)

    RequestOers (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestOers"
      -- in
      -- ( { model | requestingOers = False, snackbar = createSnackbar model "There was a problem while fetching OER data" }, Cmd.none)
      ( { model | requestingOers = False, snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none)

    RequestFeatured (Ok oers) ->
      ( { model | featuredOers = oers |> List.map .id |> Just } |> cacheOersFromList oers, Cmd.none )

    RequestFeatured (Err err) ->
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none)

    RequestWikichunkEnrichments (Ok listOfEnrichments) ->
      let
          failCount =
            if List.isEmpty listOfEnrichments then
              model.wikichunkEnrichmentRequestFailCount + 1
            else
              0

          dictOfEnrichments =
            listOfEnrichments
            |> List.map (\enrichment -> (enrichment.oerId, enrichment))
            |> Dict.fromList

          retryTime =
            (posixToMillis model.currentTime) + (failCount*2000 |> min 5000) |> millisToPosix
      in
          ( { model | wikichunkEnrichments = model.wikichunkEnrichments |> Dict.union dictOfEnrichments, requestingWikichunkEnrichments = False, enrichmentsAnimating = True, wikichunkEnrichmentRequestFailCount = failCount, wikichunkEnrichmentRetryTime = retryTime } |> registerUndefinedEntities listOfEnrichments |> updateBubblogramsIfNeeded, Cmd.none )

    RequestWikichunkEnrichments (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestWikichunkEnrichments"
      -- in
      -- ( { model | snackbar = createSnackbar model "There was a problem - please reload the page.", requestingWikichunkEnrichments = False }, Cmd.none )
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage, requestingWikichunkEnrichments = False }, Cmd.none )

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
      -- ( { model | snackbar = createSnackbar model "There was a problem while fetching the wiki definitions data", requestingEntityDefinitions = False }, Cmd.none )
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage, requestingEntityDefinitions = False }, Cmd.none )

    -- RequestAutocompleteTerms (Ok autocompleteTerms) ->
    --   if (millisSince model model.timeOfLastSearch) < 2000 then
    --     (model, Cmd.none)
    --   else
    --     ({ model | autocompleteTerms = autocompleteTerms, suggestionSelectionOnHoverEnabled = False }, Cmd.none)

    -- RequestAutocompleteTerms (Err err) ->
    --   -- let
    --   --     dummy =
    --   --       err |> Debug.log "Error in RequestAutocompleteTerms"
    --   -- in
    --   -- ( { model | snackbar = createSnackbar model "There was a problem while fetching search suggestions" }, Cmd.none )
    --   ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    -- RequestFavorites (Ok favorites) ->
    --   let
    --       newModel = { model | favorites = favorites }
    --   in
    --       ( newModel, requestOersByIds newModel favorites)
    --       |> logEventForLabStudy "RequestFavorites" []

    -- RequestFavorites (Err err) ->
    --   -- let
    --   --     dummy =
    --   --       err |> Debug.log "Error in RequestFavorites"
    --   -- in
    --   ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    RequestSaveUserProfile (Ok _) ->
      ({ model | userProfileForm = { userProfileForm | saved = True }, userProfileFormSubmitted = False }, Cmd.none)

    RequestSaveUserProfile (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestSaveUserProfile"
      -- in
      ( { model | snackbar = createSnackbar model "Some changes were not saved", userProfileFormSubmitted = False }, Cmd.none )

    RequestLabStudyLogEvent (Ok _) ->
      (model, Cmd.none)

    RequestLabStudyLogEvent (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestLabStudyLogEvent"
      -- in
      -- ( { model | snackbar = createSnackbar model "Some logs were not saved" }, Cmd.none )
      ( { model | snackbar = createSnackbar model "Some logs were not saved" }, Cmd.none )

    RequestSaveAction (Ok _) ->
      (model, Cmd.none)

    RequestSaveAction (Err err) ->
      -- ( { model | snackbar = createSnackbar model "Some changes were not saved" }, Cmd.none )
      ( { model | snackbar = createSnackbar model "Some changes were not saved" }, Cmd.none )

    RequestLoadCourse (Ok course) ->
      ({ model | course = course, courseNeedsSaving = False}, Cmd.none)

    RequestLoadCourse (Err err) ->
      ( { model | snackbar = createSnackbar model "Some changes were not saved" }, Cmd.none )

    RequestSaveCourse (Ok _) ->
      ({ model | courseChangesSaved = True }, Cmd.none)

    RequestSaveCourse (Err err) ->
      ( { model | snackbar = createSnackbar model "Some changes were not saved" }, Cmd.none )

    RequestSaveLoggedEvents (Ok _) ->
      (model, Cmd.none)

    RequestSaveLoggedEvents (Err err) ->
      ( { model | snackbar = createSnackbar model "Some logs were not saved" }, Cmd.none )

    -- RequestSaveNote (Ok _) ->
    --   (model, requestNotes)

    -- RequestSaveNote (Err err) ->
    --   ( { model | snackbar = createSnackbar model "Some changes were not saved" }, Cmd.none )

    RequestResourceRecommendations (Ok oersUnfiltered) ->
      let
          isBeingInspected oerId =
            case model.inspectorState of
              Nothing ->
                False

              Just {oer} ->
                oer.id == oerId

          -- ensure that the resource itself isn't included in the recommendations
          oers =
            oersUnfiltered
            |> List.filter (\oer -> isBeingInspected oer.id |> not)
            |> List.Extra.uniqueBy .id -- remove any duplicates
            |> List.take 5

          newInspectorState =
            case model.inspectorState of
              Nothing ->
                Nothing

              Just inspectorState ->
                Just { inspectorState | resourceRecommendations = oers }
      in
          ({ model | inspectorState = newInspectorState } |> cacheOersFromList oers, setBrowserFocus "")
          |> requestWikichunkEnrichmentsIfNeeded
          |> logEventForLabStudy "RequestResourceRecommendations" (oers |> List.map .url)

    RequestResourceRecommendations (Err err) ->
      -- let
      --     dummy =
      --       err |> Debug.log "Error in RequestResourceRecommendations"
      -- in
      -- ( { model | snackbar = createSnackbar model "An error occurred while loading recommendations" }, Cmd.none )
      ( { model | snackbar = createSnackbar model snackbarMessageReloadPage}, Cmd.none )

    SetHover maybeOerId ->
      let
          (timelineHoverState, hoveringTagEntityId) =
            case maybeOerId of
              Nothing ->
                (Nothing, Nothing)

              Just _ ->
                (model.timelineHoverState, model.hoveringTagEntityId)
      in
          ( { model | hoveringOerId = maybeOerId, timelineHoverState = timelineHoverState, hoveringTagEntityId = hoveringTagEntityId, timeOfLastMouseEnterOnCard = model.currentTime } |> unselectMentionInStory, Cmd.none )
          |> logEventForLabStudy "SetHover" [ maybeOerId |> Maybe.withDefault 0 |> String.fromInt ]

    SetPopup popup ->
      let
          newModel =
            { model | popup = Just popup }
      in
          (newModel, Cmd.none)
          |> logEventForLabStudy "SetPopup" (popupToStrings newModel.popup)

    ClosePopup ->
      case model.popup of
        Nothing ->
          (model, Cmd.none )

        Just _ ->
          ( model |> closePopup, Cmd.none )
          |> logEventForLabStudy "ClosePopup" []

    CloseInspector ->
      case model.inspectorState of
        Nothing ->
          (model, Cmd.none )

        Just _ ->
          ( { model | inspectorState = Nothing }, Cmd.none )
          |> logEventForLabStudy "CloseInspector" []

    ClickedOnDocument ->
      ( { model | autocompleteSuggestions = [] }, Cmd.none )

    SelectSuggestion suggestion ->
      ( { model | selectedSuggestion = suggestion }, Cmd.none )
      |> logEventForLabStudy "SelectSuggestion" [ suggestion ]

    MouseOverChunkTrigger mousePositionX ->
      -- ( { model | mousePositionXwhenOnChunkTrigger = mousePositionX } |> unselectMentionInStory, Cmd.none )
      ( { model | mousePositionXwhenOnChunkTrigger = mousePositionX, hoveringTagEntityId = Nothing } |> unselectMentionInStory, Cmd.none )
      |> logEventForLabStudy "MouseOverChunkTrigger" [ mousePositionX |> String.fromFloat ]

    -- YoutubeSeekTo fragmentStart ->
    --   ( model, youtubeSeekTo fragmentStart)
    --   |> logEventForLabStudy "YoutubeSeekTo" [ fragmentStart |> String.fromFloat ]

    EditUserProfile field value ->
      let
          newForm =
            { userProfileForm | userProfile = userProfileForm.userProfile |> updateUserProfileField field value, saved = False }
      in
          ( { model | userProfileForm = newForm }, Cmd.none )
          |> logEventForLabStudy "EditUserProfile" []

    SubmittedUserProfile ->
      ( { model | userProfileFormSubmitted = True }, requestSaveUserProfile model.userProfileForm.userProfile)
      |> logEventForLabStudy "SubmittedUserProfile" []

    -- ChangedTextInNewNoteFormInOerNoteboard oerId str ->
    --   ( model |> setTextInNoteForm oerId str, Cmd.none)

    ChangedTextInResourceFeedbackForm oerId str ->
      ( model |> setTextInResourceFeedbackForm oerId str, Cmd.none)

    -- SubmittedNewNoteInOerNoteboard oerId ->
    --   let
    --       text =
    --         getOerNoteForm model oerId
    --   in
    --   (model |> createNote oerId text |> setTextInNoteForm oerId "", [ setBrowserFocus "textInputFieldForNotesOrFeedback", saveNote oerId text ] |> Cmd.batch)
    --   |> logEventForLabStudy "SubmittedNewNoteInOerNoteboard" [ String.fromInt oerId, getOerNoteForm model oerId ]

    SubmittedResourceFeedback oerId text ->
      ({ model | timeOfLastFeedbackRecorded = model.currentTime } |> setTextInResourceFeedbackForm oerId "", Cmd.none)
      |> logEventForLabStudy "SubmittedResourceFeedback" [ oerId |> String.fromInt, text ]
      |> saveAction 8 [ ("OER id", Encode.int oerId), ("user feedback", Encode.string text) ]

    -- PressedKeyInNewNoteFormInOerNoteboard oerId keyCode ->
    --   if keyCode==13 then
    --     model |> update (SubmittedNewNoteInOerNoteboard oerId)
    --   else
    --     (model, Cmd.none)

    -- ClickedQuickNoteButton oerId text ->
    --   (model |> createNote oerId text |> setTextInNoteForm oerId "" , saveNote oerId text)
    --   |> logEventForLabStudy "ClickedQuickNoteButtond" [ String.fromInt oerId, text ]

    -- RemoveNote note ->
    --   (model |> removeNote note, NotesApi.deleteNote note)
    --   |> logEventForLabStudy "RemoveNote" [ note.oerId |> String.fromInt, note.text ]

    YoutubeVideoIsPlayingAtPosition position ->
      (model, Cmd.none)
      |> logEventForLabStudy "YoutubeVideoIsPlayingAtPosition" [ position |> String.fromFloat]

    OverviewTagMouseOver entityId oerId ->
      let
          popup =
            case model.overviewType of
              BubblogramOverview TopicNames ->
                Just <| BubblePopup <| BubblePopupState oerId entityId DefinitionInBubblePopup []

              _ ->
                Nothing
      in
          ({model | hoveringTagEntityId = Just entityId, popup = popup }, Cmd.none)
          |> logEventForLabStudy "OverviewTagMouseOver" [ oerId |> String.fromInt, entityId ]

    OverviewTagLabelMouseOver entityId oerId ->
      let
          popup =
            BubblePopup <| BubblePopupState oerId entityId DefinitionInBubblePopup []
      in
          ({model | hoveringTagEntityId = Just entityId, popup = Just popup }, Cmd.none)
          |> logEventForLabStudy "OverviewTagLabelMouseOver" [ oerId |> String.fromInt, entityId ]

    OverviewTagMouseOut ->
      ({model | hoveringTagEntityId = Nothing } |> unselectMentionInStory |> closePopup, Cmd.none)
      |> logEventForLabStudy "OverviewTagMouseOut" []

    OverviewTagLabelClicked oerId ->
      let
          newModel =
            {model | popup = model.popup |> updateBubblePopupOnTagLabelClicked model oerId }
      in
          (newModel, Cmd.none)
          |> logEventForLabStudy "OverviewTagLabelClicked" (popupToStrings newModel.popup)

    PageScrolled ({scrollTop, viewHeight, contentHeight, requestedByElm} as pageScrollState) ->
      ({ model | pageScrollState = pageScrollState }, Cmd.none)
      |> logEventForLabStudy "PageScrolled" [ scrollTop |> String.fromFloat, viewHeight |> String.fromFloat, contentHeight |> String.fromFloat, if requestedByElm then "elm" else "user" ]

    OerCardPlaceholderPositionsReceived positions ->
      ({ model | oerCardPlaceholderPositions = positions }, Cmd.none)

    SelectInspectorSidebarTab tab oerId ->
      let
          cmd =
            if tab==RecommendationsTab then
              requestResourceRecommendations oerId
            else
              Cmd.none

          newInspectorState =
            case model.inspectorState of
              Nothing ->
                Nothing

              Just inspectorState ->
                Just { inspectorState | inspectorSidebarTab = tab }

          tabName =
            case tab of
              FeedbackTab ->
                "FeedbackTab"

              RecommendationsTab ->
                "RecommendationsTab"
      in
          ({ model | inspectorState = newInspectorState }, [ cmd, setBrowserFocus "textInputFieldForNotesOrFeedback" ] |> Cmd.batch )
          |> logEventForLabStudy "SelectInspectorSidebarTab" [ String.fromInt oerId, tabName ]

    -- MouseMovedOnStoryTag mousePosXonCard ->
    --   case model.overviewType of
    --     ImageOverview ->
    --       (model, Cmd.none)

    --     BubblogramOverview TopicNames ->
    --       (model, Cmd.none)

    --     _ ->
    --       model
    --       |> selectOrUnselectMentionInStory mousePosXonCard

    SelectedOverviewType overviewType ->
      let
          selectedMode =
            overviewTypeId overviewType
      in
          ({ model | overviewType = overviewType, hoveringTagEntityId = Nothing } |> closePopup, Cmd.none)
          |> logEventForLabStudy "SelectedOverviewType" [ selectedMode ]
          |> saveAction 10 [ ("selectedMode", Encode.string selectedMode) ]

    MouseEnterMentionInBubbblogramOverview oerId entityId mention ->
      ({ model | selectedMentionInStory = Just (oerId, mention), hoveringTagEntityId = Just entityId } |> setBubblePopupToMention oerId entityId mention, setBrowserFocus "")

    -- ClickedHeart oerId ->
    --   if isMarkedAsFavorite model oerId then
    --     ( { model | removedFavorites = model.removedFavorites |> Set.insert oerId }, Cmd.none)
    --     |> saveAction 3 [ ("oerId", Encode.int oerId) ]
    --   else
    --     let
    --         favorites =
    --           model.favorites ++ [ oerId ]
    --           |> List.Extra.unique
    --     in
    --       ( { model | favorites = favorites, removedFavorites = model.removedFavorites |> Set.remove oerId, flyingHeartAnimation = Just { startTime = model.currentTime } }, Cmd.none)
    --       |> saveAction 2 [ ("oerId", Encode.int oerId) ]

    FlyingHeartRelativeStartPositionReceived startPoint ->
      ( { model | flyingHeartAnimationStartPoint = Just startPoint }, Cmd.none)

    TimelineMouseEvent {eventName, position} ->
      let
          newModel =
            case eventName of
              "mousedown" ->
                { model | timelineHoverState = Just { position = position, mouseDownPosition = Just position } }

              "mouseup" ->
                case model.timelineHoverState of
                  Nothing ->
                    model -- impossible

                  Just {mouseDownPosition} ->
                    case mouseDownPosition of
                      Nothing ->
                        model -- impossible
                      Just dragStartPos ->
                        { model | timelineHoverState = Just { position = position, mouseDownPosition = Nothing } }
                        |> setCourseRange dragStartPos position

              "mousemove" ->
                case model.timelineHoverState of
                  Nothing ->
                    { model | timelineHoverState = Just { position = position, mouseDownPosition = Nothing } }

                  Just timelineHoverState ->
                    { model | timelineHoverState = Just { position = position, mouseDownPosition = timelineHoverState.mouseDownPosition } }

              _ ->
                model -- impossible
      in
          (newModel, Cmd.none)
          |> logEventForLabStudy "TimelineMouseEvent" [ eventName, position |> String.fromFloat ]

    TimelineMouseLeave ->
      let
          newModel =
            case model.timelineHoverState of
              Nothing ->
                model -- impossible

              Just {position, mouseDownPosition} ->
                case mouseDownPosition of
                  Nothing ->
                    model -- scrubbed but not dragged

                  Just dragStartPos ->
                    model |> setCourseRange dragStartPos position
      in
          ({ newModel | timelineHoverState = Nothing }, Cmd.none)
          |> logEventForLabStudy "TimelineMouseLeave" []

    Html5VideoStarted pos ->
      (model |> updateVideoPlayer (Started pos) |> extendVideoUsages pos, Cmd.none)
      |> saveVideoAction 4

    Html5VideoPaused pos ->
      (model |> updateVideoPlayer (Paused pos), Cmd.none)
      |> saveVideoAction 5

    Html5VideoSeeked pos ->
      (model |> updateVideoPlayer (PositionChanged pos), Cmd.none)
      |> saveVideoAction 6

    Html5VideoStillPlaying pos ->
      (model |> updateVideoPlayer (PositionChanged pos) |> extendVideoUsages pos, Cmd.none)
      |> saveVideoAction 9

    Html5VideoAspectRatio aspectRatio ->
      case model.inspectorState of
        Nothing ->
          (model, Cmd.none)

        Just inspectorState ->
          case inspectorState.videoPlayer of
            Nothing ->
              (model, Cmd.none)

            Just videoPlayer ->
              ({ model | inspectorState = Just { inspectorState | videoPlayer = Just { videoPlayer | aspectRatio = aspectRatio } } }, Cmd.none)

    StartCurrentHtml5Video pos ->
      (model |> extendVideoUsages pos, startCurrentHtml5Video pos)
      |> logEventForLabStudy "StartCurrentHtml5Video" [ pos |> String.fromFloat ]

    ToggleContentFlow ->
      case model.session of
        Nothing ->
          (model, Cmd.none)

        Just session ->
          let
              enabled =
                not session.isContentFlowEnabled
          in
              ({ model | session = Just { session | isContentFlowEnabled = enabled } }, Cmd.none)
              |> saveAction 7 [ ("enable", Encode.bool enabled) ]
              |> logEventForLabStudy "ToggleContentFlow" [ if enabled then "enabled" else "disabled" ]

    AddedOerToCourse oerId range ->
      let
          newItem =
            { oerId = oerId
            , range = range
            , comment = ""
            }

          oldCourse =
            model.course

          newCourse =
            { oldCourse | items = newItem :: oldCourse.items}
      in
          ({ model | course = newCourse } |> markCourseAsChanged, Cmd.none)
          |> logEventForLabStudy "AddedOerToCourse" [ oerId |> String.fromInt, courseToString newCourse ]

    RemovedOerFromCourse oerId ->
      let
          oldCourse =
            model.course

          newCourse =
            { oldCourse | items = oldCourse.items |> List.filter (\item -> item.oerId/=oerId)}
      in
          ({ model | course = newCourse } |> markCourseAsChanged, Cmd.none)
          |> logEventForLabStudy "RemovedOerFromCourse" [ oerId |> String.fromInt, courseToString newCourse ]

    MovedCourseItemDown index ->
      let
          oldCourse =
            model.course

          newCourse =
            { oldCourse | items = oldCourse.items |> swapListItemWithNext index}
      in
          ({ model | course = newCourse} |> markCourseAsChanged, Cmd.none)
          |> logEventForLabStudy "MovedCourseItemDown" [ index |> String.fromInt, courseToString newCourse ]

    ChangedCommentTextInCourseItem oerId str ->
      ( model |> setCommentTextInCourseItem oerId str, Cmd.none)

    SubmittedCourseItemComment ->
      ( model |> markCourseAsChanged, setBrowserFocus "")
      |> logEventForLabStudy "SubmittedCourseItemComment" []

    StartTask taskName ->
      let
          searchText =
            case taskName of
              "Task 1" ->
                "labstudytask1"

              "Task 2" ->
                "labstudytask2"

              _ ->
                "labstudypractice"

          newModel =
            { model | currentTaskName = Just taskName, searchInputTyping = searchText, searchState = Just <| newSearch searchText, snackbar = Nothing }
      in
          ( newModel, [ setBrowserFocus "", searchOers searchText] |> Cmd.batch)
          |> logEventForLabStudy "StartTask" [ taskName ]

    CompleteTask ->
      ( { model | currentTaskName = Nothing }, setBrowserFocus "")
      |> logEventForLabStudy "CompleteTask" []

    OpenedOverviewModePopup ->
      ( { model | popup = Just OverviewModePopup }, setBrowserFocus "")
      |> logEventForLabStudy "OpenedOverviewModePopup" []


-- createNote : OerId -> String -> Model -> Model
-- createNote oerId text model =
--   let
--       newNote =
--         Note text model.currentTime oerId 0

--       oldNoteboard : Noteboard
--       oldNoteboard =
--         getOerNoteboard model oerId

--       newNoteboard : Noteboard
--       newNoteboard =
--         newNote :: oldNoteboard
--   in
--       { model | oerNoteboards = model.oerNoteboards |> Dict.insert oerId newNoteboard }


-- removeNote : Note -> Model -> Model
-- removeNote note model =
--   let
--       filter : OerId -> Noteboard -> Noteboard
--       filter _ notes =
--         notes
--         |> List.filter (\n -> n /= note)
--   in
--      { model | oerNoteboards = model.oerNoteboards |> Dict.map filter }


updateSearch : (SearchState -> SearchState) -> Model -> Model
updateSearch transformFunction model =
  case model.searchState of
    Nothing ->
      model

    Just searchState ->
      { model | searchState = Just (searchState |> transformFunction) }


insertSearchResults : List OerId -> SearchState -> SearchState
insertSearchResults oerIds searchState =
  { searchState | searchResults = Just oerIds }


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


requestOersByIds : Model -> List OerId -> Cmd Msg
requestOersByIds model oerIds =
  oerIds
  |> List.filter (\oerId -> isOerLoaded model oerId |> not)
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


cacheOersFromList : List Oer -> Model -> Model
cacheOersFromList oers model =
  let
      oersDict =
        oers
        |> List.foldl (\oer output -> output |> Dict.insert oer.id oer) Dict.empty
  in
      { model | cachedOers = Dict.union oersDict model.cachedOers }


inspectOerBasedOnUrlParameter : Model -> (Model, Cmd Msg)
inspectOerBasedOnUrlParameter model =
  let
      urlParameter =
        model.nav.url.query
        |> Maybe.withDefault ""
        |> String.split "&i="
        |> List.drop 1
        |> List.head
        |> Maybe.withDefault ""
        |> String.toInt
  in
      case urlParameter of
        Nothing ->
          (model, Cmd.none)

        Just oerId ->
          case model.cachedOers |> Dict.get oerId of
            Nothing ->
              (model, Cmd.none)

            Just oer ->
              inspectOer model oer 0 False


-- setTextInNoteForm : OerId -> String -> Model -> Model
-- setTextInNoteForm oerId str model =
--   { model | oerNoteForms = model.oerNoteForms |> Dict.insert oerId str }


setTextInResourceFeedbackForm : OerId -> String -> Model -> Model
setTextInResourceFeedbackForm oerId str model =
  { model | feedbackForms = model.feedbackForms |> Dict.insert oerId str }


updateBubblogramsIfNeeded : Model -> Model
updateBubblogramsIfNeeded model =
  { model | wikichunkEnrichments = model.wikichunkEnrichments |> Dict.map (addBubblogram model) }


logEventForLabStudy : String -> List String -> (Model, Cmd Msg) -> (Model, Cmd Msg)
logEventForLabStudy eventType params (model, cmd) =
  -- let
  --     dummy =
  --       eventType :: params
  --       |> String.join " "
  --       |> Debug.log "logEventForLabStudy"
  -- in
  if isLabStudy1 model then
    let
        timeString =
          model.currentTime
          |> posixToMillis
          |> String.fromInt

        logString =
          timeString ++ ": " ++ eventType ++ " " ++ (params |> String.join ", ")
    in
        ({ model | loggedEvents = logString :: model.loggedEvents }, cmd)
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

        BubblePopup {oerId, entityId, content} ->
          let
              contentString =
                case content of
                  DefinitionInBubblePopup ->
                    "Definition"

                  MentionInBubblePopup {positionInResource, sentence} ->
                    "Mention " ++ (positionInResource |> String.fromFloat) ++ " " ++ sentence
          in
              [ oerId |> String.fromInt, entityId, contentString ]

        OverviewModePopup ->
          [ "OverviewModePopup" ]


executeSearchAfterUrlChanged : Model -> Url -> (Model, Cmd Msg)
executeSearchAfterUrlChanged model url =
  let
      textParam =
        url.query
        |> Maybe.withDefault ""
        |> String.dropLeft 2 -- TODO A much cleaner method is to use Url.Query.parser
        |> String.split "&"
        |> List.head
        |> Maybe.withDefault ""
        |> Url.percentDecode
        |> Maybe.withDefault ""

      -- when searching by ID, don't change the value in the input field
      -- see issue #298
      searchInputTyping =
        case textParam |> String.toInt of
          Nothing ->
            textParam

          Just _ ->
            model.searchInputTyping

      newModel =
        { model | searchInputTyping = searchInputTyping,  searchState = Just <| newSearch textParam, autocompleteSuggestions = [], timeOfLastSearch = model.currentTime, snackbar = Nothing }
  in
        ( newModel |> closePopup, searchOers textParam)
        |> logEventForLabStudy "executeSearchAfterUrlChanged" [ textParam ]


saveVideoAction : Int -> (Model, Cmd Msg)-> (Model, Cmd Msg)
saveVideoAction actionTypeId (model, oldCmd) =
  case model.inspectorState of
    Nothing ->
      (model, oldCmd) -- impossible

    Just {oer, videoPlayer} ->
      case videoPlayer of
        Nothing ->
          (model, oldCmd) -- impossible

        Just {currentTime} ->
          (model, oldCmd)
          |> saveAction actionTypeId [ ("oerId", Encode.int oer.id), ("positionInSeconds", Encode.float currentTime) ]


saveAction : Int -> List (String, Encode.Value) -> (Model, Cmd Msg)-> (Model, Cmd Msg)
saveAction actionTypeId params (model, oldCmd) =
  if isLoggedIn model then
    (model, [ oldCmd, ActionApi.saveAction actionTypeId params ] |> Cmd.batch)
  else
    (model, oldCmd)


createSnackbar : Model -> String -> Maybe Snackbar
createSnackbar model str =
  Just <| Snackbar model.currentTime str


updateSnackbar : Model -> Maybe Snackbar
updateSnackbar model =
  case model.snackbar of
    Nothing ->
      Nothing

    Just snackbar ->
      if (millisSince model snackbar.startTime) > snackbarDuration then
        Nothing
      else
        Just snackbar


snackbarMessageReloadPage : String
snackbarMessageReloadPage =
  "There was a problem - please reload the page"


unselectMentionInStory : Model -> Model
unselectMentionInStory model =
  { model | selectedMentionInStory = Nothing }


selectOrUnselectMentionInStory : Float -> Model -> (Model, Cmd Msg)
selectOrUnselectMentionInStory mousePosXonCard model =
  let
      unselect =
        (model |> unselectMentionInStory, setBrowserFocus "")
        |> logEventForLabStudy "UnselectMentionInStory" []
  in
      case model.hoveringTagEntityId of
        Nothing ->
          unselect

        Just entityId ->
          case model.hoveringOerId of
            Nothing ->
              unselect

            Just oerId ->
              let
                  closestMentionInRange =
                    getMentions model oerId entityId
                    |> List.filter (\{positionInResource} -> (abs (positionInResource - mousePosXonCard) < 0.05))
                    |> List.sortBy (\{positionInResource} -> (abs (positionInResource - mousePosXonCard)))
                    |> List.head
              in
                  case closestMentionInRange of
                    Nothing ->
                      unselect

                    Just mention ->
                      ({ model | selectedMentionInStory = Just (oerId, mention), hoveringTagEntityId = Just entityId } |> setBubblePopupToMention oerId entityId mention, setBrowserFocus "")
                      |> logEventForLabStudy "SelectMentionInStory" [ oerId |> String.fromInt, mousePosXonCard |> String.fromFloat, mention.positionInResource |> String.fromFloat, mention.sentence ]


type VideoPlayerMsg
  = Started Float
  | Paused Float
  | PositionChanged Float
  | Duration Float


updateVideoPlayer : VideoPlayerMsg -> Model -> Model
updateVideoPlayer msg model =
  case model.inspectorState of
    Nothing ->
      model -- impossible

    Just inspectorState ->
      case inspectorState.videoPlayer of
        Nothing ->
          model -- impossible

        Just videoPlayer ->
          let
              newVideoPlayer =
                case msg of
                  Started pos ->
                    { videoPlayer | currentTime = pos, isPlaying = True }

                  Paused pos ->
                    { videoPlayer | currentTime = pos, isPlaying = False }

                  PositionChanged pos ->
                    { videoPlayer | currentTime = pos }

                  Duration duration ->
                    { videoPlayer | duration = duration }

              newInspectorState =
                { inspectorState | videoPlayer = Just newVideoPlayer }
          in
              { model | inspectorState = Just newInspectorState }


extendVideoUsages : Float -> Model -> Model
extendVideoUsages pos model =
  case model.inspectorState of
    Nothing ->
      model -- impossible

    Just {oer} ->
      let
          oldRanges =
            case Dict.get oer.id model.videoUsages of
              Nothing ->
                []

              Just ranges ->
                ranges
      in
          let
              newRanges =
                (Range pos videoPlayReportingInterval) :: oldRanges
          in
              { model | videoUsages = Dict.insert oer.id newRanges model.videoUsages  }


courseToString : Course -> String
courseToString {items} =
  items
  |> List.map (\item -> (String.fromInt item.oerId) ++ ":" ++ (item.range.start |> String.fromFloat) ++ "-" ++ (item.range.start + item.range.length |> String.fromFloat))
  |> String.join ","


setCourseRange : Float -> Float -> Model -> Model
setCourseRange dragStartPosition dragEndPosition ({course} as model) =
  let
      newModel oerId duration =
        let
            range =
              { start = dragStartPosition * duration
              , length = (dragEndPosition - dragStartPosition) * duration
              }
              |> invertRangeIfNeeded

            maybeExistingItem =
              course.items
              |> List.filter (\item -> item.oerId==oerId)
              |> List.head

            newItems =
              case maybeExistingItem of
                Nothing ->
                  { oerId = oerId, range = range, comment = "" } :: course.items

                Just existingItem ->
                  course.items
                  |> List.map (\item -> if item.oerId==existingItem.oerId then { item | range = range } else item)

            oldCourse : Course
            oldCourse =
              model.course
        in
            if range.length > duration/100 then -- it needs to be drag, not click
              { model | course = { oldCourse | items = newItems } }
              |> markCourseAsChanged
            else
              model
  in
      case model.inspectorState of
        Just {oer} ->
          newModel oer.id oer.durationInSeconds

        Nothing ->
          case model.hoveringOerId of
            Just hoveringOerId ->
              case model.cachedOers |> Dict.get hoveringOerId of
                Nothing ->
                  model -- impossible

                Just oer ->
                  newModel hoveringOerId oer.durationInSeconds

            Nothing ->
              model -- impossible


setCommentTextInCourseItem : OerId -> String -> Model -> Model
setCommentTextInCourseItem oerId str model =
  let
      oldCourse =
        model.course

      newItems =
        oldCourse.items
        |> List.map (\item -> if item.oerId==oerId then { item | comment = str } else item)

      newCourse =
        { oldCourse | items = newItems }
  in
      { model | course = newCourse} |> markCourseAsChanged


saveCourseIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
saveCourseIfNeeded (oldModel, oldCmd) =
  if oldModel.courseNeedsSaving && millisSince oldModel oldModel.lastTimeCourseChanged > 2000 then
    ({ oldModel | courseNeedsSaving = False }, [ requestSaveCourse oldModel.course, oldCmd ] |> Cmd.batch)
  else
    (oldModel, oldCmd)


markCourseAsChanged : Model -> Model
markCourseAsChanged model =
  { model | courseNeedsSaving = True, courseChangesSaved = False, lastTimeCourseChanged = model.currentTime }


saveLoggedEventsIfNeeded : (Model, Cmd Msg) -> (Model, Cmd Msg)
saveLoggedEventsIfNeeded (oldModel, oldCmd) =
  if oldModel.loggedEvents/=[] && millisSince oldModel oldModel.timeWhenSessionLoaded > 10000 && millisSince oldModel oldModel.lastTimeLoggedEventsSaved > 5000 then
    ({ oldModel | loggedEvents = [], lastTimeLoggedEventsSaved = oldModel.currentTime }, [ requestSaveLoggedEvents oldModel, oldCmd ] |> Cmd.batch)
  else
    (oldModel, oldCmd)


{-| Number of seconds between HTTP requests to report the ongoing
    video play position.
    Keep this constant in sync with the JavaScript constant (same name)
    and VIDEO_PLAY_REPORTING_INTERVAL in python
-}
videoPlayReportingInterval : Float
videoPlayReportingInterval =
  10


inspectOer : Model -> Oer -> Float -> Bool -> (Model, Cmd Msg)
inspectOer model oer fragmentStart playWhenReady =
  let
      videoEmbedParams : VideoEmbedParams
      videoEmbedParams =
        { modalId = modalId
        , videoId = getYoutubeVideoId oer.url |> Maybe.withDefault ""
        , videoStartPosition = fragmentStart * oer.durationInSeconds
        , playWhenReady = playWhenReady
        }
  in
      ({ model | inspectorState = Just <| newInspectorState oer fragmentStart, animationsPending = model.animationsPending |> Set.insert modalId } |> closePopup
      , openModalAnimation videoEmbedParams)
