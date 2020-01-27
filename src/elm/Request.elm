module Request exposing (requestSession, searchOers, requestFeaturedOers, requestWikichunkEnrichments, requestEntityDefinitions, requestSaveUserProfile, requestOers, requestVideoUsages, requestLoadCourse, requestSaveCourse, requestSaveLoggedEvents, requestResourceRecommendations)

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
searchOers : String -> Cmd Msg
searchOers searchText =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "search/" ] [ Url.Builder.string "text" searchText ]
    , expect = Http.expectJson RequestOerSearch (list oerDecoder)
    }


-- requestFavorites : Cmd Msg
-- requestFavorites =
--   Http.get
--     { url = Url.Builder.absolute [ apiRoot, "favorites/" ] []
--     , expect = Http.expectJson RequestFavorites (list int)
--     }


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
    { url = Url.Builder.absolute [ apiRoot, "video_usages" ] []
    , expect = Http.expectJson RequestVideoUsages (dict (list rangeDecoder))
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
    , ("range", rangeEncoder item.range)
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
    (field "range" rangeDecoder)
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
    , map2 initialUserProfile
        (field "email" string)
        (field "isDataCollectionConsent" bool)
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
