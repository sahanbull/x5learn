module ActionApi exposing (saveAction)

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
-- 4 = video started at position (second / percentage)
-- NB keep this list in sync with the backend

-- NB It would have been nice to be able to use the Actions API for all the video events.
-- However, using a custom model turned out more practical and efficient for the frontend needs.
-- At the time of writing this, the frontend needs a list of visited fragments for each OER.
-- These fragments need to expand as the video plays (or the pdf scrolls).
-- The Actions API doesn't afford this kind of updating, hence the need for a custom model.
-- We can still use the Actions API for logging, e.g. play and pause actions.

saveAction : Int -> List (String, Encode.Value) -> Cmd Msg
saveAction actionTypeId params =
  Http.post
    { url = Url.Builder.absolute [ apiRoot ] []
    , body = Http.jsonBody <| object [ ("action_type_id", Encode.int actionTypeId), ("params", object params |> encode 0 |> Encode.string) ]
    , expect = Http.expectJson RequestSaveAction (field "result" string)
    }
