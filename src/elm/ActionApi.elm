module ActionApi exposing (saveAction, requestRecentViews)

import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, at, field, list, string)

import Url
import Url.Builder

import Http

import Msg exposing (..)


apiRoot =
  "api/v1/action/"


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
    { url = Url.Builder.absolute [ apiRoot ] [ Url.Builder.int "action_type_id" actionTypeForWhenTheUserOpensAnOerCard ]
    , expect = Http.expectJson RequestRecentViews (list recentViewDecoder)
    }


recentViewDecoder : Decoder String
recentViewDecoder =
  (field "params" (field "oerUrl" string))


actionTypeForWhenTheUserOpensAnOerCard =
  1 -- TODO think of a scalable and maintainable way to share action types with the backend
