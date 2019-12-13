import Browser
import Browser.Navigation as Navigation
import Url

import Element exposing (..)

import Msg exposing (..)

import Model exposing (..)
import View.Shared exposing (..)
import View.PageHeader exposing (viewPageHeader)
import View.NavigationDrawer exposing (..)
import View.Pages.Featured exposing (viewFeaturedPage)
import View.Pages.Maintenance exposing (viewMaintenancePage)
import View.Pages.Search exposing (viewSearchPage)
-- import View.Pages.Notes exposing (viewNotesPage)
-- import View.Pages.Favorites exposing (viewFavoritesPage)
import View.Pages.Profile exposing (viewProfilePage)
-- import View.Pages.Viewed exposing (viewViewedPage)
import View.Pages.Resource exposing (viewResourcePage)

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
      featuredPage =
        viewFeaturedPage model |> withNavigationDrawer model

      (body, modal) =
        if isSiteUnderMaintenance then
          viewMaintenancePage
        else
          case  model.session of
            Nothing ->
              (viewLoadingSpinner, [])

            Just session ->
              case model.subpage of
                Home ->
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

                -- Favorites ->
                --   viewFavoritesPage model |> withNavigationDrawer model

                -- Notes ->
                --   viewNotesPage model |> withNavigationDrawer model

                -- Viewed ->
                --   viewViewedPage model |> withNavigationDrawer model

                Resource ->
                  viewResourcePage model |> withNavigationDrawer model

      header : Attribute Msg
      header =
        viewPageHeader model
        |> inFront

      page =
        body
        |> el [ width fill, spacing 50, pageBodyBackground model, height (fill |> maximum (model.windowHeight - pageHeaderHeight)), scrollbarY, htmlId "MainPageContent" ]
        |> layout (modal ++ [ header, paddingTop pageHeaderHeight, width fill ])
  in
      { title = "X5Learn"
      , body = [ page ]
      }
