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
        , borderColorLayout
        ] ++ userMessage


      loginLogoutSignup =
        case model.session of
          Nothing ->
            [ link [ alignRight, paddingXY 15 10 ] { url = logoutPath, label = "Log out" |> bodyNoWrap [] } ]

          Just session ->
            case session.loginState of
              LoggedInUser userProfile ->
                [ labStudyTaskTimer model
                , viewUserMenu model userProfile
                ]

              GuestUser ->
                [ link [ alignRight, paddingXY 15 10 ] { url = loginPath, label = "Log in" |> bodyNoWrap [] }
                , link [ alignRight, paddingXY 15 10 ] { url = signupPath, label = "Sign up" |> bodyNoWrap [] }
                ]
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
        |> row [ width fill, paddingXY 12 3, spacing 5 ]

      navButton url buttonText =
        link [ paddingXY 15 10, width fill ] { url = url, label = buttonText |> bodyNoWrap [] }

      labStudyTaskButtons =
        if isLabStudy1 model then
          [ labStudyTaskButton <| LabStudyTask "Warmup Task" 2 "w"
          , labStudyTaskButton <| LabStudyTask "Task 1 (Choose)" 20 "a"
          , labStudyTaskButton <| LabStudyTask "Task 2 (Gap)" 5 "a"
          , labStudyTaskButton <| LabStudyTask "Task 3 (Other version)" 5 "c"
          ]
        else
          []

      menu =
        if model.popup == Just UserMenu then
          ([ link [] { url = "/profile", label = displayName userProfile |> captionNowrap [ padding 15 ] }
          , navButton "/profile" "My profile"
          , navButton "/logout" "Log out"
          ]++labStudyTaskButtons)
          |> menuColumn [ Background.color white, moveRight 67, moveDown 38 ]
          |> onLeft
          |> List.singleton
        else
          []

      clickMsg =
        if model.popup == Just UserMenu then ClosePopup else SetPopup UserMenu
  in
      button ([ htmlClass "ClosePopupOnClickOutside", alignRight ] ++ menu) { onPress = Just <| clickMsg, label = label }


labStudyTaskButton : LabStudyTask -> Element Msg
labStudyTaskButton task =
  task.title |> bodyNoWrap []
  |> el [ paddingXY 15 10, width fill, onClick <| StartLabStudyTask task ]


labStudyTaskTimer : Model -> Element Msg
labStudyTaskTimer model =
  case model.startedLabStudyTask of
    Nothing ->
      none

    Just (task, startTime) ->
      let
          title =
            task.title |> captionNowrap [ greyTextDisabled ]

          countdown =
            let
                seconds =
                  (task.durationInMinutes * 60) - ((millisSince model startTime) // 1000)
                  |> max 0
            in
                seconds
                |> secondsToString
                |> captionNowrap ([ alignRight, width <| px 30 ] ++ (if seconds==0 then [ greyTextDisabled ] else []))

          label =
            [ title
            , countdown
            ]
            |> row [ spacing 10, alignRight ]
      in
            button [ alignRight ] { onPress = Just StoppedLabStudyTask, label = label }
            |> el [ width fill, alignRight ]
