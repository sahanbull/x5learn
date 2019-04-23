module View.PageHeader exposing (viewPageHeader)

import Html
import Html.Attributes
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Input as Input exposing (button)

import Model exposing (..)

import View.Shared exposing (..)

import Msg exposing (..)


viewPageHeader : Model -> Element Msg
viewPageHeader model =
  let
      userMessage =
        case model.userMessage of
          Nothing ->
            []

          Just str ->
            [ str |> text |> el [ Background.color <| rgb 1 0.5 0.5, paddingXY 30 10, centerX ] |> below ]

      attrs =
        [ width fill
        , height (px pageHeaderHeight)
        , spacing 20
        , paddingEach { allSidesZero | top = 0, left = 16, right = 16 }
        , Background.color <| rgb 1 1 1
        , borderBottom 1
        , Border.color <| rgb 0.8 0.8 0.8
        ] ++ userMessage


      loginLogoutSignup =
        case model.session of
          Just (LoggedInUser username) ->
            [ viewUserMenu model username ]

          Just (Guest username) ->
            -- [ "(Guest ID "++username++")" |> captionNowrap [ alignRight ]
            [ link [ alignRight, paddingXY 15 10 ] { url = "/login", label = "Log in" |> bodyNoWrap [] }
            , link [ alignRight, paddingXY 15 10 ] { url = "/signup", label = "Sign up" |> bodyNoWrap [] }
            ]

          _ ->
            []
  in
      [ link [] { url = "/", label = image [ height (px 26) ] { src = imgPath "x5learn_logo.png", description = "X5Learn logo" } } ] ++ loginLogoutSignup
      |> row attrs


viewUserMenu model userProfile =
  let
      icon =
        avatarImage

      triangle =
        "▾" |> captionNowrap [ Font.color grey80 ]

      label =
        [ icon, triangle ]

      navButton url buttonText =
        link [ paddingXY 15 10, width fill ] { url = url, label = buttonText |> bodyNoWrap [] }

      menu =
        if model.popup == Just UserMenu then
          [ userProfile |> displayName |> captionNowrap [ padding 15 ]
          , navButton "/profile" "My profile"
          , navButton "/logout" "Log out"
          ]
          |> menuColumn [ Background.color white, moveRight 67, moveDown 38 ]
          |> onLeft
          |> List.singleton
        else
          []

      clickMsg =
        if model.popup == Just UserMenu then ClosePopup else SetPopup UserMenu
  in
      button ([ htmlClass "ClosePopupOnClickOutside", alignRight ] ++ menu) { onPress = Just <| clickMsg, label = label |> row [ width fill, paddingXY 12 3, spacing 5 ]}
