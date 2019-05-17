import Browser
import Browser.Navigation as Navigation
import Url

import Element exposing (..)

import Msg exposing (..)

import Model exposing (..)
import View.Shared exposing (..)
import View.PageHeader exposing (viewPageHeader)
import View.NavigationDrawer exposing (..)
import View.Pages.Intro exposing (viewIntroPage)
import View.Pages.PostRegistration exposing (viewPostRegistrationPage)
import View.Pages.Search exposing (viewSearchPage)
import View.Pages.Notes exposing (viewNotesPage)
import View.Pages.Gains exposing (viewGainsPage)
import View.Pages.Profile exposing (viewProfilePage)
import View.Pages.Recent exposing (viewRecentPage)

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
      ( model, cmd )


view : Model -> Browser.Document Msg
view model =
  let
      introPage =
        (viewIntroPage model, [])

      (body, modal) =
        case  model.session of
          Nothing ->
            (viewLoadingSpinner, [])

          Just ({userState} as session) ->
            case model.nav.url.path of
              -- "/next_steps" ->
              --   viewNextStepsPage model |> withNavigationDrawer model

              -- "/gains" ->
              --   viewGainsPage model |> withNavigationDrawer model

              "/profile" ->
                case session.loginState of
                  LoggedInUser userProfile ->
                    viewProfilePage model userProfile model.userProfileForm |> withNavigationDrawer model

                  GuestUser ->
                    introPage

              "/notes" ->
                viewNotesPage model userState |> withNavigationDrawer model

              "/" ->
                if session.loginState /= GuestUser && (not userState.registrationComplete) then
                  viewPostRegistrationPage model userState |> withNavigationDrawer model
                else if userState == initialUserState then
                  introPage
                else
                  viewNotesPage model userState |> withNavigationDrawer model

              "/recent" ->
                viewRecentPage model userState |> withNavigationDrawer model

              _ ->
                case model.searchState of
                  Nothing ->
                    introPage

                  Just searchState ->
                    viewSearchPage model userState searchState |> withNavigationDrawer model

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
