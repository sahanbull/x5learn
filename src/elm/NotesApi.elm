module NotesApi exposing (saveNote, requestNotes, deleteNote)

import Time exposing (millisToPosix)

import Json.Encode as Encode exposing (encode, object)
import Json.Decode as Decode exposing (Decoder, map4, at, field, list, string, int)
import Json.Decode.Extra exposing (datetime)

import Url
import Url.Builder

import Http

import Msg exposing (..)
import Model exposing (..)


apiRoot =
  "api/v1/note"


saveNote : OerId -> String -> Cmd Msg
saveNote oerId text =
  Http.post
    { url = Url.Builder.absolute [ apiRoot, "" ] []
    , body = Http.jsonBody <| object [ ("oer_id", Encode.int oerId), ("text", Encode.string text) ]
    , expect = Http.expectJson RequestSaveNote (field "result" string)
    }


deleteNote : Note -> Cmd Msg
deleteNote note =
  Http.request
    { method = "DELETE"
    , headers = []
    , url = Url.Builder.absolute [ apiRoot, String.fromInt note.id ] []
    , body = Http.jsonBody <| object []
    , expect = Http.expectJson RequestDeleteNote (field "result" string)
    , timeout = Nothing
    , tracker = Nothing
    }


requestNotes : Cmd Msg
requestNotes =
  Http.get
    { url = Url.Builder.absolute [ apiRoot, "" ] []
    , expect = Http.expectJson RequestNotes (list noteDecoder)
    }


noteDecoder =
  map4 Note
    (field "text" string)
    (field "created_at" datetime)
    (field "oer_id" int)
    (field "id" int)
