module Request exposing (requestSession, searchOers, requestFeaturedOers, requestWikichunkEnrichments, requestEntityDefinitions, requestSaveUserProfile, requestOers, requestLabStudyLogEvent, requestVideoUsages, requestLoadCourse, requestSaveCourse)--, requestUpdatePlayingVideo) --requestResource, requestResourceRecommendations, requestSendResourceFeedback, requestFavorites)

import Set exposing (Set)
import Dict exposing (Dict)
import Time exposing (millisToPosix, posixToMillis)

import Http exposing (expectStringResponse)
import Json.Decode as Decode exposing (Value,map,map2,map3,map4,map5,map8,field,bool,int,float,string,list,dict,oneOf,maybe,null)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as Encode
import Url
import Url.Builder
import List.Extra

import Model exposing (..)

import Msg exposing (..)


apiRoot =
  "api/v1"


requestSession : Cmd Msg
requestSession =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "session/" ] []
    , expect = Http.expectJson RequestSession sessionDecoder
    }


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


requestFeaturedOers : Cmd Msg
requestFeaturedOers =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "featured/" ] []
    , expect = Http.expectJson RequestFeatured (list oerDecoder)
    }


requestWikichunkEnrichments : List OerId -> Cmd Msg
requestWikichunkEnrichments ids =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "wikichunk_enrichments/" ] []
    , body = Http.jsonBody <| Encode.object [ ("ids", (Encode.list Encode.int) ids) ]
    , expect = Http.expectJson RequestWikichunkEnrichments (list wikichunkEnrichmentDecoder)
    }


requestEntityDefinitions : List String -> Cmd Msg
requestEntityDefinitions entityIds =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "entity_definitions/" ] [ Url.Builder.string "ids" (entityIds |> String.join ",") ]
    , expect = Http.expectJson RequestEntityDefinitions (dict string)
    }


requestSaveUserProfile : UserProfile -> Cmd Msg
requestSaveUserProfile userProfile =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "save_user_profile/" ] []
    , body = Http.jsonBody <| userProfileEncoder userProfile
    , expect = Http.expectString RequestSaveUserProfile
    }


userProfileEncoder : UserProfile -> Encode.Value
userProfileEncoder userProfile =
  Encode.object
    [ ("email", Encode.string userProfile.email)
    , ("firstName", Encode.string userProfile.firstName)
    , ("lastName", Encode.string userProfile.lastName)
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


requestLabStudyLogEvent : Int -> String -> List String -> Cmd Msg
requestLabStudyLogEvent time eventType params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "log_event_for_lab_study/" ] []
    , body = Http.jsonBody <| Encode.object [ ("browserTime", Encode.int time), ("eventType", Encode.string eventType), ("params", Encode.list Encode.string params) ]
    , expect = Http.expectString RequestLabStudyLogEvent
    }


requestLoadCourse : Cmd Msg
requestLoadCourse =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "load_course/" ] []
    , body = Http.jsonBody <| Encode.object []
    , expect = Http.expectJson RequestLoadCourse courseDecoder
    }


requestSaveCourse : Course -> Cmd Msg
requestSaveCourse course =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "save_course/" ] []
    , body = Http.jsonBody <| Encode.object [ ("items", Encode.list courseItemEncoder course.items) ]
    , expect = Http.expectString RequestSaveCourse
    }


-- requestUpdatePlayingVideo : Float -> Cmd Msg
-- requestUpdatePlayingVideo currentTimeInVideo =
--   Http.post
--     { url = Url.Builder.absolute [ apiRoot, "playing_video/" ] []
--     , body = Http.jsonBody <| Encode.object [ ("currentTimeInVideo", Encode.float currentTimeInVideo) ]
--     , expect = Http.expectString RequestUpdatePlayingVideo
--     }


-- requestResource : Int -> Cmd Msg
-- requestResource oerId =
--   Http.post
--     { url = Url.Builder.absolute [ apiRoot, "resource/" ] []
--     , body = Http.jsonBody <| Encode.object [ ("oerId", Encode.int oerId) ]
--     , expect = Http.expectJson RequestResource oerDecoder
--     }


-- requestResourceRecommendations : OerId -> Cmd Msg
-- requestResourceRecommendations oerId =
--   Http.get
--     { url = Url.Builder.absolute [ apiRoot, "recommendations/" ] [ Url.Builder.int "oerId" oerId ]
--     , expect = Http.expectJson RequestResourceRecommendations (list oerDecoder)
--     }


-- requestSendResourceFeedback : Int -> String -> Cmd Msg
-- requestSendResourceFeedback oerId text =
--   Http.post
--     { url = Url.Builder.absolute [ apiRoot, "resource_feedback/" ] []
--     , body = Http.jsonBody <| Encode.object [ ("oerId", Encode.int oerId), ("text", Encode.string text) ]
--     , expect = Http.expectString RequestSendResourceFeedback
--     }


requestVideoUsages : Cmd Msg
requestVideoUsages =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "video_usages" ] []
    , expect = Http.expectJson RequestVideoUsages (dict (list rangeDecoder))
    }


courseItemDecoder =
  map3 CourseItem
    (field "oerId" int)
    (field "range" rangeDecoder)
    (field "comment" string)


courseDecoder =
  map Course
    (field "items" (list courseItemDecoder))


rangeDecoder =
  map2 Range
    (field "start" float)
    (field "length" float)


sessionDecoder =
  oneOf
    [ field "loggedInUser" loggedInUserDecoder
    , field "guestUser" guestUserDecoder
    ]


loggedInUserDecoder =
  map2 (\userProfile isContentFlowEnabled -> Session (LoggedInUser userProfile) isContentFlowEnabled)
    (field "userProfile" userProfileDecoder)
    (field "isContentFlowEnabled" bool)


guestUserDecoder =
  map (\_ -> Session GuestUser True)
    string


userProfileDecoder =
  oneOf
    [ map3 UserProfile
        (field "email" string)
        (field "firstName" string)
        (field "lastName" string)
    , map initialUserProfile
        (field "email" string)
    ]


searchResultsDecoder =
  list oerDecoder


oerDecoder =
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


wikichunkEnrichmentDecoder =
  map5 (WikichunkEnrichment Nothing)
    (field "mentions" (dict (list mentionDecoder)))
    (field "chunks" (list chunkDecoder))
    (field "clusters" (list clusterDecoder))
    (field "errors" bool)
    (field "oerId" int)


clusterDecoder =
  list string


mentionDecoder =
  map2 MentionInOer
    (field "positionInResource" float)
    (field "sentence" string)


chunkDecoder =
  map4 Chunk
    (field "start" float)
    (field "length" float)
    (field "entities" (list entityDecoder))
    (field "text" string)


entityDecoder =
  map3 Entity
    (field "id" string)
    (field "title" string)
    (field "url" string)
