module ActionApi exposing (saveAction)

import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, at, field, list, string, int)

import Url
import Url.Builder

import Http

import Msg exposing (..)
import Model exposing (OerId)


apiRoot : String
apiRoot =
  "api/v1/action/"


-- action type IDs (1, 2, 3, ...) see app.py

saveAction : Int -> List (String, Encode.Value) -> Cmd Msg
saveAction actionTypeId params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot ] []
    , body = Http.jsonBody <| object [ ("action_type_id", Encode.int actionTypeId), ("params", object params |> encode 0 |> Encode.string) ]
    , expect = Http.expectJson RequestSaveAction (field "result" string)
    }
