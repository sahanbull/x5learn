module View.Pages.Viewed exposing (viewViewedPage)

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
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewViewedPage : Model -> PageWithModal
viewViewedPage model =
  let
      page =
        if model.fragmentAccesses |> Dict.isEmpty then
          if isLoggedIn model then
            viewCenterNote "Your viewed items will appear here"
          else
            guestCallToSignup "To ensure that your changes are saved"
            |> milkyWhiteCenteredContainer
        else
          model.fragmentAccesses
          |> Dict.toList
          |> List.map (\(time, fragment) -> fragment.oerId)
          |> List.filterMap (\oerId -> model.cachedOers |> Dict.get oerId)
          |> List.reverse
          |> List.Extra.uniqueBy .id
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
