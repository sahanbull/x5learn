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
import View.Card exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewRecentPage : Model -> UserState -> PageWithModal
viewRecentPage model userState =
  let
      page =
        if userState.fragmentAccesses |> Dict.isEmpty then
          if isLoggedIn model then
            viewCenterNote "Your viewed items will appear here"
          else
            guestCallToSignup "To ensure that your changes are saved"
            |> milkyWhiteCenteredContainer
        else
          let
              oerUrls =
                userState.fragmentAccesses
                |> Dict.toList
                |> List.map (\(time, fragment) -> fragment.oerUrl)
                |> List.reverse
                |> List.Extra.unique
          in
              viewVerticalListOfCards model userState oerUrls
  in
      (page, viewInspectorModalOrEmpty model userState)


viewVerticalListOfCards : Model -> UserState -> List OerUrl -> Element Msg
viewVerticalListOfCards model userState oerUrls =
  let
      rowHeight =
        cardHeight + verticalSpacingBetweenCards

      nrows =
        List.length oerUrls

      cardPositionAtIndex index =
        { x = 0, y = index * rowHeight + 70 |> toFloat }

      viewCard index oerUrl =
        let
            oer =
              oerUrl
              |> getCachedOerWithBlankDefault model
        in
            viewOerCard model userState [] (cardPositionAtIndex index) ("recent-"++ (String.fromInt index)) oer |> el [ centerX ]

      cards =
        oerUrls
        |> List.indexedMap viewCard
        |> List.reverse
        |> List.map inFront
  in
      none
      |> el ([ height (rowHeight * nrows + 100|> px), spacing 20, paddingBottom 200, width fill, Border.rounded 2 ] ++ cards)
