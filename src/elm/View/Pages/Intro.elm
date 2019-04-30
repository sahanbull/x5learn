module View.Pages.Intro exposing (viewIntroPage)

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


viewIntroPage : Model -> Element Msg
viewIntroPage model =
  let
      title =
        -- "Easy entrance to deep ideas." |> text |> el [ whiteText, Font.size 48, centerX, centerY ] |> el [ width fill, height <| fillPortion 3 ]
        [ "Study anything. Anywhere. Free!" |> text |> el [ whiteText, Font.size 60, centerX ]
        , "Easy entrance to deep ideas" |> text |> el [ whiteText, Font.size 24, centerX ]
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
