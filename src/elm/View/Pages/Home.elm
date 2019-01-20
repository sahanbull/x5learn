module View.Pages.Home exposing (viewHomePage)

import Url

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewHomePage : Model -> Element Msg
viewHomePage model =
  let
      title =
        "Study anything. Anywhere. Free." |> text |> el [ primaryWhite, Font.size 48, centerX, centerY ] |> el [ width fill, height <| fillPortion 3 ]

      searchSection =
        model.searchInputTyping
        |> viewSearchWidget (px 360) "Find open learning materials"
        |> el [ width fill, height <| fillPortion 5 ]
  in
      [ title
      , searchSection
      ]
      |> column [ centerX, padding 20, spacing 20, width fill, height fill ]
