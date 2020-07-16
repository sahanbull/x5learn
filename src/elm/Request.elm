module Request exposing (requestSession, searchOers, requestFeaturedOers, requestWikichunkEnrichments, requestEntityDefinitions, requestSaveUserProfile, requestOers, requestVideoUsages, requestLoadCourse, requestSaveCourse, requestSaveLoggedEvents, requestResourceRecommendations, requestCourseOptimization, requestLoadUserPlaylists, requestCreatePlaylist, requestAddToPlaylist, requestSavePlaylist, requestDeletePlaylist, requestLoadLicenseTypes, requestPublishPlaylist, requestFetchPublishedPlaylist, requestSaveNote, requestSaveReview, requestFetchNotesForOer, requestFetchReviewsForOer, requestRemoveNote, requestRemoveReview,  requestUpdateNote, requestUpdateReview, requestUpdatePlaylistItem)

import Set exposing (Set)
import Dict exposing (Dict)
import Time exposing (millisToPosix, posixToMillis)

import Http exposing (expectStringResponse)
import Json.Decode as Decode exposing (Decoder,Value,map,map2,map3,map4,map5,map8,field,bool,int,float,string,list,dict,oneOf,maybe,null)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as Encode
import Url
import Url.Builder
import List.Extra

import Model exposing (..)

import Msg exposing (..)


{-| This module is responsible for most of the data fetching via JSON GET/POST requests.
-}
apiRoot =
  "api/v1"


{-| Fetch the current user (logged in or not)
-}
requestSession : Cmd Msg
requestSession =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "session/" ] []
    , expect = Http.expectJson RequestSession sessionDecoder
    }


{-| Fetch OER search results from the backend
-}
searchOers : String -> Int -> Cmd Msg
searchOers searchText page =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "search/" ] [ Url.Builder.string "text" searchText, Url.Builder.int "page" page ]
    , expect = Http.expectJson RequestOerSearch oerSearchResultDecoder
    }


{-| Fetch OER data from the server.
-}
requestOers : List OerId -> Cmd Msg
requestOers oerIds =
  let
      uniqueOerIds =
        oerIds
        |> List.Extra.unique
  in
      Http.post
        { url = Url.Builder.absolute [ apiRoot, "oers/" ] []
        , body = Http.jsonBody <| Encode.object [ ("ids", (Encode.list Encode.int) oerIds) ]
        , expect = Http.expectJson RequestOers (list oerDecoder)
        }


{-| Fetch featured Oers from the backend.
-}
requestFeaturedOers : Cmd Msg
requestFeaturedOers =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "featured/" ] []
    , expect = Http.expectJson RequestFeatured (list oerDecoder)
    }


{-| Fetch enrichment data from the backend
-}
requestWikichunkEnrichments : List OerId -> Cmd Msg
requestWikichunkEnrichments ids =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "wikichunk_enrichments/" ] []
    , body = Http.jsonBody <| Encode.object [ ("ids", (Encode.list Encode.int) ids) ]
    , expect = Http.expectJson RequestWikichunkEnrichments (list wikichunkEnrichmentDecoder)
    }


{-| Fetch entity definitions from the backend
-}
requestEntityDefinitions : List String -> Cmd Msg
requestEntityDefinitions entityIds =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "entity_definitions/" ] [ Url.Builder.string "ids" (entityIds |> String.join ",") ]
    , expect = Http.expectJson RequestEntityDefinitions (dict string)
    }


{-| Persist the user profile data when the user submits the form
-}
requestSaveUserProfile : UserProfile -> Cmd Msg
requestSaveUserProfile userProfile =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "save_user_profile/" ] []
    , body = Http.jsonBody <| userProfileEncoder userProfile
    , expect = Http.expectString RequestSaveUserProfile
    }


{-| Fetch course data
-}
requestLoadCourse : Cmd Msg
requestLoadCourse =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "load_course/" ] []
    , body = Http.jsonBody <| Encode.object []
    , expect = Http.expectJson RequestLoadCourse courseDecoder
    }


