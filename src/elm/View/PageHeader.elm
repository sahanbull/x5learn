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

import View.Utility exposing (..)
import View.ToggleIndicator exposing (..)

import Msg exposing (..)


{-| Render the page header bar, including the typical elements:
    - Site logo
    - Login / Signup
    - User menu (when logged in)
-}
viewPageHeader : Model -> Element Msg
viewPageHeader model =
  let
      snackbar =
        case model.snackbar of
          Nothing ->
            []

          Just {text, startTime} ->
            let
                time =
                  millisSince model startTime

                opacity =
                  if time < snackbarDuration - 1500 then 1 else 0
            in
                [ text |> bodyWrap [ htmlClass "Snackbar", alpha opacity, pointerEventsNone, Background.color <| grey 50, paddingXY 25 15, centerX, Font.size 13, greyText, Border.rounded 4, Font.color <| greyMedium, centerX, moveDown <| toFloat <| model.windowHeight - pageHeaderHeight - 50 ] |> el [ paddingLeft <| navigationDrawerWidth, centerX ]  |> below ]

      attrs =
        [ width fill
        , height (px pageHeaderHeight)
        , spacing 20
        , paddingEach { allSidesZero | top = 0, left = 13, right = 16 }
        , Background.color <| rgb 1 1 1
        , borderBottom 1
        , borderColorDivider
        ] ++ snackbar

      loginLogoutSignup =
        case model.session of
          Nothing ->
            [ link [ alignRight, paddingXY 15 10 ] { url = logoutPath, label = "Log out" |> bodyNoWrap [] } ]

          Just session ->
            case session.loginState of
              LoggedInUser userProfile ->
                [ viewExplainerToggle model
                , viewUserMenu model userProfile
                ]

              GuestUser ->
                [ link [ alignRight, paddingXY 15 10 ] { url = loginPath, label = "Log in" |> bodyNoWrap [] }
                , link [ alignRight, paddingXY 15 10 ] { url = signupPath, label = "Sign up" |> bodyNoWrap [] }
                ]
  in
      [ link [] { url = "/", label = image [ height (px 26) ] { src = imgPath "x5learn_logo.png", description = "X5Learn logo" } } ] ++ loginLogoutSignup
      |> row attrs


{-| Render the user menu
-}
viewUserMenu : Model -> UserProfile -> Element Msg
viewUserMenu model userProfile =
  let
      icon =
        avatarImage

      triangle =
        "▾" |> captionNowrap [ Font.color grey80 ]

      label =
        [ icon, triangle ]
        |> row [ width fill, paddingXY 12 3, spacing 5 ]

      navButton url buttonText =
        link [ paddingXY 15 10, width fill ] { url = url, label = buttonText |> bodyNoWrap [] }

      menu =
        if model.popup == Just UserMenu then
          let
              menuItems =
                if isLabStudy1 model then
                  [ displayName userProfile |> captionNowrap [ padding 15 ]
                  , navButton "/logout" "Log out"
                  ]
                else
                  [ link [] { url = "/profile", label = displayName userProfile |> captionNowrap [ padding 15 ] }
                  , navButton "/profile" "My profile"
                  , navButton "/logout" "Log out"
                  ]
          in
              menuItems
              |> menuColumn [ Background.color white, moveRight 67, moveDown 38 ]
              |> onLeft
              |> List.singleton
        else
          []

      clickMsg =
        if model.popup == Just UserMenu then ClosePopup else SetPopup UserMenu
  in
      button ([ htmlClass "ClosePopupOnClickOutside", alignRight ] ++ menu) { onPress = Just <| clickMsg, label = label }


{-| Render the widget for the user to switch Explainer on and off
-}
viewExplainerToggle : Model -> Element Msg
viewExplainerToggle model =
  let
      enabled =
        model.isExplainerEnabled
  in
  [ "Transparent AI" |> bodyNoWrap ([ width fill ] ++ (if enabled then [ Font.color magenta ] else []))
  , viewToggleIndicator enabled (if enabled then "MagentaBackground" else "") |> el [ paddingRight 10 ]
  ]
  |> row [ spacing 10, onClick ToggleExplainer, htmlClass "CursorPointer" ]
  |> el [ alignRight ]
