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
import View.Pages.Notes exposing (viewNotesPage)
import View.Pages.Gains exposing (viewGainsPage)
import View.Pages.Profile exposing (viewProfilePage)
import View.Pages.History exposing (viewHistoryPage)
import View.Pages.NextSteps exposing (viewNextStepsPage)

import Update exposing (..)
import Request exposing (..)


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
  let
      (model, cmd) =
        initialModel (Nav url key) flags
        |> update (Initialized url) -- ensure that subpage-specific state is loaded when starting on a subpage
  in
      ( model, [ cmd, requestViewedFragments ] |> Cmd.batch )


view : Model -> Browser.Document Msg
view model =
  let
      homePage =
        (viewHomePage model, [])

      (body, modal) =
        if model.session == Nothing then
          (viewLoadingSpinner, [])
        else
          case model.nav.url.path of
            "/next_steps" ->
              viewNextStepsPage model |> withNavigationDrawer model

            "/gains" ->
              viewGainsPage model |> withNavigationDrawer model

            "/profile" ->
              case loggedInUser model of
                Just userProfile ->
                  viewProfilePage model userProfile model.userProfileForm |> withNavigationDrawer model

                _ ->
                  homePage

            "/notes" ->
              viewNotesPage model |> withNavigationDrawer model

            "/history" ->
              viewHistoryPage model |> withNavigationDrawer model

            _ ->
              case model.searchState of
                Nothing ->
                  homePage

                Just searchState ->
                  viewSearchPage model searchState |> withNavigationDrawer model

      header =
        viewPageHeader model
        |> inFront

      page =
        body
        |> el [ width fill, spacing 50, pageBodyBackground, height (fill |> maximum (model.windowHeight - pageHeaderHeight)), scrollbarY ]
        |> layout (modal ++ [ header, paddingTop pageHeaderHeight, width fill ])
  in
      { title = "X5Learn"
      , body = [ page ]
      }
