module View.SearchWidget exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave, onFocus)
import Json.Decode
import Json.Encode
import Dict

import Model exposing (..)
import View.Utility exposing (..)
import Msg exposing (..)


viewSearchWidget : Model -> Length -> String -> String -> Element Msg
viewSearchWidget model widthAttr placeholder searchInputTyping =
  let
      submit =
        TriggerSearch searchInputTyping

      submitButton =
        let
            icon =
              image [ semiTransparent ] { src = (svgPath "search"), description = "search" }
        in
            button [ moveLeft 45, moveDown 1, width (px 45), height (px 45) ] { onPress = Just submit, label = icon }

      searchField =
        Input.text [ htmlId "SearchField", width fill, Input.focusedOnLoad, onEnter <| submit ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just (placeholder |> text |> Input.placeholder []), label = Input.labelHidden "search" }
        |> el [ width widthAttr, onRight submitButton, centerX, below suggestions ]

      suggestionButton str =
        let
            label =
              str |> bodyNoWrap [ width fill, padding 12, spacing 3, Border.rounded 4 ]

            background =
              if str == model.selectedSuggestion then
                [ superLightBackground ]
              else
                []

            mouseEnterHandler =
              if model.suggestionSelectionOnHoverEnabled then
                [ onMouseEnter <| SelectSuggestion str ]
              else
                []
        in
            button ([ width fill, clipX, onFocus <| SelectSuggestion str ]++background++mouseEnterHandler) { onPress = Just <| TriggerSearch str, label = label }

      suggestions =
        if List.isEmpty model.autocompleteTerms || String.length searchInputTyping < 1 then
          none
        else
          model.autocompleteSuggestions
          |> List.map (\suggestion -> suggestionButton suggestion)
          |> menuColumn [ width fill, clipY, height (px 39 |> maximum (39*7)) ]
          |> el [ width fill, htmlId "AutocompleteTerms" ]
  in
      [ searchField
      ]
      |> column [ spacing 10, centerX ]


