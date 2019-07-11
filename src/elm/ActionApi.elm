module ActionApi exposing (save)

import Json.Encode as Encode exposing (..)
import Json.Decode exposing (field, string)

import Url
import Url.Builder

import Http

import Msg exposing (..)


apiRoot =
  "api/v1/action"



save : Int -> List (String, Encode.Value) -> Cmd Msg
save actionTypeId params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "" ] []
    , body = Http.jsonBody <| object [ ("action_type_id", int actionTypeId), ("params", object params |> encode 0 |> Encode.string) ]
    , expect = Http.expectJson RequestSaveAction (field "result" string)
    }
