import Browser
import Browser.Navigation as Navigation
import Url

import Element exposing (..)

import Msg exposing (..)

import Model exposing (..)
import View.Shared exposing (..)
import View.PageHeader exposing (viewPageHeader)
import View.NavigationDrawer exposing (..)
import View.Pages.Home exposing (viewHomePage)
import View.Pages.Search exposing (viewSearchPage)
import View.Pages.Playlists exposing (viewPlaylistsPage)

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
      (body, modal) =
        case model.nav.url.path of
          "/playlists" ->
            viewPlaylistsPage model |> withNavigationDrawer model

          _ ->
            case model.searchState of
              Nothing ->
                (viewHomePage model, [])

              Just searchState ->
                viewSearchPage model searchState |> withNavigationDrawer model

      header =
        viewPageHeader model

      page =
        body
        |> el [ width fill, spacing 50, pageBodyBackground, height (fill |> maximum (model.windowHeight - pageHeaderHeight)), scrollbarY ]
        |> layout ([ inFront header, paddingTop pageHeaderHeight, width fill ] ++ modal)
  in
      { title = "X5Learn"
      , body = [ page ]
      }
