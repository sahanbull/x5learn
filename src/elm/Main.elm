import Browser
import Browser.Navigation as Navigation
import Url

import Element exposing (..)

import Msg exposing (..)

import Model exposing (..)
import View.Shared exposing (..)
import View.PageHeader exposing (viewPageHeader)
import View.Pages.Landing exposing (viewPageLanding)
import Update exposing (..)


main : Program Flags Model Msg
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlChange = UrlChanged
    , onUrlRequest = LinkClicked
    }


init : Flags -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
  ( initialModel (Nav url key) flags, Cmd.none )


view : Model -> Browser.Document Msg
view model =
  let
      body =
        viewPageLanding model

      header =
        viewPageHeader model

      page =
        body
        |> el [ inFront header, width fill, spacing 50, paddingTop pageHeaderHeight, pageBodyBackground, height fill ]
        |> layout [ width fill ]
  in
      { title = "X5Learn"
      , body = [ page ]
      }
