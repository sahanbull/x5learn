module OerSearch exposing (searchOers)

import Http exposing (expectStringResponse)
import Json.Decode exposing (Value,map,map2,map3,map6,field,bool,int,float,string,list,dict,oneOf,maybe,nullable)
import Json.Encode
import Url
import Url.Builder
-- import Debug

import Model exposing (..)

import Msg exposing (..)


apiRoot =
  "api/v1"


searchOers : String -> Cmd Msg
searchOers searchText =
  let
      encoded =
        Url.Builder.absolute [ apiRoot, "search" ] [ Url.Builder.string "url" "https://platform.x5gon.org/materialUrl", Url.Builder.string "text" searchText ]
        -- |> Debug.log "search encoded "
  in
      Http.get
        { url = encoded
        , expect = Http.expectJson RequestOerSearch searchResultsDecoder
        }


searchResultsDecoder =
  list searchResultDecoder


searchResultDecoder =
  map6 Oer
    (field "url" string)
    (field "provider" string)
    (field "title" string)
    (field "description" string)
    (field "imageUrls" (list string))
    (field "youtubeVideoVersions" (dict string))

-- X5GON
-- searchResultDecoder =
--   map3 Oer
--     (field "title" string)
--     (field "url" string)
--     (field "videoType" bool)

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