{-| Persist changes in the course
-}
requestSaveCourse : Course -> Cmd Msg
requestSaveCourse course =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "save_course/" ] []
    , body = Http.jsonBody <| Encode.object [ ("items", Encode.list courseItemEncoder course.items) ]
    , expect = Http.expectString RequestSaveCourse
    }


{-| Persist UI events
-}
requestSaveLoggedEvents : Model -> Cmd Msg
requestSaveLoggedEvents {currentTime, loggedEvents} =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "save_ui_logged_events_batch/" ] []
    , body = Http.jsonBody <| Encode.object [ ("clientTime", Encode.string (currentTime |> posixToMillis |> String.fromInt)), ("text", Encode.string (loggedEvents |> List.reverse |> String.join "\n")) ]
    , expect = Http.expectString RequestSaveLoggedEvents
    }


{-| Fetch related resources in full-page resource view
-}
requestResourceRecommendations : OerId -> Cmd Msg
requestResourceRecommendations oerId =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "recommendations/" ] [ Url.Builder.int "oerId" oerId ]
    , expect = Http.expectJson RequestResourceRecommendations (list oerDecoder)
    }


{-| Fetch data regarding which parts of videos the user has watched
-}
requestVideoUsages : Cmd Msg
requestVideoUsages =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "video_usages/" ] []
    , expect = Http.expectJson RequestVideoUsages (dict (list rangeDecoder))
    }


{-| Fetch data regarding which parts of videos the user has watched
-}
requestCourseOptimization : Course -> Playlist -> Cmd Msg
requestCourseOptimization course playlist =
  let
      oerIds =
        course.items |> List.map .oerId
  in
      Http.post
        { url = Url.Builder.absolute [ apiRoot, "course_optimization/" ++ playlist.title ] [ ]
        , body = Http.jsonBody <| Encode.object [ ("oerIds", Encode.list Encode.int oerIds) ]
        , expect = Http.expectJson RequestCourseOptimization (list int)
        }


{-| Fetch user playlist data
-}
requestLoadUserPlaylists : Cmd Msg
requestLoadUserPlaylists =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "playlist/" ] [ Url.Builder.string "mode" "temp_playlists_only" ]
    , expect = Http.expectJson RequestLoadUserPlaylists (list playlistDecoder)
    }

{-| Persist the newly created playlist
-}
requestCreatePlaylist : Playlist -> Cmd Msg
requestCreatePlaylist playlist =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "playlist/" ] []
    , body = Http.jsonBody <| playlistEncoder playlist
    , expect = Http.expectString RequestCreatePlaylist
    }

{-| Persist oer in playlist
-}
requestAddToPlaylist : Playlist -> Oer -> Cmd Msg
requestAddToPlaylist playlist oer =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "playlist/" ++ playlist.title ] []
    , body = Http.jsonBody <| Encode.object [ ("oer_id", Encode.int oer.id ) ]
    , expect = Http.expectString RequestAddToPlaylist
    }


{-| Persist playlist in database
-}
requestSavePlaylist : Playlist -> Cmd Msg
requestSavePlaylist playlist =
  Http.request
    { method = "PUT"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "playlist/" ++ playlist.title ] []
    , body = Http.jsonBody <| playlistEncoder playlist
    , expect = Http.expectString RequestSavePlaylist
    }

requestDeletePlaylist : Playlist -> Cmd Msg
requestDeletePlaylist playlist =
  Http.request
    { method = "DELETE"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "playlist/" ++ playlist.title ] []
    , body = Http.jsonBody <| playlistEncoder playlist
    , expect = Http.expectString RequestDeletePlaylist
    }

requestLoadLicenseTypes : Cmd Msg
requestLoadLicenseTypes = 
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "license/" ] []
    , expect = Http.expectJson RequestLoadLicenseTypes (list licenseTypeDecoder)
    }

{-| publish a temporary playlist
-}
requestPublishPlaylist : PublishPlaylistForm -> Cmd Msg
requestPublishPlaylist publishPlaylistForm = 
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "playlist/" ] []
    , body = Http.jsonBody <| publishPlaylistEncoder publishPlaylistForm
    , expect = Http.expectString RequestPublishPlaylist
    }

