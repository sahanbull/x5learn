module ActionApi exposing (saveAction, requestRecentViews)

import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, at, field, list, string, int)

import Url
import Url.Builder

import Http

import Msg exposing (..)
import Model exposing (OerId)


apiRoot =
  "api/v1/action/"


-- action type IDs
-- 1 = view, i.e. open card in inspector
-- 2 = mark as favorite
-- 3 = unmark favorite
-- NB keep this list in sync with the backend
saveAction : Int -> List (String, Encode.Value) -> Cmd Msg
saveAction actionTypeId params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot ] []
    , body = Http.jsonBody <| object [ ("action_type_id", Encode.int actionTypeId), ("params", object params |> encode 0 |> Encode.string) ]
    , expect = Http.expectJson RequestSaveAction (field "result" string)
    }


requestRecentViews : Cmd Msg
requestRecentViews =
  Http.get
    { url = Url.Builder.absolute [ apiRoot ] [ Url.Builder.int "action_type_id" 1 ]
    , expect = Http.expectJson RequestRecentViews (list recentViewDecoder)
    }


recentViewDecoder : Decoder OerId
recentViewDecoder =
  (field "params" (field "oerId" int))
