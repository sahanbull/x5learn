module View.Pages.History exposing (viewHistoryPage)

import Url
import Dict
import Set
import List.Extra

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
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewHistoryPage : Model -> PageWithModal
viewHistoryPage model =
  let
      page =
        case model.viewedFragments of
          Nothing ->
            viewLoadingSpinner

          Just fragmentsOrEmpty ->
            case fragmentsOrEmpty of
              [] ->
                viewCenterNote "Your viewed items will appear here"

              fragments ->
                fragments
                |> viewVerticalListOfCards model
  in
      (page, viewInspectorModalOrEmpty model)



viewVerticalListOfCards : Model -> List Fragment -> Element Msg
viewVerticalListOfCards model fragments =
  let
      rowHeight =
        cardHeight + 50

      nrows =
        List.length fragments

      cardPositionAtIndex index =
        { x = 0, y = index * rowHeight + 70 |> toFloat }

      cards =
        fragments
        |> List.indexedMap (\index fragment -> viewOerCard model [] (cardPositionAtIndex index) ("history-"++ (String.fromInt index)) fragment.oer |> el [ centerX ])
        |> List.reverse
        |> List.map inFront
  in
      none
      -- |> column ([ height (rowHeight * nrows + 100|> px), spacing 20, padding 20, width fill, Background.color transparentWhite, Border.rounded 2 ] ++ cards)
      |> el ([ height (rowHeight * nrows + 100|> px), spacing 20, paddingBottom 200, width fill, Border.rounded 2 ] ++ cards)
