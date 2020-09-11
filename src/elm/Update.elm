module Update exposing (update, countOfUserPlaylists)

-- import Url.Parser
-- import Url.Parser.Query

import ActionApi exposing (..)
import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra
import Model exposing (..)
import Msg exposing (..)
import Ports exposing (..)
import Request exposing (..)
import Set
import Time exposing (Posix, millisToPosix, posixToMillis)
import Update.BubblePopup exposing (..)
import Update.Bubblogram exposing (..)
import Url exposing (Url)
import Url.Builder

import I18Next exposing ( t, Delims(..) )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ nav, userProfileForm, playlistPublishForm, playlistCreateForm } as model) =
    -- let
    --     actionlog =
    --       msg |> Debug.log "action"
    -- in
    case msg of
        ModelInitialized url ->
            let
                ( newModel, cmd ) =
                    model |> update (UrlChanged url)
            in
                ( newModel, [ cmd, requestSession, requestLoadCourse, requestLoadUserPlaylists, requestLoadLicenseTypes, askPageScrollState True ] |> Cmd.batch )


        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    if List.member (url.path |> String.dropLeft 1) ("login signup logout about" |> String.split " ") then
                        ( model |> closePopup, Navigation.load (Url.toString url) )
                            |> logEventForLabStudy "LinkClickedInternal" [ url.path ]

                    else
                        ( model |> closePopup, Navigation.pushUrl model.nav.key (Url.toString url) )
                            |> logEventForLabStudy "LinkClickedInternal" [ url.path ]

                Browser.External href ->
                    ( model |> closePopup, Navigation.load href )
                        |> logEventForLabStudy "LinkClickedExternal" [ href ]

        UrlChanged url ->
            let
                ( subpage, ( newModel, cmd ) ) =
                    if url.path |> String.startsWith profilePath then
                        ( Profile, ( model, Cmd.none ) )

                    else if url.path |> String.startsWith publishPlaylistPath then
                        case model.playlist of
                            Nothing ->
                                ( Home
                                , ( model
                                  , if model.featuredOers == Nothing then
                                        requestFeaturedOers

                                    else
                                        Cmd.none
                                  )
                                )

                            Just playlist ->
                                let
                                    newPlaylistPublishForm =
                                        PublishPlaylistForm playlist False playlist.title Nothing
                                in
                                ( PublishPlaylist, ( { model | playlistPublishForm = newPlaylistPublishForm }, Cmd.none ) )

                    else if url.path |> String.startsWith createPlaylistPath then
                        if countOfUserPlaylists model.userPlaylists >= 5 then
                            ( Home
                            , ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_playlist_maximum_limit_warning") }
                                , if model.featuredOers == Nothing then
                                    requestFeaturedOers

                                else
                                    Cmd.none
                                )
                            )
                        else
                            let
                                freshPlaylist = 
                                    Playlist Nothing (t model.translations "playlist.lbl_playlist_new") Nothing Nothing Nothing Nothing True Nothing [] Nothing []
                                updatedPlaylistCreateForm = { playlistCreateForm | playlist = freshPlaylist, saved = False, isClone = False }
                            in
                            ( CreatePlaylist, ( { model | playlist = Nothing, playlistCreateForm = updatedPlaylistCreateForm }, Cmd.none ) )

                    else if url.path |> String.startsWith searchPath then
                        ( Search, executeSearchAfterUrlChanged model url )

                    else
                        -- default to home page
                        ( Home
                        , ( { model | searchIsPlaylist = False }
                          , if model.featuredOers == Nothing then
                                requestFeaturedOers

                            else
                                Cmd.none
                          )
                        )

                query =
                    url.query |> Maybe.withDefault ""
            in
            ( { newModel | nav = { nav | url = url }, inspectorState = Nothing, timeOfLastUrlChange = model.currentTime, subpage = subpage } |> closePopup |> resetUserProfileForm |> showLoginHintIfNeeded, cmd )
                |> logEventForLabStudy "UrlChanged" [ url.path, query ]
                |> saveAction 14 [ ( "path", Encode.string url.path ), ( "query", Encode.string query ) ]

        ClockTicked currentTime ->
            ( { model | currentTime = currentTime, enrichmentsAnimating = anyBubblogramsAnimating model, snackbar = updateSnackbar model }, getOerCardPlaceholderPositions True )
                |> requestWikichunkEnrichmentsIfNeeded
                |> requestEntityDefinitionsIfNeeded
                |> saveCourseIfNeeded
                |> saveLoggedEventsIfNeeded

        AnimationTick currentTime ->
            ( { model | currentTime = currentTime } |> incrementFrameCountInInspectorAnimation, Cmd.none )

        SearchFieldChanged str ->
            ( { model | searchInputTyping = str } |> closePopup, Cmd.none )
                |> logEventForLabStudy "SearchFieldChanged" [ str ]

        TriggerSearch str isFromSearchField ->
            if str == "" then
                (model, Cmd.none)
            else
                let
                    searchUrl =
                        Url.Builder.relative [ searchPath ] [ Url.Builder.string "q" (String.trim str) ]
                in
                ( { model | inspectorState = Nothing } |> closePopup, Navigation.pushUrl nav.key searchUrl )
                    |> saveAction 13 [ ( "text", Encode.string str ), ( "isFromSearchField", Encode.bool isFromSearchField ) ]

        BrowserResized x y ->
            ( { model | windowWidth = x, windowHeight = y } |> closePopup, askPageScrollState True )

        InspectOer oer fragmentStart playWhenReady commentForLogging ->
            let
                newModel = 
                    if commentForLogging == "ClickedOnPlaylistItem" then
                        case model.playlist of
                            Nothing ->
                                { model | openedOerFromPlaylist = False }

                            Just playlist ->
                                let
                                    playlistTitle =
                                        case getPlaylistTitle model oer.id of
                                            Nothing ->
                                                oer.title

                                            Just title ->
                                                title

                                    playlistDescription =
                                        case getPlaylistDescription model oer.id of
                                            Nothing ->
                                                oer.description

                                            Just description ->
                                                description

                                    playlistItem =
                                        PlaylistItem oer.id playlistTitle playlistDescription
                                in
                                    { model | openedOerFromPlaylist = True, editingOerPlaylistItem = playlistItem }
                    else
                        { model | openedOerFromPlaylist = False }

            in
            inspectOer newModel oer fragmentStart playWhenReady
                |> saveAction 1 [ ( "oerId", Encode.int oer.id ) ]
                |> logEventForLabStudy "InspectOer"
                    [ oer.id |> String.fromInt
                    , fragmentStart |> String.fromFloat
                    , "playWhenReady:"
                        ++ (if playWhenReady then
                                "True"

                            else
                                "False"
                           )
                    , commentForLogging
                    ]

        ClickedOnCourseItem oer ->
            model
                |> update (InspectOer oer 0 False "ClickedOnCourseItem")
                |> logEventForLabStudy "ClickedOnCourseItem" [ oer.id |> String.fromInt ]

        PressedCloseButtonInInspector ->
            ( { model | inspectorState = Nothing }, Cmd.none )
                |> logEventForLabStudy "PressedCloseButtonInInspector" []

        InspectorAnimationStart animation ->
            ( { model | inspectorAnimation = Just animation }, Cmd.none )

        InspectorAnimationStop dummy ->
            ( { model | inspectorAnimation = Nothing, animationsPending = model.animationsPending |> Set.remove inspectorId }, Cmd.none )

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
            ( newModel |> resetUserProfileForm, cmd )
                |> logEventForLabStudy "RequestSession" []

        RequestSession (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestSession"
            -- in
            ( { model | snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

        RequestVideoUsages (Ok dictWithStringKeys) ->
            let
                videoUsages =
                    dictWithStringKeys
                        |> Dict.foldl (\k v result -> result |> Dict.insert (k |> String.toInt |> Maybe.withDefault 0) v) Dict.empty
            in
            ( { model | videoUsages = videoUsages }, Cmd.none )

        RequestVideoUsages (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestVideoUsages"
            -- in
            ( { model | snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

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
        RequestOerSearch (Ok oerSearchResult) ->
            let
                ( newModel, cmd ) =
                    model
                        |> insertSearchResults ( oerSearchResult.oers |> List.map .id)
                        |> cacheOersFromList oerSearchResult.oers
                        |> inspectOerBasedOnUrlParameter
            in
            ( { newModel | searchTotalPages = oerSearchResult.totalPages }, [ cmd, setBrowserFocus "SearchField", getOerCardPlaceholderPositions True, askPageScrollState True ] |> Cmd.batch )
                |> requestWikichunkEnrichmentsIfNeeded
                |> logEventForLabStudy "RequestOerSearch" (oerSearchResult.oers |> List.map .id |> List.map String.fromInt)

        RequestOerSearch (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestOerSearch"
            -- in
            -- ( { model | snackbar = createSnackbar model "There was a problem while fetching the search data" }, Cmd.none )
            ( { model | snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

        RequestOers (Ok oers) ->
            ( { model | requestingOers = False } |> cacheOersFromList oers, Cmd.none )

        RequestOers (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestOers"
            -- in
            -- ( { model | requestingOers = False, snackbar = createSnackbar model "There was a problem while fetching OER data" }, Cmd.none)
            ( { model | requestingOers = False, snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

        RequestFeatured (Ok oers) ->
            ( { model | searchIsPlaylist = False, featuredOers = oers |> List.map .id |> Just } |> cacheOersFromList oers, Cmd.none )

        RequestFeatured (Err err) ->
            ( { model | snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

        RequestWikichunkEnrichments (Ok listOfEnrichments) ->
            let
                failCount =
                    if List.isEmpty listOfEnrichments then
                        model.wikichunkEnrichmentRequestFailCount + 1

                    else
                        0

                dictOfEnrichments =
                    listOfEnrichments
                        |> List.map (\enrichment -> ( enrichment.oerId, enrichment ))
                        |> Dict.fromList

                retryTime =
                    posixToMillis model.currentTime + (failCount * 2000 |> min 5000) |> millisToPosix

                newModel =
                    { model
                        | wikichunkEnrichments = model.wikichunkEnrichments |> Dict.union dictOfEnrichments
                        , requestingWikichunkEnrichments = False
                        , enrichmentsAnimating = True
                        , wikichunkEnrichmentRequestFailCount = failCount
                        , wikichunkEnrichmentRetryTime = retryTime
                    }
                        |> registerUndefinedEntities listOfEnrichments
                        |> updateBubblogramsIfNeeded
            in
            ( newModel, Cmd.none )

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

        RequestSaveUserProfile (Ok _) ->
            ( { model | userProfileForm = { userProfileForm | saved = True }, userProfileFormSubmitted = False }, Cmd.none )

        RequestSaveUserProfile (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestSaveUserProfile"
            -- in
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning"), userProfileFormSubmitted = False }, Cmd.none )

        RequestLabStudyLogEvent (Ok _) ->
            ( model, Cmd.none )

        RequestLabStudyLogEvent (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestLabStudyLogEvent"
            -- in
            -- ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_logs_not_saved_warning") }, Cmd.none )
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestSaveAction (Ok _) ->
            ( model, Cmd.none )

        RequestSaveAction (Err err) ->
            -- ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestLoadCourse (Ok course) ->
            let
                newModel =
                    { model | course = course, courseNeedsSaving = False, courseOptimization = Nothing }

                oerIds =
                    course.items
                        |> List.map .oerId
            in
            ( newModel, requestOersByIds newModel oerIds )

        RequestLoadCourse (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestSaveCourse (Ok _) ->
            ( { model | courseChangesSaved = model.courseNeedsSaving, courseNeedsSaving = False }, Cmd.none )

        RequestSaveCourse (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestSaveLoggedEvents (Ok _) ->
            ( model, Cmd.none )

        RequestSaveLoggedEvents (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_logs_not_saved_warning") }, Cmd.none )

        RequestResourceRecommendations (Ok oersUnfiltered) ->
            let
                isBeingInspected oerId =
                    case model.inspectorState of
                        Nothing ->
                            False

                        Just { oer } ->
                            oer.id == oerId

                -- ensure that the resource itself isn't included in the recommendations
                oers =
                    oersUnfiltered
                        |> List.filter (\oer -> isBeingInspected oer.id |> not)
                        |> List.Extra.uniqueBy .id
                        -- remove any duplicates
                        |> List.take 5

                newInspectorState =
                    case model.inspectorState of
                        Nothing ->
                            Nothing

                        Just inspectorState ->
                            Just { inspectorState | resourceRecommendations = oers }
            in
            ( { model | inspectorState = newInspectorState } |> cacheOersFromList oers, setBrowserFocus "" )
                |> requestWikichunkEnrichmentsIfNeeded
                |> logEventForLabStudy "RequestResourceRecommendations" (oers |> List.map .url)

        RequestResourceRecommendations (Err err) ->
            -- let
            --     dummy =
            --       err |> Debug.log "Error in RequestResourceRecommendations"
            -- in
            -- ( { model | snackbar = createSnackbar model "An error occurred while loading recommendations" }, Cmd.none )
            ( { model | snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

        RequestCourseOptimization (Ok newSequenceOerIds) ->
            let
                oldCourse =
                    model.course

                newItems =
                    newSequenceOerIds
                        |> List.filterMap (\oerId -> oldCourse.items |> List.filter (\item -> item.oerId == oerId) |> List.head)

                newCourse =
                    { oldCourse | items = newItems }
            in
            ( { model | course = newCourse, courseOptimization = Just (UndoAvailable oldCourse) }, Cmd.none )
                |> saveCourseNow

        RequestCourseOptimization (Err err) ->
            ( { model | snackbar = createSnackbar model snackbarMessageReloadPage }, Cmd.none )

        RequestLoadUserPlaylists (Ok playlists) ->
            case model.playlist of
                Nothing ->
                    ( { model | userPlaylists = Just playlists }, Cmd.none )

                Just playlist ->
                    let
                        updatedPlaylist =
                            filterPlaylistByText playlists playlist

                        oerIds =
                            List.map (\x -> x) updatedPlaylist.oerIds

                        courseItems =
                            List.map (\x -> CourseItem x [] "") updatedPlaylist.oerIds

                        course =
                            Course courseItems
                    in
                    ( { model | userPlaylists = Just playlists, course = course, playlist = Just updatedPlaylist }, requestOersByIds model oerIds )

        RequestLoadUserPlaylists (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_publish_playlist_error") }, Cmd.none )

        RequestCreatePlaylist (Ok _) ->
            ( { model | playlistCreateForm = { playlistCreateForm | saved = True, isClone = False }, playlistCreateFormSubmitted = False }, requestLoadUserPlaylists )

        RequestCreatePlaylist (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning"), playlistCreateFormSubmitted = False }, Cmd.none )

        RequestAddToPlaylist (Ok _) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_add_to_playlist_success") }, requestLoadUserPlaylists )

        RequestAddToPlaylist (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestSavePlaylist (Ok _) ->
            ( { model | snackbar = createSnackbar model  (t model.translations "alerts.lbl_temp_playlist_save_success")  }, requestLoadUserPlaylists )

        RequestSavePlaylist (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestDeletePlaylist (Ok _) ->
            ( { model | promptedDeletePlaylist = False, playlist = Nothing, snackbar = createSnackbar model (t model.translations "alerts.lbl_temp_playlist_delete_success") }, requestLoadUserPlaylists )

        RequestDeletePlaylist (Err err) ->
            ( { model | promptedDeletePlaylist = False, snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestLoadLicenseTypes (Ok licenseTypes) ->
            ( { model | licenseTypes = licenseTypes }, Cmd.none )

        RequestLoadLicenseTypes (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_license_types_load_error") }, Cmd.none )

        RequestPublishPlaylist (Ok id) ->
            let
                url =
                    "/search?q=pl:" ++ id

                updatedPublishPlaylistForm =
                    { playlistPublishForm | blueprintUrl = Just url }
            in
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_publish_playlist_success"), playlistPublishFormSubmitted = False, playlistPublishForm = updatedPublishPlaylistForm, playlist = Nothing }, requestLoadUserPlaylists )

        RequestPublishPlaylist (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_publish_playlist_error"), playlistPublishFormSubmitted = False }, Cmd.none )

        RequestFetchPublishedPlaylist (Ok playlist) ->
            let
                parentPlaylist = { playlist | parent = playlist.id}
                updatedPlaylistCreateForm = { playlistCreateForm | playlist = parentPlaylist, saved = False, isClone = True }
            in
                ( { model | publishedPlaylist = Just playlist, playlistCreateForm = updatedPlaylistCreateForm }, Cmd.none )

        RequestFetchPublishedPlaylist (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_playlist_fetch_error") }, Cmd.none )

        RequestSaveNote (Ok _) ->
            case model.inspectorState of
                Nothing ->
                    ( model, Cmd.none)

                Just state ->
                    ( model , requestFetchNotesForOer state.oer.id)

        RequestSaveNote (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestFetchNotesForOer (Ok notes) ->
            ( { model | userNotesForOer = notes }, Cmd.none)

        RequestFetchNotesForOer (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestRemoveNote (Ok _) ->
            case model.inspectorState of
                Nothing ->
                    ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_note_delete_success") } , Cmd.none)

                Just state ->
                    ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_note_delete_success") } , requestFetchNotesForOer state.oer.id)

        RequestRemoveNote (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestUpdateNote (Ok _) ->
            case model.inspectorState of
                Nothing ->
                    ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_note_update_success") } , Cmd.none)

                Just state ->
                    ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_note_update_success"), editUserNoteForOerInPlace = Nothing } , requestFetchNotesForOer state.oer.id)

        RequestUpdateNote (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        RequestUpdatePlaylistItem (Ok _) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_playlist_item_update_success") }, requestLoadUserPlaylists )

        RequestUpdatePlaylistItem (Err err) ->
            ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_changes_not_saved_warning") }, Cmd.none )

        SetHover maybeOerId ->
            let
                ( timelineHoverState, hoveringEntityId ) =
                    case maybeOerId of
                        Nothing ->
                            ( Nothing, Nothing )

                        Just _ ->
                            ( model.timelineHoverState, model.hoveringEntityId )
            in
            ( { model | hoveringOerId = maybeOerId, timelineHoverState = timelineHoverState, hoveringEntityId = hoveringEntityId, timeOfLastMouseEnterOnCard = model.currentTime } |> unselectMention, Cmd.none )
                |> logEventForLabStudy "SetHover" [ maybeOerId |> Maybe.withDefault 0 |> String.fromInt ]

        SetPopup popup ->
            let
                newModel =
                    { model | popup = Just popup }
            in
            ( newModel, setBrowserFocus "" )
                |> logEventForLabStudy "SetPopup" (popupToStrings newModel.popup)

        ClosePopup ->
            case model.popup of
                Nothing ->
                    ( model, Cmd.none )

                Just _ ->
                    ( model |> closePopup, Cmd.none )
                        |> logEventForLabStudy "ClosePopup" []

        CloseInspector ->
            case model.inspectorState of
                Nothing ->
                    ( model, Cmd.none )

                Just _ ->
                    ( { model | inspectorState = Nothing, editingOerTitleInPlaylist = False, editingOerDescriptionInPlaylist = False }, Cmd.none )
                        |> logEventForLabStudy "CloseInspector" []

        MouseOverChunkTrigger mousePositionX ->
            ( { model | mousePositionXwhenOnChunkTrigger = mousePositionX, hoveringEntityId = Nothing } |> unselectMention, Cmd.none )
                |> logEventForLabStudy "MouseOverChunkTrigger" [ mousePositionX |> String.fromFloat ]

        --YoutubeSeekTo fragmentStart ->
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
            ( { model | userProfileFormSubmitted = True }, requestSaveUserProfile model.userProfileForm.userProfile )
                |> logEventForLabStudy "SubmittedUserProfile" []

        ChangedTextInResourceFeedbackForm oerId str ->
            ( model |> setTextInResourceFeedbackForm oerId str, Cmd.none )

        SubmittedNoteEdit ->
            case model.editUserNoteForOerInPlace of
                Nothing ->
                    ( model, Cmd.none )

                Just note ->
                    ( model, requestUpdateNote note )

        ChangedTextInNote str ->
            case model.editUserNoteForOerInPlace of
                Nothing ->
                    ( model, Cmd.none )

                Just editingNote ->
                    let
                        oldEditingNote =
                            editingNote

                        newEditingNote =
                            ( { oldEditingNote | text = str } )

                    in
                        ( { model | editUserNoteForOerInPlace = Just newEditingNote }, Cmd.none)

        SubmittedResourceFeedback oerId text ->
            ( { model | timeOfLastFeedbackRecorded = model.currentTime } |> setTextInResourceFeedbackForm oerId "", requestSaveNote oerId text)
                |> logEventForLabStudy "SubmittedResourceFeedback" [ oerId |> String.fromInt, text ]
                |> saveAction 8 [ ( "OER id", Encode.int oerId ), ( "user feedback", Encode.string text ) ]

        YoutubeVideoIsPlayingAtPosition position ->
            (model, Cmd.none)
            |> logEventForLabStudy "YoutubeVideoIsPlayingAtPosition" [ position |> String.fromFloat]

        BubblogramTopicMouseOver entityId oerId ->
            let
                popup =
                    case model.overviewType of
                        BubblogramOverview TopicNames ->
                            Just <| BubblePopup <| BubblePopupState oerId entityId DefinitionInBubblePopup []

                        _ ->
                            Nothing
            in
            ( { model | hoveringEntityId = Just entityId, popup = popup }, Cmd.none )
                |> logEventForLabStudy "BubblogramTopicMouseOver" [ oerId |> String.fromInt, entityId ]

        BubblogramTopicLabelMouseOver entityId oerId ->
            let
                popup =
                    BubblePopup <| BubblePopupState oerId entityId DefinitionInBubblePopup []
            in
            ( { model | hoveringEntityId = Just entityId, popup = Just popup }, Cmd.none )
                |> logEventForLabStudy "BubblogramTopicLabelMouseOver" [ oerId |> String.fromInt, entityId ]

        BubblogramTopicMouseOut ->
            ( { model | hoveringEntityId = Nothing } |> unselectMention |> closePopup, Cmd.none )
                |> logEventForLabStudy "BubblogramTopicMouseOut" []

        BubblogramTopicLabelClicked oerId ->
            let
                newModel =
                    { model | popup = model.popup |> updateBubblePopupOnTopicLabelClicked model oerId }
            in
            ( newModel, Cmd.none )
                |> logEventForLabStudy "BubblogramTopicLabelClicked" (popupToStrings newModel.popup)

        PageScrolled ({ scrollTop, viewHeight, contentHeight, requestedByElm } as pageScrollState) ->
            ( { model | pageScrollState = pageScrollState }, Cmd.none )
                |> logEventForLabStudy "PageScrolled"
                    [ scrollTop |> String.fromFloat
                    , viewHeight |> String.fromFloat
                    , contentHeight |> String.fromFloat
                    , if requestedByElm then
                        "elm"

                      else
                        "user"
                    ]

        OerCardPlaceholderPositionsReceived positions ->
            ( { model | oerCardPlaceholderPositions = positions }, Cmd.none )

        SelectInspectorSidebarTab tab oerId ->
            let
                cmd =
                    if tab == RecommendationsTab then
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
            ( { model | inspectorState = newInspectorState }, [ cmd, setBrowserFocus "feedbackTextInputField" ] |> Cmd.batch )
                |> logEventForLabStudy "SelectInspectorSidebarTab" [ String.fromInt oerId, tabName ]

        MouseMovedOnTopicLane mousePosXonCard ->
            case model.overviewType of
                ThumbnailOverview ->
                    ( model, Cmd.none )

                BubblogramOverview TopicNames ->
                    ( model, Cmd.none )

                _ ->
                    model
                        |> selectOrUnselectMention mousePosXonCard

        SelectedOverviewType overviewType ->
            let
                selectedMode =
                    overviewTypeId overviewType
            in
            ( { model | overviewType = overviewType, hoveringEntityId = Nothing } |> closePopup, Cmd.none )
                |> logEventForLabStudy "SelectedOverviewType" [ selectedMode ]
                |> saveAction 10 [ ( "selectedMode", Encode.string selectedMode ) ]

        SelectedPlaylist playlist ->
            let
                oerIds =
                    List.map (\x -> x) playlist.oerIds

                courseItems =
                    List.map (\x -> CourseItem x [] "") playlist.oerIds

                course =
                    Course courseItems
            in
            ( { model | playlist = Just playlist, course = course, courseOptimization = Nothing } |> closePopup, requestOersByIds model oerIds )

        MouseEnterMentionInBubbblogramOverview oerId entityId mention ->
            ( { model | selectedMention = Just ( oerId, mention ), hoveringEntityId = Just entityId } |> setBubblePopupToMention oerId entityId mention, setBrowserFocus "" )

        TimelineMouseEvent { eventName, position } ->
            case hoveringOrInspectingOer model of
                Nothing ->
                    ( model, Cmd.none )

                -- impossible
                Just oer ->
                    handleTimelineMouseEvent model oer eventName position
                        |> logEventForLabStudy "TimelineMouseEvent" [ eventName, position |> String.fromFloat ]

        TimelineMouseLeave ->
            ( { model | timelineHoverState = Nothing }, Cmd.none )

        Html5VideoStarted pos ->
            ( model |> updateVideoPlayer (Started pos) |> extendVideoUsages pos, Cmd.none )
                |> saveVideoAction 4

        Html5VideoPaused pos ->
            ( model |> updateVideoPlayer (Paused pos), Cmd.none )
                |> saveVideoAction 5

        Html5VideoSeeked pos ->
            ( model |> updateVideoPlayer (PositionChanged pos), Cmd.none )
                |> saveVideoAction 6

        Html5VideoStillPlaying pos ->
            ( model |> updateVideoPlayer (PositionChanged pos) |> extendVideoUsages pos, Cmd.none )
                |> saveVideoAction 9

        Html5VideoAspectRatio aspectRatio ->
            case model.inspectorState of
                Nothing ->
                    ( model, Cmd.none )

                Just inspectorState ->
                    case inspectorState.videoPlayer of
                        Nothing ->
                            ( model, Cmd.none )

                        Just videoPlayer ->
                            ( { model | inspectorState = Just { inspectorState | videoPlayer = Just { videoPlayer | aspectRatio = aspectRatio } } }, Cmd.none )

        StartCurrentHtml5Video pos ->
            ( model |> extendVideoUsages pos, startCurrentHtml5Video pos )
                |> logEventForLabStudy "StartCurrentHtml5Video" [ pos |> String.fromFloat ]

        ToggleContentFlow ->
            case model.session of
                Nothing ->
                    ( model, Cmd.none )

                Just session ->
                    let
                        enabled =
                            not session.isContentFlowEnabled
                    in
                    ( { model | session = Just { session | isContentFlowEnabled = enabled } }, Cmd.none )
                        |> saveAction 7 [ ( "enable", Encode.bool enabled ) ]
                        |> logEventForLabStudy "ToggleContentFlow"
                            [ if enabled then
                                "enabled"

                              else
                                "disabled"
                            ]

        ToggleExplainer ->
            let
                isExplainerEnabled =
                    not model.isExplainerEnabled

                popup =
                    if isExplainerEnabled then
                        Just ExplainerMetaInformationPopup

                    else
                        Nothing
            in
            ( { model | isExplainerEnabled = isExplainerEnabled, popup = popup }, Cmd.none )
                |> saveAction 11 [ ( "enable", Encode.bool isExplainerEnabled ) ]

        OpenExplanationPopup componentId ->
            ( { model | popup = Just <| ExplanationPopup componentId }, Cmd.none )
                |> saveAction 12 [ ( "componentId", Encode.string componentId ) ]

        AddedOerToCourse oer ->
            let
                newItem =
                    { oerId = oer.id
                    , ranges = [ Range 0 oer.durationInSeconds ]
                    , comment = ""
                    }

                oldCourse =
                    model.course

                newCourse =
                    { oldCourse | items = newItem :: oldCourse.items }
            in
            ( { model | course = newCourse, courseOptimization = Nothing }, Cmd.none )
                |> logEventForLabStudy "AddedOerToCourse" [ oer.id |> String.fromInt, courseToString newCourse ]
                |> saveCourseNow

        RemovedOerFromCourse oerId ->
            case model.playlist of
                Nothing ->
                    let
                        oldCourse =
                            model.course

                        newCourse =
                            { oldCourse | items = oldCourse.items |> List.filter (\item -> item.oerId /= oerId) }
                    in
                    ( { model | course = newCourse, courseOptimization = Nothing, inspectorState = Nothing, snackbar = createSnackbar model (t model.translations "alerts.lbl_remove_playlist_item_success") }, Cmd.none )
                        |> logEventForLabStudy "RemovedOerFromCourse" [ oerId |> String.fromInt, courseToString newCourse ]
                        |> saveCourseNow
                
                Just playlist ->
                    let
                        oldUserPlaylists = 
                            model.userPlaylists

                        oldplaylist = 
                            playlist

                        newplaylist = 
                            { oldplaylist | oerIds = List.filter (\x -> x /= oerId) oldplaylist.oerIds }

                        newUserPlaylists = 
                            (List.filter (\x -> x.title /= newplaylist.title) (Maybe.withDefault [] oldUserPlaylists)) ++ [newplaylist]

                        oldCourse =
                            model.course

                        newCourse =
                            { oldCourse | items = oldCourse.items |> List.filter (\item -> item.oerId /= oerId) }

                    in
                    ( { model | course = newCourse, playlist = Just newplaylist, userPlaylists = Just newUserPlaylists, courseOptimization = Nothing, inspectorState = Nothing, snackbar = createSnackbar model (t model.translations "alerts.lbl_remove_playlist_item_success") }, requestSavePlaylist newplaylist )
                        |> logEventForLabStudy "RemovedOerFromCourse" [ oerId |> String.fromInt, courseToString newCourse ]
                        |> saveCourseNow


        MovedCourseItemDown index ->
            let
                oldCourse =
                    model.course

                newCourse =
                    { oldCourse | items = oldCourse.items |> swapListItemWithNext index }
            in
                case model.playlist of
                    Nothing ->
                        ( { model | course = newCourse, courseOptimization = Nothing }, Cmd.none  )
                            |> logEventForLabStudy "MovedCourseItemDown" [ index |> String.fromInt, courseToString newCourse ]
                            |> saveCourseNow

                    Just playlist ->
                        let
                            updatedPlaylist =
                                Playlist playlist.id playlist.title playlist.description playlist.author playlist.creator playlist.parent playlist.is_visible playlist.license (List.map (\x -> x.oerId) newCourse.items) Nothing playlist.playlistItemData

                        in
                        ( { model | course = newCourse, courseOptimization = Nothing }, requestSavePlaylist updatedPlaylist )
                            |> logEventForLabStudy "MovedCourseItemDown" [ index |> String.fromInt, courseToString newCourse ]
                            |> saveCourseNow

        PressedOptimiseLearningPath ->
            case model.playlist of
                Nothing ->
                    ( model, Cmd.none )
            
                Just playlist ->
                    ( { model | courseOptimization = Just Loading }, [ setBrowserFocus "", requestCourseOptimization model.course playlist ] |> Cmd.batch )
                        |> logEventForLabStudy "PressedOptimiseLearningPath" []

        PressedUndoCourse savedPreviousCourse ->
            case model.playlist of
                Nothing->
                    ( { model | course = savedPreviousCourse, courseOptimization = Nothing }, Cmd.none )
                        |> logEventForLabStudy "PressedUndoCourse" [ courseToString savedPreviousCourse ]
                        |> saveCourseNow

                Just playlist ->
                    let
                        updatedPlaylist =
                            Playlist playlist.id playlist.title playlist.description playlist.author playlist.creator playlist.parent playlist.is_visible playlist.license (List.map (\x -> x.oerId) savedPreviousCourse.items) Nothing playlist.playlistItemData
                    in
                    ( { model | course = savedPreviousCourse, courseOptimization = Nothing }, requestSavePlaylist updatedPlaylist )
                        |> logEventForLabStudy "PressedUndoCourse" [ courseToString savedPreviousCourse ]
                        |> saveCourseNow

        ChangedCommentTextInCourseItem oerId str ->
            ( model |> setCommentTextInCourseItem oerId str, Cmd.none )

        SubmittedCourseItemComment ->
            ( model, setBrowserFocus "" )
                |> logEventForLabStudy "SubmittedCourseItemComment" []
                |> saveCourseNow

        StartTask taskName ->
            let
                searchText =
                    case taskName of
                        "Task 1" ->
                            "labstudytask1"

                        "Task 2" ->
                            "labstudytask2"

                        "Math" ->
                            "youtubestudy"

                        _ ->
                            "labstudypractice"

                newModel =
                    { model | currentTaskName = Just taskName, searchInputTyping = searchText, searchState = Just <| newSearch searchText, snackbar = Nothing }
            in
            ( newModel, [ setBrowserFocus "", searchOers searchText model.currentPageForSearch model.materialType model.materialLanguage ] |> Cmd.batch )
                |> logEventForLabStudy "StartTask" [ taskName ]

        CompleteTask ->
            if isLabStudy2 model then
            ( { model | currentTaskName = Nothing }, setBrowserFocus "" )
                |> logEventForLabStudy "CompleteTask" []
            else 
            ( { model | currentTaskName = Nothing, course = initialCourse }, setBrowserFocus "" )
                |> logEventForLabStudy "CompleteTask" []

        OpenedOverviewTypeMenu ->
            ( { model | popup = Just OverviewTypePopup }, setBrowserFocus "" )
                |> logEventForLabStudy "OpenedOverviewTypeMenu" []

        PressedReadMore inspectorState ->
            ( { model | inspectorState = Just { inspectorState | userPressedReadMore = True } }, Cmd.none )
                |> logEventForLabStudy "PressedReadMore" []

        ToggleDataCollectionConsent enabled ->
            let
                oldProfile =
                    userProfileForm.userProfile

                newProfile =
                    { oldProfile | isDataCollectionConsent = not enabled }

                newForm =
                    { userProfileForm | userProfile = newProfile, saved = False }
            in
            ( { model | userProfileForm = newForm }, Cmd.none )
                |> logEventForLabStudy "ToggleDataCollectionConsent"
                    [ if enabled then
                        "enable"

                      else
                        "disable"
                    ]

        -- We need to catch the click event to prevent it from bubbling up to the card and opening the inspector
        ClickedOnContentFlowBar oer position isCard ->
            ( model, Cmd.none )
                |> logEventForLabStudy "ClickedOnContentFlowBar"
                    [ oer.id |> String.fromInt
                    , position |> String.fromFloat
                    , if isCard then
                        "card"

                      else
                        "inspector"
                    ]

        PressedRemoveRangeButton oerId range ->
            ( model |> removeRangeFromCourse oerId range |> closePopup, Cmd.none )
                |> logEventForLabStudy "PressedRemoveRangeButton" [ oerId |> String.fromInt, range |> rangeToString ]

        OpenedSelectPlaylistMenu ->
            case model.popup of
                Nothing ->
                    ( { model | popup = Just PlaylistPopup }, setBrowserFocus "" )
                        |> logEventForLabStudy "OpenedPlaylistMenu" []
                
                Just PlaylistPopup ->
                    ( model |> closePopup, Cmd.none )
                        |> logEventForLabStudy "OpenedPlaylistMenu" []

                _ ->
                    ( { model | popup = Just PlaylistPopup }, setBrowserFocus "" )
                        |> logEventForLabStudy "OpenedPlaylistMenu" []

        EditPlaylist field value ->
            let
                newForm =
                    { playlistPublishForm | playlist = playlistPublishForm.playlist |> updatePlaylistField field value, published = False }
            in
            ( { model | playlistPublishForm = newForm }, Cmd.none )
                |> logEventForLabStudy "EditPlaylist" []

        SubmittedPublishPlaylist ->
            if model.playlistPublishForm.playlist.title == "" || model.playlistPublishForm.playlist.author == Just "" then
                ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_validate_publish_playlist_warning") }, Cmd.none )
            else if (List.length model.playlistPublishForm.playlist.oerIds) <= 1 then
                ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_validate_publish_playlist_min_items_warning") }, Cmd.none )
            else
                ( { model | playlistPublishFormSubmitted = True }, requestPublishPlaylist model.playlistPublishForm )
                |> logEventForLabStudy "SubmittedPublishPlaylist" []

        SubmittedCreatePlaylist ->
            case checkIfPlaylistNameIsUnique model.userPlaylists model.playlistCreateForm.playlist.title of
                False ->
                    ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_validate_unique_playlist_warning") }, Cmd.none)  
            
                True ->
                    ( { model | playlistCreateFormSubmitted = True }, requestCreatePlaylist model.playlistCreateForm.playlist )
                    |> logEventForLabStudy "SubmittedCreatePlaylist" []

        EditNewPlaylist field value ->
            let
                newForm =
                    { playlistCreateForm | playlist = playlistCreateForm.playlist |> updatePlaylistField field value, saved = False }
            in
            ( { model | playlistCreateForm = newForm }, Cmd.none )
                |> logEventForLabStudy "EditNewPlaylist" []

        OpenedAddToPlaylistMenu ->
            ( { model | popup = Just AddToPlaylistPopup }, setBrowserFocus "" )
                |> logEventForLabStudy "OpenedAddToPlaylistMenu" []

        SelectedAddToPlaylist playlist oer ->
            ( model |> closePopup, requestAddToPlaylist playlist oer )

        SavePlaylist playlist course ->
            let
                updatedPlaylist =
                    Playlist playlist.id playlist.title playlist.description playlist.author playlist.creator playlist.parent playlist.is_visible playlist.license (List.map (\x -> x.oerId) course.items) Nothing playlist.playlistItemData
            in
            ( model, requestSavePlaylist updatedPlaylist )

        DeletePlaylist playlist ->
            ( model, requestDeletePlaylist playlist )

        SelectedLicense license ->
            let
                updatedPlaylist =
                    { playlistPublishForm | playlist = playlistPublishForm.playlist |> updatePlaylistLicense license.id }
            in
            ( { model | playlistPublishForm = updatedPlaylist } |> closePopup, Cmd.none )

        OpenedSelectLicenseMenu ->
            ( { model | popup = Just SelectLicensePopup }, setBrowserFocus "" )

        SetPlaylistState playlistState ->
            case playlistState of
                Nothing ->
                    ({ model | playlistState = playlistState}, Cmd.none)

                Just PlaylistClone ->
                    if isLoggedIn model then
                        case model.publishedPlaylistId of
                            Nothing ->
                                ({ model | playlistState = playlistState}, Cmd.none)
                            Just id ->
                                case model.publishedPlaylist of
                                    Nothing ->
                                        ({ model | playlistState = playlistState}, requestFetchPublishedPlaylist id )

                                    Just publishedPlaylist ->
                                        if id == (String.fromInt (Maybe.withDefault 0 publishedPlaylist.id)) then
                                            ({ model | playlistState = playlistState}, Cmd.none)
                                        else
                                            ({ model | playlistState = playlistState}, requestFetchPublishedPlaylist id )
                    else
                        ( { model | snackbar = createSnackbar model (t model.translations "alerts.lbl_prompt_login") }, Cmd.none )

                _ ->
                    case model.publishedPlaylistId of
                        Nothing ->
                            ({ model | playlistState = playlistState}, Cmd.none)
                        Just id ->
                            case model.publishedPlaylist of
                                Nothing ->
                                    ({ model | playlistState = playlistState}, requestFetchPublishedPlaylist id )

                                Just publishedPlaylist ->
                                    if id == (String.fromInt (Maybe.withDefault 0 publishedPlaylist.id)) then
                                        ({ model | playlistState = playlistState}, Cmd.none)
                                    else
                                        ({ model | playlistState = playlistState}, requestFetchPublishedPlaylist id )

        CancelCreatePlaylist ->
            ( model , Navigation.load "/" )

        EditNoteForOer note ->
            ( { model | editUserNoteForOerInPlace = Just note }, Cmd.none )

        RemoveNoteForOer noteId ->
            ( model, requestRemoveNote noteId )

        PromptDeletePlaylist flag ->
            ( { model | promptedDeletePlaylist = flag }, Cmd.none)

        ClickedOnPlaylistItem oer ->
            model
            |> update (InspectOer oer 0 False "ClickedOnPlaylistItem")
            |> logEventForLabStudy "ClickedOnPlaylistItem" [ oer.id |> String.fromInt ]

        EditOerInPlaylist flag editType ->
            if editType == "title" then
                ( { model | editingOerTitleInPlaylist = flag }, [ setBrowserFocus "editingOerTitle", registerInspectorPlaylistEvents True ] |> Cmd.batch )
            else
                ( { model | editingOerDescriptionInPlaylist = flag }, [ setBrowserFocus "editingOerDescription", registerInspectorPlaylistEvents True ] |> Cmd.batch )

        UpdatePlaylistItem editType str ->
            if editType == "title" then
                let

                    oldPlaylistItem =
                        model.editingOerPlaylistItem

                    newPlaylistItem =
                        { oldPlaylistItem | title = str }

                in
                ( { model | editingOerPlaylistItem = newPlaylistItem }, Cmd.none )
            else
                let

                    oldPlaylistItem =
                        model.editingOerPlaylistItem

                    newPlaylistItem =
                        { oldPlaylistItem | description = str }

                in
                ( { model | editingOerPlaylistItem = newPlaylistItem }, Cmd.none )

        SubmittedPlaylistItemUpdate ->
            case model.playlist of
                Nothing ->
                 (model, Cmd.none)

                Just playlist ->
                    ( { model | editingOerTitleInPlaylist = False, editingOerDescriptionInPlaylist = False }, requestUpdatePlaylistItem playlist.title model.editingOerPlaylistItem )

        SetSearchCurrentPage pageNumber ->
            case model.searchState of
                Nothing ->
                 ( model, Cmd.none )
                
                Just searchState ->
                     ( { model | currentPageForSearch = pageNumber }, Navigation.load ("/search?q=" ++ searchState.lastSearchText ++ "&page=" ++ String.fromInt pageNumber) )

        OpenedLanguageSelectorMenu ->
            ( { model | popup = Just LanguagePopup }, setBrowserFocus "" )
                |> logEventForLabStudy "OpenedLanguageSelectorMenu" []

        ChangeLanguage lang ->
            ( { model | language = lang }, Navigation.load ("/?lang=" ++ lang))
            
        StopEditingPlaylist flag ->
            ( { model | editingOerTitleInPlaylist = False, editingOerDescriptionInPlaylist = False }, Cmd.none )

        OpenedSelectSearchMaterialType ->
            case model.popup of
                Nothing ->
                    ( { model | popup = Just SearchMaterialTypePopup }, setBrowserFocus "" )
                        |> logEventForLabStudy "OpenedSearchMaterialTypePopup" []
                
                Just SearchMaterialTypePopup ->
                    ( model |> closePopup, Cmd.none )
                        |> logEventForLabStudy "OpenedSearchMaterialTypePopup" []

                _ ->
                    ( { model | popup = Just SearchMaterialTypePopup }, setBrowserFocus "" )
                        |> logEventForLabStudy "OpenedSearchMaterialTypePopup" []
                

        SelectedMaterialTypeForSearch materialType ->
            ( { model | materialType = materialType } |> closePopup, Cmd.none )

        OpenedSelectSearchMaterialLanguage ->
            case model.popup of
                Nothing ->
                    ( { model | popup = Just SearchMaterialLanguagePopup }, setBrowserFocus "" )
                        |> logEventForLabStudy "OpenedSearchMaterialLanguagePopup" []
                
                Just SearchMaterialLanguagePopup ->
                    ( model |> closePopup, Cmd.none )
                        |> logEventForLabStudy "OpenedSearchMaterialLanguagePopup" []

                _ ->
                    ( { model | popup = Just SearchMaterialLanguagePopup }, setBrowserFocus "" )
                        |> logEventForLabStudy "OpenedSearchMaterialTypePopup" []
                

        SelectedMaterialLanguageForSearch materialLanguage ->
            ( { model | materialLanguage = materialLanguage } |> closePopup, Cmd.none )


insertSearchResults : List OerId -> Model -> Model
insertSearchResults oerIds model =
    let
        newSearchState =
            case model.searchState of
                Nothing ->
                    Nothing

                -- impossible
                Just searchState ->
                    Just { searchState | searchResults = Just oerIds }
    in
    { model | searchState = newSearchState }


incrementFrameCountInInspectorAnimation : Model -> Model
incrementFrameCountInInspectorAnimation model =
    case model.inspectorAnimation of
        Nothing ->
            model

        Just animation ->
            { model | inspectorAnimation = Just { animation | frameCount = animation.frameCount + 1 } }


requestWikichunkEnrichmentsIfNeeded : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
requestWikichunkEnrichmentsIfNeeded ( model, oldCmd ) =
    if model.requestingWikichunkEnrichments || (model.wikichunkEnrichmentRequestFailCount > 0 && (model.currentTime |> posixToMillis) < (model.wikichunkEnrichmentRetryTime |> posixToMillis)) then
        ( model, oldCmd )

    else
        let
            missing =
                model.cachedOers
                    |> Dict.keys
                    |> List.filter (\oerId -> Dict.member oerId model.wikichunkEnrichments |> not)
        in
        if List.isEmpty missing then
            ( model, oldCmd )

        else
            ( model, [ oldCmd, requestWikichunkEnrichments missing ] |> Cmd.batch )


requestOersByIds : Model -> List OerId -> Cmd Msg
requestOersByIds model oerIds =
    oerIds
        |> List.filter (\oerId -> isOerLoaded model oerId |> not)
        |> requestOers


requestEntityDefinitionsIfNeeded : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
requestEntityDefinitionsIfNeeded ( oldModel, oldCmd ) =
    if oldModel.requestingEntityDefinitions then
        ( oldModel, oldCmd )

    else
        let
            newModel =
                { oldModel | requestingEntityDefinitions = True }

            missingEntities =
                oldModel.entityDefinitions
                    |> Dict.filter (\_ definition -> definition == DefinitionScheduledForLoading)
                    |> Dict.keys
                    |> List.take 50

            -- arbitrary pagination
        in
        if List.isEmpty missingEntities then
            ( oldModel, oldCmd )

        else
            ( newModel, [ oldCmd, requestEntityDefinitions missingEntities ] |> Cmd.batch )


registerUndefinedEntities : List WikichunkEnrichment -> Model -> Model
registerUndefinedEntities enrichments model =
    let
        entityDefinitions =
            enrichments
                |> uniqueEntitiesFromEnrichments
                |> List.map .id
                |> List.foldl
                    (\entityId output ->
                        if model.entityDefinitions |> Dict.member entityId then
                            output

                        else
                            output |> Dict.insert entityId DefinitionScheduledForLoading
                    )
                    model.entityDefinitions
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


updatePlaylistLicense : Int -> Playlist -> Playlist
updatePlaylistLicense id playlist =
    { playlist | license = Just id }


updatePlaylistField : PlaylistField -> String -> Playlist -> Playlist
updatePlaylistField field value playlist =
    case field of
        Title ->
            { playlist | title = value }

        Description ->
            { playlist | description = Just value }

        Author ->
            { playlist | author = Just value }


cacheOersFromList : List Oer -> Model -> Model
cacheOersFromList oers model =
    let
        oersDict =
            oers
                |> List.foldl (\oer output -> output |> Dict.insert oer.id oer) Dict.empty
    in
    { model | cachedOers = Dict.union oersDict model.cachedOers }


inspectOerBasedOnUrlParameter : Model -> ( Model, Cmd Msg )
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
            ( model, Cmd.none )

        Just oerId ->
            case model.cachedOers |> Dict.get oerId of
                Nothing ->
                    ( model, Cmd.none )

                Just oer ->
                    model
                        |> update (InspectOer oer 0 False "inspectOerBasedOnUrlParameter")


setTextInResourceFeedbackForm : OerId -> String -> Model -> Model
setTextInResourceFeedbackForm oerId str model =
    { model | feedbackForms = model.feedbackForms |> Dict.insert oerId str }


updateBubblogramsIfNeeded : Model -> Model
updateBubblogramsIfNeeded model =
    { model | wikichunkEnrichments = model.wikichunkEnrichments |> Dict.map (addBubblogram model) }


logEventForLabStudy : String -> List String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
logEventForLabStudy eventType params ( model, cmd ) =
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
        ( { model | loggedEvents = logString :: model.loggedEvents }, cmd )

    else
        ( model, cmd )


popupToStrings : Maybe Popup -> List String
popupToStrings maybePopup =
    case maybePopup of
        Nothing ->
            []

        Just popup ->
            case popup of
                ContentFlowPopup { barId, oer, chunk, entityPopup } ->
                    let
                        entityIdStr =
                            case entityPopup of
                                Nothing ->
                                    ""

                                Just { entityId } ->
                                    entityId
                    in
                    [ "ContentFlowPopup", barId, oer.url, chunk.entities |> List.map .id |> String.join ",", entityIdStr ]

                UserMenu ->
                    [ "UserMenu" ]

                BubblePopup { oerId, entityId, content } ->
                    let
                        contentString =
                            case content of
                                DefinitionInBubblePopup ->
                                    "Definition"

                                MentionInBubblePopup { positionInResource, sentence } ->
                                    "Mention " ++ (positionInResource |> String.fromFloat) ++ " " ++ sentence
                    in
                    [ oerId |> String.fromInt, entityId, contentString ]

                OverviewTypePopup ->
                    [ "OverviewTypePopup" ]

                ExplanationPopup componentId ->
                    [ "ExplanationPopup", componentId ]

                ExplainerMetaInformationPopup ->
                    [ "ExplainerMetaInformationPopup" ]

                LoginHintPopup ->
                    [ "LoginHintPopup" ]

                PopupAfterClickedOnContentFlowBar oer position isCard maybeRange ->
                    [ "PopupAfterClickedOnContentFlowBar"
                    , position |> String.fromFloat
                    , if isCard then
                        "card"

                      else
                        "inspector"
                    , if maybeRange == Nothing then
                        "Clicked on empty space"

                      else
                        "Clicked on range"
                    ]

                PlaylistPopup ->
                    [ "PlaylistPopup" ]

                AddToPlaylistPopup ->
                    [ "AddToPlaylistPopup" ]

                SelectLicensePopup ->
                    [ "SelectLicensePopup" ]

                LanguagePopup ->
                    [ "LanguagePopup" ]

                SearchMaterialTypePopup ->
                    [ "SearchMaterialTypePopup" ]

                SearchMaterialLanguagePopup ->
                    [ "SearchMaterialLanguagePopup" ]


executeSearchAfterUrlChanged : Model -> Url -> ( Model, Cmd Msg )
executeSearchAfterUrlChanged model url =
    let
        textParam =
            url.query
                |> Maybe.withDefault ""
                |> String.dropLeft 2
                -- TODO A much cleaner method is to use Url.Query.parser
                |> String.split "&"
                |> List.head
                |> Maybe.withDefault ""
                |> Url.percentDecode
                |> Maybe.withDefault ""

        pageNo = 
            url.query
                |> Maybe.withDefault ""
                |> String.dropLeft 2
                |> String.split "&"
                |> List.reverse
                |> List.head
                |> Maybe.withDefault ""
                |> String.split "="
                |> List.reverse
                |> List.head
                |> Maybe.withDefault ""
                |> String.toInt
                |> Maybe.withDefault 1
                
        -- when searching by ID, don't change the value in the input field
        -- see issue #298
        searchInputTyping =
            case textParam |> String.toInt of
                Nothing ->
                    textParam

                Just _ ->
                    model.searchInputTyping

        isPlaylist =
            searchIsPlaylist textParam

        playlistId =
            if isPlaylist then
                extractPlaylistIdFromSearchString textParam
            else
                Nothing

        newModel =
            { model | currentPageForSearch = pageNo, searchInputTyping = searchInputTyping, searchState = Just <| newSearch textParam, snackbar = Nothing, searchIsPlaylist = isPlaylist, publishedPlaylistId = playlistId, playlistState = Nothing }
    in
    ( newModel |> closePopup, searchOers textParam pageNo model.materialType model.materialLanguage )
        |> logEventForLabStudy "executeSearchAfterUrlChanged" [ textParam ]


saveVideoAction : Int -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
saveVideoAction actionTypeId ( model, oldCmd ) =
    case model.inspectorState of
        Nothing ->
            ( model, oldCmd )

        -- impossible
        Just { oer, videoPlayer } ->
            case videoPlayer of
                Nothing ->
                    ( model, oldCmd )

                -- impossible
                Just { currentTime } ->
                    ( model, oldCmd )
                        |> saveAction actionTypeId [ ( "oerId", Encode.int oer.id ), ( "positionInSeconds", Encode.float currentTime ) ]


saveAction : Int -> List ( String, Encode.Value ) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
saveAction actionTypeId params ( model, oldCmd ) =
    if isLoggedIn model then
        ( model, [ oldCmd, ActionApi.saveAction actionTypeId params ] |> Cmd.batch )

    else
        ( model, oldCmd )


createSnackbar : Model -> String -> Maybe Snackbar
createSnackbar model str =
    Just <| Snackbar model.currentTime str


updateSnackbar : Model -> Maybe Snackbar
updateSnackbar model =
    case model.snackbar of
        Nothing ->
            Nothing

        Just snackbar ->
            if millisSince model snackbar.startTime > snackbarDuration then
                Nothing

            else
                Just snackbar


snackbarMessageReloadPage : String
snackbarMessageReloadPage =
    "There was a problem - please reload the page"


unselectMention : Model -> Model
unselectMention model =
    { model | selectedMention = Nothing }


selectOrUnselectMention : Float -> Model -> ( Model, Cmd Msg )
selectOrUnselectMention mousePosXonCard model =
    let
        unselect =
            ( model |> unselectMention, setBrowserFocus "" )
                |> logEventForLabStudy "UnselectMention" []
    in
    case model.hoveringEntityId of
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
                                |> List.filter (\{ positionInResource } -> abs (positionInResource - mousePosXonCard) < 0.05)
                                |> List.sortBy (\{ positionInResource } -> abs (positionInResource - mousePosXonCard))
                                |> List.head
                    in
                    case closestMentionInRange of
                        Nothing ->
                            unselect

                        Just mention ->
                            ( { model | selectedMention = Just ( oerId, mention ), hoveringEntityId = Just entityId } |> setBubblePopupToMention oerId entityId mention, setBrowserFocus "" )
                                |> logEventForLabStudy "SelectMention" [ oerId |> String.fromInt, mousePosXonCard |> String.fromFloat, mention.positionInResource |> String.fromFloat, mention.sentence ]


type VideoPlayerMsg
    = Started Float
    | Paused Float
    | PositionChanged Float
    | Duration Float


updateVideoPlayer : VideoPlayerMsg -> Model -> Model
updateVideoPlayer msg model =
    case model.inspectorState of
        Nothing ->
            model

        -- impossible
        Just inspectorState ->
            case inspectorState.videoPlayer of
                Nothing ->
                    model

                -- impossible
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
            model

        -- impossible
        Just { oer } ->
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
                    Range pos videoPlayReportingInterval :: oldRanges
            in
            { model | videoUsages = Dict.insert oer.id newRanges model.videoUsages }


courseToString : Course -> String
courseToString { items } =
    let
        itemToString item =
            "{oerId: " ++ String.fromInt item.oerId ++ ", ranges: [" ++ (item.ranges |> List.map rangeToString |> String.join ", ") ++ "], comment: \"" ++ item.comment ++ "\"}"

        itemsAsString =
            items
                |> List.map itemToString
                |> String.join ", "
    in
    "{items: [" ++ itemsAsString ++ "]}"


rangeToString : Range -> String
rangeToString range =
    "{start: " ++ (range.start |> String.fromFloat) ++ ", end: " ++ (range.start + range.length |> String.fromFloat) ++ "}"


getCourseRangeAtPosition : Model -> Oer -> Float -> Maybe Range
getCourseRangeAtPosition model oer position01 =
    let
        maybeCourseItem =
            model.course.items
                |> List.filter (\item -> item.oerId == oer.id)
                |> List.head
    in
    case maybeCourseItem of
        Nothing ->
            Nothing

        Just item ->
            item.ranges
                |> List.filter (\range -> isNumberInRange (position01 * oer.durationInSeconds) range)
                |> List.head


addRangeToCourse : Oer -> Float -> Float -> Model -> Model
addRangeToCourse oer dragStartPosition dragEndPosition ({ course } as model) =
    let
        duration =
            oer.durationInSeconds

        range =
            { start = dragStartPosition * duration
            , length = (dragEndPosition - dragStartPosition) * duration
            }
                |> invertRangeIfNeeded

        maybeCourseItem =
            course.items
                |> List.filter (\item -> item.oerId == oer.id)
                |> List.head

        newItems =
            case maybeCourseItem of
                Nothing ->
                    -- add a newly created CourseItem to the Course
                    { oerId = oer.id, ranges = [ range ], comment = "" } :: course.items

                Just courseItem ->
                    -- change an existing CourseItem
                    course.items
                        |> List.map
                            (\item ->
                                if item.oerId == courseItem.oerId then
                                    { item | ranges = range :: item.ranges }

                                else
                                    item
                            )
    in
    { model | course = { course | items = newItems } }
        |> markCourseAsChanged


removeRangeFromCourse : OerId -> Range -> Model -> Model
removeRangeFromCourse oerId range ({ course } as model) =
    let
        maybeCourseItem =
            course.items
                |> List.filter (\item -> item.oerId == oerId)
                |> List.head

        newItems =
            case maybeCourseItem of
                Nothing ->
                    -- impossible
                    course.items

                Just courseItem ->
                    course.items
                        |> List.map
                            (\item ->
                                if item.oerId == courseItem.oerId then
                                    { item | ranges = item.ranges |> List.filter (\r -> r /= range) }

                                else
                                    item
                            )
                        |> List.filter (\item -> item.ranges |> List.isEmpty |> not)

        -- remove the item from the course if the user deletes the last range
    in
    { model | course = { course | items = newItems } }
        |> markCourseAsChanged


setCommentTextInCourseItem : OerId -> String -> Model -> Model
setCommentTextInCourseItem oerId str model =
    let
        oldCourse =
            model.course

        newItems =
            oldCourse.items
                |> List.map
                    (\item ->
                        if item.oerId == oerId then
                            { item | comment = str }

                        else
                            item
                    )

        newCourse =
            { oldCourse | items = newItems }
    in
    { model | course = newCourse, courseOptimization = Nothing } |> markCourseAsChanged


saveCourseIfNeeded : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
saveCourseIfNeeded ( oldModel, oldCmd ) =
    if oldModel.courseNeedsSaving && millisSince oldModel oldModel.lastTimeCourseChanged > 2000 then
        ( oldModel, oldCmd )
            |> saveCourseNow

    else
        ( oldModel, oldCmd )


saveCourseNow : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
saveCourseNow ( oldModel, oldCmd ) =
    ( oldModel, [ requestSaveCourse oldModel.course, oldCmd ] |> Cmd.batch )


markCourseAsChanged : Model -> Model
markCourseAsChanged model =
    { model | courseNeedsSaving = True, courseChangesSaved = False, lastTimeCourseChanged = model.currentTime }


saveLoggedEventsIfNeeded : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
saveLoggedEventsIfNeeded ( oldModel, oldCmd ) =
    if oldModel.loggedEvents /= [] && millisSince oldModel oldModel.timeWhenSessionLoaded > 10000 && millisSince oldModel oldModel.lastTimeLoggedEventsSaved > 5000 then
        ( { oldModel | loggedEvents = [], lastTimeLoggedEventsSaved = oldModel.currentTime }, [ requestSaveLoggedEvents oldModel, oldCmd ] |> Cmd.batch )

    else
        ( oldModel, oldCmd )


{-| Number of seconds between HTTP requests to report the ongoing
video play position.
Keep this constant in sync with the JavaScript constant (same name)
and VIDEO\_PLAY\_REPORTING\_INTERVAL in python
-}
videoPlayReportingInterval : Float
videoPlayReportingInterval =
    10


inspectOer : Model -> Oer -> Float -> Bool -> ( Model, Cmd Msg )
inspectOer model oer fragmentStart playWhenReady =
    let
        videoEmbedParams : VideoEmbedParams
        videoEmbedParams =
            { inspectorId = inspectorId
            , videoId = getYoutubeVideoId oer.url |> Maybe.withDefault ""
            , videoStartPosition = fragmentStart * oer.durationInSeconds
            , playWhenReady = playWhenReady
            }
    in
        ( { model | inspectorState = Just <| newInspectorState oer fragmentStart, animationsPending = model.animationsPending |> Set.insert inspectorId, hoveringOerId = Nothing } |> closePopup, Cmd.batch [ requestFetchNotesForOer oer.id, openInspectorAnimation videoEmbedParams, embedYoutubePlayerOnResourcePage videoEmbedParams] 
        )


showLoginHintIfNeeded : Model -> Model
showLoginHintIfNeeded model =
    { model
        | popup =
            if isLoggedIn model then
                Nothing

            else
                Just LoginHintPopup
    }


handleTimelineMouseEvent : Model -> Oer -> String -> Float -> ( Model, Cmd Msg )
handleTimelineMouseEvent model oer eventName position =
    case eventName of
        "mousedown" ->
            { model | timelineHoverState = Just { position = position, mouseDownPosition = Just position } }
                |> noCmd

        "mouseup" ->
            case model.timelineHoverState of
                Nothing ->
                    -- ignore
                    model
                        |> noCmd

                Just { mouseDownPosition } ->
                    case mouseDownPosition of
                        Nothing ->
                            -- ignore
                            model
                                |> noCmd

                        Just dragStartPos ->
                            if (position - dragStartPos |> abs) < 0.01 then
                                -- Click without horizontal dragging -> open the popup
                                { model
                                    | timelineHoverState = Nothing
                                    , popup = Just <| PopupAfterClickedOnContentFlowBar oer position (isHovering model oer) (getCourseRangeAtPosition model oer position)
                                }
                                    |> noCmd

                            else
                                -- Click with horizontal dragging -> add the range to the course
                                let
                                    newModel =
                                        { model | timelineHoverState = Just { position = position, mouseDownPosition = Nothing } }
                                            |> addRangeToCourse oer dragStartPos position
                                in
                                newModel
                                    |> noCmd
                                    |> logEventForLabStudy "DragRange" [ oer.id |> String.fromInt, dragStartPos |> String.fromFloat, position |> String.fromFloat, courseToString newModel.course ]

        "mousemove" ->
            case model.timelineHoverState of
                Nothing ->
                    { model | timelineHoverState = Just { position = position, mouseDownPosition = Nothing } }
                        |> noCmd

                Just timelineHoverState ->
                    let
                        mouseDownPosition =
                            if isLabStudy1 model then
                                timelineHoverState.mouseDownPosition

                            else
                                Nothing

                        -- if the user isn't a labstudy participant, then they cannot drag ranges. We achieve this by pretending they didn't hold the mouse button down.
                    in
                    { model | timelineHoverState = Just { position = position, mouseDownPosition = mouseDownPosition } }
                        |> noCmd

        _ ->
            -- impossible
            model
                |> noCmd


noCmd : Model -> ( Model, Cmd Msg )
noCmd model =
    ( model, Cmd.none )


filterPlaylistByText : List Playlist -> Playlist -> Playlist
filterPlaylistByText playlists playlist =
    let
        matches =
            List.filter (\x -> x.title == playlist.title) playlists
    in
    case List.head matches of
        Nothing ->
            Playlist Nothing "" Nothing Nothing Nothing Nothing True Nothing [] Nothing []

        Just firstMatch ->
            firstMatch


searchIsPlaylist : String -> Bool
searchIsPlaylist searchText =
    if searchText |> String.startsWith "pl:" then
        True

    else
        False


extractPlaylistIdFromSearchString : String -> Maybe String
extractPlaylistIdFromSearchString searchText =
    case List.tail (searchText |> String.split ":") of
        Nothing ->
            Nothing
    
        Just id ->
            List.head (List.reverse (searchText |> String.split ":"))


countOfUserPlaylists : Maybe (List Playlist) -> Int
countOfUserPlaylists playlists =
    case playlists of
        Nothing ->
            0
    
        Just pl ->
            List.length pl

checkIfPlaylistNameIsUnique : Maybe (List Playlist) -> String -> Bool
checkIfPlaylistNameIsUnique playlists newPlaylistTitle = 
    case playlists of
        Nothing ->
            True
    
        Just pl ->
            let
                matches =
                    List.head (List.filter (\x -> x.title == newPlaylistTitle) pl)
            in
                case matches of
                    Nothing ->
                        True

                    Just _ ->
                        False

getPlaylistTitle : Model -> OerId -> Maybe String
getPlaylistTitle model oerId =
  case model.playlist of 
    Nothing ->
      Nothing

    Just playlist ->
      let

        playlistItemData =
          List.head ( List.filter (\x -> x.oerId == oerId ) playlist.playlistItemData)

      in
        case playlistItemData of
            Nothing ->
              Nothing
                
            Just itemData ->
              Just itemData.title

getPlaylistDescription : Model -> OerId -> Maybe String
getPlaylistDescription model oerId =
  case model.playlist of 
    Nothing ->
      Nothing

    Just playlist ->
      let

        playlistItemData =
          List.head ( List.filter (\x -> x.oerId == oerId ) playlist.playlistItemData)

      in
        case playlistItemData of
            Nothing ->
              Nothing
                
            Just itemData ->
              Just itemData.description
            
    
            
    