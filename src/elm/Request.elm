module Request exposing (searchOers, requestNextSteps, requestViewedFragments, requestEntityDescriptions)

import Http exposing (expectStringResponse)
import Json.Decode exposing (Value,map,map2,map3,map8,field,bool,int,float,string,list,dict,oneOf,maybe,nullable)
import Json.Decode.Extra exposing (andMap)
import Json.Encode
import Url
import Url.Builder

import Debug exposing (log)

import Model exposing (..)

import Msg exposing (..)


apiRoot =
  "api/v1"


searchOers : String -> Cmd Msg
searchOers searchText =
  let
      encoded =
        Url.Builder.absolute [ apiRoot, "search" ] [ Url.Builder.string "url" "https://platform.x5gon.org/materialUrl", Url.Builder.string "text" searchText ]
  in
      Http.get
        { url = encoded
        , expect = Http.expectJson RequestOerSearch searchResultsDecoder
        }


requestNextSteps : Cmd Msg
requestNextSteps =
  let
      encoded =
        Url.Builder.absolute [ apiRoot, "next_steps" ] []
  in
      Http.get
        { url = encoded
        , expect = Http.expectJson RequestNextSteps (list pathwayDecoder)
        }


requestViewedFragments : Cmd Msg
requestViewedFragments =
  let
      encoded =
        Url.Builder.absolute [ apiRoot, "viewed_fragments" ] []
  in
      Http.get
        { url = encoded
        , expect = Http.expectJson RequestViewedFragments (list fragmentDecoder)
        }


requestEntityDescriptions : List String -> Cmd Msg
requestEntityDescriptions entityIds =
  let
      encoded =
        Url.Builder.absolute [ apiRoot, "entity_descriptions/" ] [ Url.Builder.string "ids" (entityIds |> String.join ",") ]
  in
      Http.get
        { url = encoded
        , expect = Http.expectJson RequestEntityDescriptions (dict string)
        }


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
