module Request exposing (requestSession, searchOers, requestGains, requestEntityDescriptions, requestSearchSuggestions, requestSaveUserProfile, requestSaveUserState, requestOers)

import Set exposing (Set)
import Dict exposing (Dict)
import Time exposing (millisToPosix, posixToMillis)

import Http exposing (expectStringResponse)
import Json.Decode as Decode exposing (Value,map,map2,map3,map8,field,bool,int,float,string,list,dict,oneOf,maybe,null)
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
    , expect = Http.expectJson RequestOerSearch searchResultsDecoder
    }


requestSearchSuggestions : String -> Cmd Msg
requestSearchSuggestions searchText =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "search_suggestions/" ] [ Url.Builder.string "text" searchText ]
    , expect = Http.expectJson RequestSearchSuggestions (list string)
    }


-- requestNextSteps : Cmd Msg
-- requestNextSteps =
--   Http.get
--     { url = Url.Builder.absolute [ apiRoot, "next_steps/" ] []
--     , expect = Http.expectJson RequestNextSteps (list pathwayDecoder)
--     }


requestOers : Set String -> Cmd Msg
requestOers urls =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "oers/" ] []
    -- , body = Http.jsonBody <| (Encode.list Encode.string) (urls |> Set.toList)
    -- , body = Http.jsonBody <| Encode.object [ "urls", (urls |> Set.toList) ]
    , body = Http.jsonBody <| Encode.object [ ("urls", (Encode.list Encode.string) (urls |> Set.toList)) ]
    , expect = Http.expectJson RequestOers (dict oerDecoder)
    }


requestGains : Cmd Msg
requestGains =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "gains/" ] []
    , expect = Http.expectJson RequestGains (list gainDecoder)
    }


requestEntityDescriptions : List String -> Cmd Msg
requestEntityDescriptions entityIds =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "entity_descriptions/" ] [ Url.Builder.string "ids" (entityIds |> String.join ",") ]
    , expect = Http.expectJson RequestEntityDescriptions (dict string)
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


requestSaveUserState : UserState -> Cmd Msg
requestSaveUserState userState =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "save_user_state/" ] []
    , body = Http.jsonBody <| userStateEncoder userState
    , expect = Http.expectString RequestSaveUserState
    }


userStateEncoder : UserState -> Encode.Value
userStateEncoder userState =
  Encode.object
    [ ("viewedFragments", (Encode.list fragmentEncoder) userState.viewedFragments )
    , ("oerNoteboards", dictEncoder (Encode.list noteEncoder) userState.oerNoteboards)
    ]


fragmentEncoder : Fragment -> Encode.Value
fragmentEncoder fragment =
  Encode.object
    [ ("oerUrl", Encode.string fragment.oerUrl)
    , ("start", Encode.float fragment.start)
    , ("length", Encode.float fragment.length)
    ]


noteEncoder : Note -> Encode.Value
noteEncoder note =
  Encode.object
    [ ("text", Encode.string note.text)
    , ("time", Encode.int (note.time |> posixToMillis))
    ]


sessionDecoder =
  oneOf
    [ field "loggedInUser" loggedInUserDecoder
    , field "guestUser" guestUserDecoder
    ]


loggedInUserDecoder =
  map2 (\userState userProfile -> Session userState (LoggedInUser userProfile))
    (field "userState" userStateDecoder)
    (field "userProfile" userProfileDecoder)


guestUserDecoder =
  map (\userState -> Session userState GuestUser)
    (field "userState" userStateDecoder)


userStateDecoder =
  oneOf
    [ null initialUserState
    , map2 UserState
        (field "viewedFragments" (list fragmentDecoder))
        (field "oerNoteboards" (dict noteboardDecoder))
    ]


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


fragmentDecoder =
  map3 Fragment
    (field "oerUrl" string)
    (field "start" float)
    (field "length" float)


noteboardDecoder =
  list noteDecoder


noteDecoder =
  map2 (\text time -> Note text (millisToPosix time))
    (field "text" string)
    (field "time" int)


pathwayDecoder =
  map2 Pathway
    (field "rationale" string)
    (field "fragments" (list fragmentDecoder))


playlistDecoder =
  map2 Playlist
    (field "title" string)
    (field "oers" (list oerDecoder))


searchResultsDecoder =
  list oerDecoder


oerDecoder =
  Decode.succeed Oer
  |> andMap (field "date" string)
  |> andMap (field "description" string)
  |> andMap (field "duration" string)
  |> andMap (field "images" (list string))
  |> andMap (field "provider" string)
  |> andMap (field "title" string)
  |> andMap (field "url" string)
  |> andMap (field "wikichunks" (list chunkDecoder))
  |> andMap (field "mediatype" string)


chunkDecoder =
  map3 Chunk
    (field "start" float)
    (field "length" float)
    (field "entities" (list entityDecoder))


entityDecoder =
  map3 Entity
    (field "id" string)
    (field "title" string)
    (field "url" string)


-- X5GON
-- EXAMPLE JSON RESPONSE
-- "url" : "http://videolectures.net/kdd2016_tran_mobile_phones/",
-- "provider" : "Videolectures.NET",
-- "audioType" : false,
-- "description" : "Sensor based activity recognition is a critical component of\r\nmobile phone based applications aimed at driving detection.\r\nCurrent methodologies consist of hand-engineered features\r\ninput into discriminative models, and experiments to date\r\nhave been restricted to small scale studies of O(10) users.\r\nHere we show how convolutional neural networks can be\r\nused to learn features from raw and spectrogram sensor time\r\nseries collected from the phone accelerometer and gyroscope.\r\nWhile with limited training data such an approach under\r\nperforms existing models, we show that convolutional neural\r\nnetworks outperform currently used discriminative models\r\nwhen the training dataset size is sufficiently large. We also\r\ntest performance of the model implemented on the Android\r\nplatform and we validate our methodology using sensor data\r\ncollected from over 2000 mobile phone users.",
-- "weight" : 0.196078980584288,
-- "language" : "eng",
-- "title" : "Deep learning for driving detection on mobile phones",
-- "type" : "video",
-- "textType" : false,
-- "videoType" : true


dictEncoder enc dict =
  Dict.toList dict
    |> List.map (\(k,v) -> (k, enc v))
    |> Encode.object
