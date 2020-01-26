module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Url

import Element exposing (..)

import Msg exposing (..)

import Model exposing (..)
import View.Utility exposing (..)
import View.PageHeader exposing (viewPageHeader)
import View.NavigationDrawer exposing (..)
import View.Pages.Featured exposing (viewFeaturedPage)
import View.Pages.Maintenance exposing (viewMaintenancePage)
import View.Pages.Search exposing (viewSearchPage)
import View.Pages.Profile exposing (viewProfilePage)

import Update exposing (..)
import Request exposing (..)


{-| This module comprises the core of the Elm application.
    It contains the essential "main" function and some of its key arguments,
    particularly "init" and "view" (since they are small functions).
    The "update" function is large enough to deserve its own module.


    Set up the Elm application, using the "Browser" module.
    https://package.elm-lang.org/packages/elm/browser/1.0.1/Browser#application
    (NB check if the version number is in sync with elm.json)
-}
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


{-| Initialise the Elm application
-}
init : Flags -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
  let
      (model, cmd) =
        initialModel (Nav url key) flags
        |> update (ModelInitialized url) -- ensure that subpage-specific state is loaded when starting on a subpage
  in
      ( model, cmd )


{-| This is the top-level view functions.
    All it does is delegate to the appropriate view function to render the current page
-}
view : Model -> Browser.Document Msg
view model =
  let
      featuredPage =
        viewFeaturedPage model |> withNavigationDrawer model

      (body, inspector) =
        if isSiteUnderMaintenance then
          viewMaintenancePage
        else
          case  model.session of
            Nothing ->
              (viewLoadingSpinner, [])

            Just session ->
              case model.subpage of
                Home ->
                  if isLabStudy1 model then
                    case model.searchState of
                      Nothing ->
                        featuredPage

                      Just searchState ->
                        viewSearchPage model searchState |> withNavigationDrawer model
                  else
                    featuredPage

                Profile ->
                  case session.loginState of
                    LoggedInUser userProfile ->
                      viewProfilePage model userProfile model.userProfileForm |> withNavigationDrawer model

                    GuestUser ->
                      featuredPage

                Search ->
                  case model.searchState of
                    Nothing ->
                      featuredPage

                    Just searchState ->
                      viewSearchPage model searchState |> withNavigationDrawer model

      header : Attribute Msg
      header =
        viewPageHeader model
        |> inFront

      page =
        body
        |> el [ width fill, spacing 50, pageBodyBackground model, height (fill |> maximum (model.windowHeight - pageHeaderHeight)), scrollbarY, htmlId "MainPageContent" ]
        |> layout (inspector ++ [ header, paddingTop pageHeaderHeight, width fill ])
  in
      { title = "X5Learn"
      , body = [ page ]
      }
