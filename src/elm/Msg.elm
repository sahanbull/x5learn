module Msg exposing (..)

import Browser
import Url

import Model exposing (..)

type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ChangeSearchText String
  | SubmitSearch


subscriptions : Model -> Sub Msg
subscriptions model =
  [] |> Sub.batch
