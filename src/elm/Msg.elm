module Msg exposing (..)

import Browser
import Browser.Events
import Url
import Json.Encode as Encode
import Http
import Time exposing (Posix)
import Dict exposing (Dict)

import Geometry exposing (..)
import Model exposing (..)
import Ports

type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ChangeSearchText String
  | NewUserFromSearch
  | ResizeBrowser Int Int
  | InspectSearchResult Oer
  | UninspectSearchResult
  | TriggerAnim Encode.Value
  | RequestOerSearch (Result Http.Error (List Oer))
  | ClockTick Posix
  | SetHover (Maybe String)


subscriptions : Model -> Sub Msg
subscriptions model =
  [ Browser.Events.onResize ResizeBrowser
  , Ports.modalAnim TriggerAnim
  , Time.every 200 ClockTick
  ]
  |> Sub.batch
