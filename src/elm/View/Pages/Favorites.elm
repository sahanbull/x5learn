module View.Pages.Favorites exposing (viewFavoritesPage)

import Url
import Dict
import Set

import Time exposing (posixToMillis)

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import Animation exposing (..)
import View.Utility exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewFavoritesPage : Model -> PageWithModal
viewFavoritesPage model =
  let
      page =
        if model.favorites |> List.isEmpty then
          if isLoggedIn model then
            viewCenterNote "Your favorite items will appear here"
          else
            guestCallToSignup "In order to save your favorite items"
            |> milkyWhiteCenteredContainer
        else
          model.favorites
          -- |> List.filter (isMarkedAsFavorite model)
          |> List.filterMap (\oerId -> model.cachedOers |> Dict.get oerId)
          |> List.reverse
          |> viewOerCardsVertically model
  in
      (page, viewInspectorModalOrEmpty model)


viewOerCardsVertically : Model -> List Oer -> Element Msg
viewOerCardsVertically model oers =
  let
      rowHeight =
        cardHeight + verticalSpacingBetweenCards

      nrows =
        List.length oers

      cardPositionAtIndex index =
        { x = 0, y = index * rowHeight + 70 |> toFloat }

      viewCard index oer =
        viewOerCard model [] (cardPositionAtIndex index) ("vertical-"++ (String.fromInt index)) True oer |> el [ centerX ]

      cards =
        oers
        |> List.indexedMap viewCard
        |> List.reverse
        |> List.map inFront
  in
      none
      |> el ([ height (rowHeight * nrows + 100|> px), spacing 20, paddingBottom 200, width fill, Border.rounded 2 ] ++ cards)
