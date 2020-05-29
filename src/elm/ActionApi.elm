module ActionApi exposing (saveAction)

{-| This module is responsible for talking to the Actions API.
    At the time of writing, this communication is one-way.
    We are only SAVING raw actions.
    We haven't had a use case for LOADING raw actions so far.
    The actions type IDs (1,2,3...) are documented in app.py
-}


import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, at, field, list, string, int)

import Url
import Url.Builder

import Http

import Msg exposing (..)
import Model exposing (OerId)


{-| API endpoint see app.py
-}
apiRoot : String
apiRoot =
  "api/v1/action/"


{-| Send a user action to the server.
    The actions type IDs (1,2,3...) are documented in app.py
-}
saveAction : Int -> List (String, Encode.Value) -> Cmd Msg
saveAction actionTypeId params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot ] []
    , body = Http.jsonBody <| object [ ("action_type_id", Encode.int actionTypeId), ("is_bundled", Encode.bool False), ("params", object params |> encode 0 |> Encode.string) ]
    , expect = Http.expectJson RequestSaveAction (field "result" string)
    }
