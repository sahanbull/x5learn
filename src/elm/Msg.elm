module Msg exposing (..)

import Browser
import Browser.Events
import Url

import Model exposing (..)

type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ChangeSearchText String
  | NewUserFromSearch
  | ResizeBrowser Int Int


subscriptions : Model -> Sub Msg
subscriptions model =
  [ Browser.Events.onResize ResizeBrowser
  ]
  |> Sub.batch