{-| fetch a published playlist
-}
requestFetchPublishedPlaylist : String -> Cmd Msg
requestFetchPublishedPlaylist playlistId =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "playlist/" ++ playlistId ] []
    , expect = Http.expectJson RequestFetchPublishedPlaylist playlistDecoder
    }  


{-| save a user note attached to a oer
-}
requestSaveNote : OerId -> String -> Cmd Msg
requestSaveNote oerId text =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "note/" ] []
    , body = Http.jsonBody <| Encode.object [ ("oer_id", Encode.int oerId), ("text", Encode.string text) ]
    , expect = Http.expectString RequestSaveNote
    }


{-| fetch notes of a user given a oer id
-}
requestFetchNotesForOer : OerId -> Cmd Msg
requestFetchNotesForOer oerId =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "note/" ] [ Url.Builder.int "oer_id" oerId, Url.Builder.string "sort" "asc" ]
    , expect = Http.expectJson RequestFetchNotesForOer (list noteDecoder)
    }  

{-| delete a note attached to an oer
-}
requestRemoveNote : Int -> Cmd Msg
requestRemoveNote noteId = 
  Http.request
    { method = "DELETE"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "note/" ++ String.fromInt noteId ] []
    , body = Http.jsonBody <| Encode.object []
    , expect = Http.expectString RequestRemoveNote
    }

{-| update a note attached to an oer
-}
requestUpdateNote : Note -> Cmd Msg
requestUpdateNote note = 
  Http.request
    { method = "PUT"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "note/" ++ String.fromInt note.id ] [ Url.Builder.string "text" note.text ]
    , body = Http.jsonBody <| Encode.object []
    , expect = Http.expectString RequestUpdateNote
    }


{-| save a user review for a oer
-}
requestSaveReview : OerId -> String -> Cmd Msg
requestSaveReview oerId text =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "review/" ] []
    , body = Http.jsonBody <| Encode.object [ ("oer_id", Encode.int oerId), ("text", Encode.string text) ]
    , expect = Http.expectString RequestSaveReview
    }


{-| fetch reviews of an oer
-}
requestFetchReviewsForOer : OerId -> Cmd Msg
requestFetchReviewsForOer oerId =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "review/" ] [ Url.Builder.int "oer_id" oerId, Url.Builder.string "sort" "asc" ]
    , expect = Http.expectJson RequestFetchReviewsForOer (list noteDecoder)
    }  


{-| delete a review attached to an oer
-}
requestRemoveReview : Int -> Cmd Msg
requestRemoveReview reviewId = 
  Http.request
    { method = "DELETE"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "review/" ++ String.fromInt reviewId ] []
    , body = Http.jsonBody <| Encode.object []
    , expect = Http.expectString RequestRemoveReview
    }


{-| update a review of an oer
-}
requestUpdateReview : Review -> Cmd Msg
requestUpdateReview review = 
  Http.request
    { method = "PUT"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "review/" ++ String.fromInt review.id ] [ Url.Builder.string "text" review.text ]
    , body = Http.jsonBody <| Encode.object []
    , expect = Http.expectString RequestUpdateReview
    }


requestUpdatePlaylistItem : String -> PlaylistItem -> Cmd Msg
requestUpdatePlaylistItem playlistTitle playlistItem = 
  Http.request
    { method = "PUT"
    , timeout = Nothing
    , tracker = Nothing
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, "playlist/" ++ playlistTitle ] []
    , body = Http.jsonBody <| Encode.object [ ( "playlist_item_data", playlistItemEncoder playlistItem) ] 
    , expect = Http.expectString RequestUpdatePlaylistItem
    }

{-| JSON decoders and encoders for custom types are defined below.
-}
userProfileEncoder : UserProfile -> Encode.Value
userProfileEncoder userProfile =
  Encode.object
    [ ("email", Encode.string userProfile.email)
    , ("firstName", Encode.string userProfile.firstName)
    , ("lastName", Encode.string userProfile.lastName)
    , ("isDataCollectionConsent", Encode.bool userProfile.isDataCollectionConsent)
    ]


