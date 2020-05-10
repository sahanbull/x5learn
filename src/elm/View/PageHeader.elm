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
                [ text |> bodyWrap [ htmlClass "Snackbar", alpha opacity, pointerEventsNone, Background.color oxfordBlue, paddingXY 25 15, centerX, Font.size 16, whiteText, Border.rounded 4, Font.color white, centerX, moveDown <| toFloat <| model.windowHeight - pageHeaderHeight - 50 ] |> el [ paddingLeft <| navigationDrawerWidth, centerX ]  |> below ]

      attrs =
        [ width fill
        , height (px pageHeaderHeight)
        , spacing 20
        , paddingEach { allSidesZero | top = 0, left = 13, right = 16 }
        , Background.color white
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
                , viewLinkToAboutPage
                , viewUserMenu model userProfile
                ]

              GuestUser ->
                let
                    loginHintPopup =
                      case model.popup of
                        Just LoginHintPopup ->
                          [ guestCallToSignup "To create your ideal personal learning pathway" ]
                          |> menuColumn [ padding 15, moveDown 10, width <| px 176, Background.color warningOrange ]
                          |> below
                          |> List.singleton

                        _ ->
                          []
                in
                    [ viewExplainerToggle model
                    , viewLinkToAboutPage
                    , link [ alignRight, paddingXY 15 10 ] { url = loginPath, label = "Log in" |> bodyNoWrap [] } |> el loginHintPopup
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

      label =
        [ icon, dropdownTriangle ]
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
              |> menuColumn [ moveRight 67, moveDown 38 ]
              |> onLeft
              |> List.singleton
        else
          []

      clickMsg =
        if model.popup == Just UserMenu then ClosePopup else SetPopup UserMenu
  in
      button ([ htmlClass "PreventClosingThePopupOnClick", alignRight ] ++ menu) { onPress = Just clickMsg, label = label }


{-| Render the widget for the user to switch Explainer on and off
-}
viewExplainerToggle : Model -> Element Msg
viewExplainerToggle model =
  let
      enabled =
        model.isExplainerEnabled

      popup =
        case model.popup of
          Just ExplainerMetaInformationPopup ->
            [ "This mode allows you to see which AI components are involved in specific parts of the user interface. Use the 'explain' buttons for links to further information." |> bodyWrap [] ]
            |> menuColumn [ padding 15, moveDown 10 ]
            |> below
            |> List.singleton

          _ ->
            []
  in
      [ "Unveil the AI" |> bodyNoWrap ([ width fill ] ++ (if enabled then [ Font.color magenta ] else []))
      , viewToggleIndicator enabled (if enabled then "MagentaBackground" else "") |> el [ paddingRight 10 ]
      ]
      |> row ([ spacing 10, onClick ToggleExplainer, htmlClass "CursorPointer PreventClosingThePopupOnClick" ] ++ popup)
      |> el [ alignRight ]


{-| Render the link to the /about page
-}
viewLinkToAboutPage : Element Msg
viewLinkToAboutPage =
  link [ alignRight, paddingXY 15 10 ] { url = aboutPath, label = "About" |> bodyNoWrap [] }
