module View.Pages.PostRegistration exposing (viewPostRegistrationPage)

import Url
import Dict
import Set

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import Animation exposing (..)
import View.Shared exposing (..)
import View.Card exposing (..)
import View.Inspector exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewPostRegistrationPage : Model -> UserState -> PageWithModal
viewPostRegistrationPage model userState =
  let
      heading =
        "Welcome 😊"
        |> headlineWrap []

      explanation =
        "You have successfully signed up."
        |> bodyWrap []

      options =
        [ confirmButton [ alignRight ] "Got it" (Just <| SubmitPostRegistrationForm True)
        ]
        |> row [ spacing 30, width fill ]

      form =
        [ heading
        , explanation
        , options
        ]
        |> column [ padding 20, spacing 30, width (px 440) ]

      page =
        form
        |> milkyWhiteCenteredContainer
  in
      (page, viewInspectorModalOrEmpty model userState)