courseItemEncoder : CourseItem -> Encode.Value
courseItemEncoder item =
  Encode.object
    [ ("oerId", Encode.int item.oerId)
    , ("ranges", Encode.list rangeEncoder item.ranges)
    , ("comment", Encode.string item.comment)
    ]

  
rangeEncoder : Range -> Encode.Value
rangeEncoder range =
  Encode.object
    [ ("start", Encode.float range.start)
    , ("length", Encode.float range.length)
    ]


courseItemDecoder : Decoder CourseItem
courseItemDecoder =
  map3 CourseItem
    (field "oerId" int)
    (field "ranges" (list rangeDecoder))
    (field "comment" string)


courseDecoder : Decoder Course
courseDecoder =
  map Course
    (field "items" (list courseItemDecoder))


rangeDecoder : Decoder Range
rangeDecoder =
  map2 Range
    (field "start" float)
    (field "length" float)


sessionDecoder : Decoder Session
sessionDecoder =
  oneOf
    [ field "loggedInUser" loggedInUserDecoder
    , field "guestUser" guestUserDecoder
    ]


loggedInUserDecoder : Decoder Session
loggedInUserDecoder =
  map3 (\userProfile isContentFlowEnabled overviewTypeId -> Session (LoggedInUser userProfile) isContentFlowEnabled overviewTypeId)
    (field "userProfile" userProfileDecoder)
    (field "isContentFlowEnabled" bool)
    (field "overviewTypeId" string)


guestUserDecoder : Decoder Session
guestUserDecoder =
  map (\_ -> Session GuestUser True "")
    string


userProfileDecoder : Decoder UserProfile
userProfileDecoder =
  oneOf
    [ map4 UserProfile
        (field "email" string)
        (field "firstName" string)
        (field "lastName" string)
        (field "isDataCollectionConsent" bool)
    , map initialUserProfile
        (field "email" string)
    ]


searchResultsDecoder : Decoder (List Oer)
searchResultsDecoder =
  list oerDecoder


oerDecoderWithTranslations : Decoder Oer
oerDecoderWithTranslations =
  Decode.succeed Oer
  |> andMap (field "id" int)
  |> andMap (field "date" string)
  |> andMap (field "description" string)
  |> andMap (field "duration" string)
  |> andMap (field "durationInSeconds" float)
  |> andMap (field "images" (list string))
  |> andMap (field "provider" string)
  |> andMap (field "title" string)
  |> andMap (field "url" string)
  |> andMap (field "mediatype" string)
  |> andMap (field "translations" (dict string))


oerDecoderWithoutTranslations : Decoder Oer
oerDecoderWithoutTranslations =
  Decode.succeed (\a b c d e f g h i j -> Oer a b c d e f g h i j Dict.empty)
  |> andMap (field "id" int)
  |> andMap (field "date" string)
  |> andMap (field "description" string)
  |> andMap (field "duration" string)
  |> andMap (field "durationInSeconds" float)
  |> andMap (field "images" (list string))
  |> andMap (field "provider" string)
  |> andMap (field "title" string)
  |> andMap (field "url" string)
  |> andMap (field "mediatype" string)


oerDecoder : Decoder Oer
oerDecoder =
  oneOf
    [ oerDecoderWithTranslations
    , oerDecoderWithoutTranslations
    ]


wikichunkEnrichmentDecoder : Decoder WikichunkEnrichment
wikichunkEnrichmentDecoder =
  map5 (WikichunkEnrichment Nothing)
    (field "mentions" (dict (list mentionDecoder)))
    (field "chunks" (list chunkDecoder))
    (field "clusters" (list clusterDecoder))
    (field "errors" bool)
    (field "oerId" int)


clusterDecoder : Decoder Cluster
clusterDecoder =
  list string


mentionDecoder : Decoder MentionInOer
mentionDecoder =
  map2 MentionInOer
    (field "positionInResource" float)
    (field "sentence" string)


chunkDecoder : Decoder Chunk
chunkDecoder =
  map4 Chunk
    (field "start" float)
    (field "length" float)
    (field "entities" (list entityDecoder))
    (field "text" string)


