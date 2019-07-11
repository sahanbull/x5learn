module NotesApi exposing (saveNote)--, requestNotes)

import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, at, field, list, string)

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
