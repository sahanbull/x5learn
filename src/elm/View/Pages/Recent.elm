module View.Pages.Recent exposing (viewRecentPage)

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


viewRecentPage : Model -> PageWithModal
viewRecentPage model =
  let
      page =
        if model.fragmentAccesses |> Dict.isEmpty then
          if isLoggedIn model then
            viewCenterNote "Your viewed items will appear here"
          else
            guestCallToSignup "To ensure that your changes are saved"
            |> milkyWhiteCenteredContainer
        else
          let
              oerIds =
                model.fragmentAccesses
                |> Dict.toList
                |> List.map (\(time, fragment) -> fragment.oerId)
                |> List.reverse
                |> List.Extra.unique
          in
              viewVerticalListOfCards model oerIds
  in
      (page, viewInspectorModalOrEmpty model)


viewVerticalListOfCards : Model -> List OerId -> Element Msg
viewVerticalListOfCards model oerIds =
  let
      rowHeight =
        cardHeight + verticalSpacingBetweenCards

      nrows =
        List.length oerIds

      cardPositionAtIndex index =
        { x = 0, y = index * rowHeight + 70 |> toFloat }

      viewCard index oerId =
        let
            oer =
              oerId
              |> getCachedOerWithBlankDefault model
        in
            viewOerCard model [] (cardPositionAtIndex index) ("recent-"++ (String.fromInt index)) oer |> el [ centerX ]

      cards =
        oerIds
        |> List.indexedMap viewCard
        |> List.reverse
        |> List.map inFront
  in
      none
      |> el ([ height (rowHeight * nrows + 100|> px), spacing 20, paddingBottom 200, width fill, Border.rounded 2 ] ++ cards)