entityDecoder : Decoder Entity
entityDecoder =
  map3 Entity
    (field "id" string)
    (field "title" string)
    (field "url" string)

playlistDecoder : Decoder Playlist
playlistDecoder = 
  Decode.succeed Playlist
  |> andMap (Decode.maybe (Decode.field "id" Decode.int))
  |> andMap (field "title" string)
  |> andMap (Decode.maybe (Decode.field "description" Decode.string))
  |> andMap (Decode.maybe (Decode.field "author" Decode.string))
  |> andMap (Decode.maybe (Decode.field "creator" Decode.int))
  |> andMap (Decode.maybe (Decode.field "parent" Decode.int))
  |> andMap (Decode.field "is_visible" Decode.bool)
  |> andMap (Decode.maybe (Decode.field "license" Decode.int))
  |> andMap (field "oerIds" (list Decode.int))
  |> andMap (Decode.maybe (Decode.field "url" Decode.string))
  |> andMap (field "playlistItemData" (list playlistItemDecoder))


playlistEncoder : Playlist -> Encode.Value
playlistEncoder playlist =
  Encode.object
    [ ("id", Encode.int (Maybe.withDefault 0 playlist.id))
    , ("title", Encode.string playlist.title)
    , ("description", Encode.string (Maybe.withDefault "" playlist.description))
    , ("author", Encode.string (Maybe.withDefault "" playlist.author))
    , ("creator", Encode.int (Maybe.withDefault 0 playlist.creator))
    , ("parent", Encode.int (Maybe.withDefault 0 playlist.parent))
    , ("is_visible", Encode.bool True)
    , ("license", Encode.int (Maybe.withDefault 1 playlist.license))
    , ("is_temp", Encode.bool True)
    , ("playlist_items", Encode.list Encode.int playlist.oerIds)
    , ("playlist_item_data", Encode.list playlistItemEncoder playlist.playlistItemData)
    ]

playlistItemEncoder : PlaylistItem -> Encode.Value
playlistItemEncoder playlistItem =
  Encode.object
    [ ("oerId", Encode.int playlistItem.oerId)
    , ("title", Encode.string playlistItem.title)
    , ("description", Encode.string playlistItem.description)
    ]

playlistItemDecoder : Decoder PlaylistItem
playlistItemDecoder = 
  map3 PlaylistItem
    (field "oerId" int)
    (field "title" string)
    (field "description" string)

licenseTypeDecoder : Decoder LicenseType
licenseTypeDecoder = 
  map3 LicenseType
    (field "id" int)
    (field "description" string)
    (field "url" (maybe string))

publishPlaylistEncoder : PublishPlaylistForm -> Encode.Value
publishPlaylistEncoder publishPlaylistForm =
  Encode.object
    [ ("id", Encode.int (Maybe.withDefault 0 publishPlaylistForm.playlist.id))
    , ("title", Encode.string publishPlaylistForm.playlist.title)
    , ("description", Encode.string (Maybe.withDefault "" publishPlaylistForm.playlist.description))
    , ("author", Encode.string (Maybe.withDefault "" publishPlaylistForm.playlist.author))
    , ("creator", Encode.int (Maybe.withDefault 0 publishPlaylistForm.playlist.creator))
    , ("parent", Encode.int (Maybe.withDefault 0 publishPlaylistForm.playlist.parent))
    , ("is_visible", Encode.bool True)
    , ("license", Encode.int (Maybe.withDefault 1 publishPlaylistForm.playlist.license))
    , ("is_temp", Encode.bool False)
    , ("playlist_items", Encode.list Encode.int publishPlaylistForm.playlist.oerIds)
    , ("temp_title", Encode.string publishPlaylistForm.originalTitle)
    ]

noteDecoder : Decoder Note
noteDecoder = 
  map2 Note
    (field "id" int)
    (field "text" string)


oerSearchResultDecoder : Decoder OerSearchResult
oerSearchResultDecoder = 
  Decode.succeed OerSearchResult
  |> andMap (field "oers" (list oerDecoder))
  |> andMap (field "total_pages" int)
  |> andMap (field "current_page" int)