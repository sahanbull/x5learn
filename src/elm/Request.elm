module Request exposing (requestSession, searchOers, requestGains, requestWikichunkEnrichments, requestSearchSuggestions, requestEntityDefinitions, requestSaveUserProfile, requestOers, requestLabStudyLogEvent, requestResource, requestResourceRecommendations, requestSendResourceFeedback)

import Set exposing (Set)
import Dict exposing (Dict)
import Time exposing (millisToPosix, posixToMillis)

import Http exposing (expectStringResponse)
import Json.Decode as Decode exposing (Value,map,map2,map3,map4,map5,map8,field,bool,int,float,string,list,dict,oneOf,maybe,null)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as Encode
import Url
import Url.Builder

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


requestSearchSuggestions : String -> Cmd Msg
requestSearchSuggestions searchText =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "search_suggestions/" ] [ Url.Builder.string "text" searchText ]
    , expect = Http.expectJson RequestSearchSuggestions (list string)
    }


requestOers : Set OerId -> Cmd Msg
requestOers ids =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "oers/" ] []
    , body = Http.jsonBody <| Encode.object [ ("ids", (Encode.list Encode.int) (ids |> Set.toList)) ]
    , expect = Http.expectJson RequestOers (list oerDecoder)
    }


requestGains : Cmd Msg
requestGains =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "gains/" ] []
    , expect = Http.expectJson RequestGains (list gainDecoder)
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


requestLabStudyLogEvent : Int -> String -> List String -> Cmd Msg
requestLabStudyLogEvent time eventType params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "log_event_for_lab_study/" ] []
    , body = Http.jsonBody <| Encode.object [ ("browserTime", Encode.int time), ("eventType", Encode.string eventType), ("params", Encode.list Encode.string params) ]
    , expect = Http.expectString RequestLabStudyLogEvent
    }


requestResource : Int -> Cmd Msg
requestResource oerId =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "resource/" ] []
    , body = Http.jsonBody <| Encode.object [ ("oerId", Encode.int oerId) ]
    , expect = Http.expectJson RequestResource oerDecoder
    }


requestResourceRecommendations : String -> Cmd Msg
requestResourceRecommendations searchText =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "search/" ] [ Url.Builder.string "text" searchText ]
    , expect = Http.expectJson RequestResourceRecommendations (list oerDecoder)
    }


requestSendResourceFeedback : Int -> String -> Cmd Msg
requestSendResourceFeedback oerId text =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "resource_feedback/" ] []
    , body = Http.jsonBody <| Encode.object [ ("oerId", Encode.int oerId), ("text", Encode.string text) ]
    , expect = Http.expectString RequestSendResourceFeedback
    }


sessionDecoder =
  oneOf
    [ field "loggedInUser" loggedInUserDecoder
    , field "guestUser" guestUserDecoder
    ]


loggedInUserDecoder =
  map (\userProfile -> Session (LoggedInUser userProfile))
    (field "userProfile" userProfileDecoder)


guestUserDecoder =
  map (\_ -> Session GuestUser)
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


gainDecoder =
  map3 Gain
    (field "title" string)
    (field "level" float)
    (field "confidence" float)


searchResultsDecoder =
  list oerDecoder


oerDecoder =
  Decode.succeed Oer
  |> andMap (field "id" int)
  |> andMap (field "date" string)
  |> andMap (field "description" string)
  |> andMap (field "duration" string)
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
