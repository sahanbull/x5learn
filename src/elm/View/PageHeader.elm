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
          Just (LoggedIn username) ->
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


viewUserMenu model username =
  let
      icon =
        image [ alpha 0.5 ] { src = svgPath "user_default_avatar", description = "user menu" }

      title =
        "▾" |> captionNowrap [ Font.color grey80 ]

      label =
        [ icon, title ]

      menu =
        case model.popup of
          Just UserMenu ->
            [ username |> captionNowrap [ padding 15 ]
            , link [ paddingXY 15 10 ] { url = "/logout", label = "Log out" |> bodyNoWrap [] }
            ]
            |> menuColumn [ width <| px 100, Background.color white, moveLeft 30 ]
            |> below
            |> List.singleton

          _ ->
            []
  in
      button ([ htmlClass "PopupAutoclose", alignRight ] ++ menu) { onPress = Just <| SetPopup UserMenu, label = label |> row [ width fill, paddingXY 12 3, spacing 5 ]}
