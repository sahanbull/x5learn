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
        -- "Easy entrance to deep ideas." |> text |> el [ primaryWhite, Font.size 48, centerX, centerY ] |> el [ width fill, height <| fillPortion 3 ]
        [ "Discover ideas" |> text |> el [ primaryWhite, Font.size 80, centerX ]
        , "Study anything. Anywhere. Free" |> text |> el [ primaryWhite, Font.size 24, centerX ]
        ]
        |> column [ centerX, centerY, spacing 30 ]
        |> el [ width fill, height <| fillPortion 3 ]

      searchSection =
        model.searchInputTyping
        |> viewSearchWidget model (px 360) "Find open learning materials"
        |> el [ width fill, height <| fillPortion 7 ]
  in
      [ title
      , searchSection
      ]
      |> column [ centerX, padding 20, spacing 20, width fill, height fill ]
