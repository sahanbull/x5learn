module Request exposing (requestSession, searchOers, requestNextSteps, requestViewedFragments, requestGains, requestEntityDescriptions, requestSearchSuggestions, requestSaveUserProfile)

import Http exposing (expectStringResponse)
import Json.Decode exposing (Value,map,map2,map3,map8,field,bool,int,float,string,list,dict,oneOf,maybe,nullable)
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


requestNextSteps : Cmd Msg
requestNextSteps =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "next_steps/" ] []
    , expect = Http.expectJson RequestNextSteps (list pathwayDecoder)
    }


requestViewedFragments : Cmd Msg
requestViewedFragments =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "viewed_fragments/" ] []
    , expect = Http.expectJson RequestViewedFragments (list fragmentDecoder)
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
    -- [ ("email", Encode.string userProfile.email)
    [ ("firstName", Encode.string userProfile.firstName)
    , ("lastName", Encode.string userProfile.lastName)
    ]


sessionDecoder =
  oneOf
    [ map LoggedInUser (field "loggedIn" userProfileDecoder)
    , map Guest (field "guest" string)
    ]


userProfileDecoder =
  map3 UserProfile
    (field "email" string)
    (field "firstName" string)
    (field "lastName" string)


gainDecoder =
  map3 Gain
    (field "title" string)
    (field "level" float)
    (field "confidence" float)


fragmentDecoder =
  map3 Fragment
    (field "oer" oerDecoder)
    (field "start" float)
    (field "length" float)


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
  Json.Decode.succeed Oer
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
