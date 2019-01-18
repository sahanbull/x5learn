module Msg exposing (..)

import Browser
import Browser.Events
import Url
import Json.Encode as Encode

import Geometry exposing (..)
import Model exposing (..)
import Ports

type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ChangeSearchText String
  | NewUserFromSearch
  | ResizeBrowser Int Int
  | InspectSearchResult UserState Oer
  | UninspectSearchResult UserState
  | TriggerAnim Encode.Value


subscriptions : Model -> Sub Msg
subscriptions model =
  [ Browser.Events.onResize ResizeBrowser
  , Ports.modalAnim TriggerAnim
  ]
  |> Sub.batch
