module NotesApi exposing (saveNote, requestNotes)

import Time exposing (millisToPosix)

import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, map3, at, field, list, string, int)
import Json.Decode.Extra exposing (datetime)

import Url
import Url.Builder

import Http

import Msg exposing (..)
import Model exposing (..)


apiRoot =
  "api/v1/note/"


saveNote : OerId -> String -> Cmd Msg
saveNote oerId text =
  Http.post
    { url = Url.Builder.absolute [ apiRoot ] []
    , body = Http.jsonBody <| object [ ("oer_id", Encode.int oerId), ("text", Encode.string text) ]
    , expect = Http.expectJson RequestSaveNote (field "result" string)
    }


requestNotes : Cmd Msg
requestNotes =
  Http.get
    { url = Url.Builder.absolute [ apiRoot ] []
    , expect = Http.expectJson RequestNotes (list noteDecoder)
    }


noteDecoder =
  map3 Note
    (field "text" string)
    (field "created_at" datetime)
    (field "oer_id" int)
