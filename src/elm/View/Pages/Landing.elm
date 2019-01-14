module View.Pages.Landing exposing (viewPageLanding)

import Url

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode

viewPageLanding : Model -> Element Msg
viewPageLanding model =
  let
      title =
        "Study anything. Anywhere. Free." |> text |> el [ primaryWhite, jumboText, centerX, centerY ] |> el [ width fill, height <| fillPortion 3 ]

      searchSection =
        viewSearchWidget model.searchInputTyping
        |> el [ width fill, height <| fillPortion 5 ]
  in
      [ title
      , searchSection
      ]
      |> column [ centerX, padding 20, spacing 20, width fill, height fill ]


viewSearchWidget searchInputTyping =
  let
      icon =
        image [ alpha 0.5 ] { src = (svgPath "search"), description = "search icon" }

      submitButton =
        button [ moveLeft 34, moveDown 12 ] { onPress = Just NewUserFromSearch, label = icon }
  in
      Input.text [ width (px 360), primaryDark, Input.focusedOnLoad, onEnter NewUserFromSearch ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just ("Find open learning materials" |> text |> Input.placeholder []), label = Input.labelHidden "search" }
      |> el [ centerX, onRight submitButton ]
