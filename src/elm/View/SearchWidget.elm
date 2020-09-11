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
        TriggerSearch searchInputTyping True

      submitButton =
        let
            icon =
              image [ semiTransparent ] { src = (svgPath "search"), description = "search" }
        in
            button [ moveLeft 45, moveDown 1, width (px 45), height (px 45) ] { onPress = Just submit, label = icon }

      searchField =
        Input.text [ Font.size 14, htmlId "SearchField", width fill, Input.focusedOnLoad, onEnter <| submit ] { onChange = SearchFieldChanged, text = searchInputTyping, placeholder = Just (placeholder |> text |> Input.placeholder []), label = Input.labelHidden "search" }
        |> el [ width widthAttr, onRight submitButton, centerX ]

      materialTypeButton =
        let
          buttonText = 
            model.materialType ++ " ▾"

          option materialType =
            actionButtonWithoutIcon [] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] materialType (Just <| SelectedMaterialTypeForSearch materialType)

          options : List (Attribute Msg)
          options =
            case model.popup of
              Just SearchMaterialTypePopup ->
                List.map  (\x -> option x) (List.filter (\o -> model.materialType /= o) [ "All Media", "Video", "Audio", "Text" ])
                |> menuColumn [ width fill]
                |> below
                |> List.singleton
              
              _ ->
                []

          attrs =
            [ width fill, alignLeft, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
        in
          actionButtonWithoutIcon [ width fill, centerX, paddingXY 12 10, htmlClass "textOverflowControl" ] [ width fill, buttonRounding, Border.width 1, Border.color greyDivider ] buttonText (Just OpenedSelectSearchMaterialType)
          |> el attrs

      materialLanguageButton =
        let
          buttonText = 
            model.materialLanguage ++ " ▾"

          option materialLanguage =
            actionButtonWithoutIcon [] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] materialLanguage (Just <| SelectedMaterialLanguageForSearch materialLanguage)

          options : List (Attribute Msg)
          options =
            case model.popup of
              Just SearchMaterialLanguagePopup ->
                List.map  (\x -> option x) (List.filter (\o -> model.materialLanguage /= o) ["en", "ch", "ru", "pt", "es", "ja", "fr", "de", "it", "ar", "hi", "pa", "bn"])
                |> menuColumn [ width fill]
                |> below
                |> List.singleton
              
              _ ->
                []

          attrs =
            [ width fill, alignLeft, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
        in
          actionButtonWithoutIcon [ width fill, centerX, paddingXY 12 10, htmlClass "textOverflowControl" ] [ width fill, buttonRounding, Border.width 1, Border.color greyDivider ] buttonText (Just OpenedSelectSearchMaterialLanguage)
          |> el attrs

      buttonRow =
        [ materialTypeButton
        , materialLanguageButton
        ]
        |> row [ width (fillPortion 2), spacing 10 ]

  in
      [ searchField
      , buttonRow
      ]
      |> column [ spacing 10, centerX ]


