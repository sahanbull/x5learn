module View.Pages.Recents exposing (viewRecentsPage)

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


viewRecentsPage : Model -> UserState -> PageWithModal
viewRecentsPage model userState =
  let
      page =
        if userState.fragmentAccesses |> Dict.isEmpty then
          viewCenterNote "Your viewed items will appear here"
        else
          let
              oerUrls =
                userState.fragmentAccesses
                |> Dict.toList
                |> List.map (\(time, fragment) -> fragment.oerUrl)
                |> List.Extra.unique
          in
              viewVerticalListOfCards model userState oerUrls
  in
      (page, viewInspectorModalOrEmpty model userState)


viewVerticalListOfCards : Model -> UserState -> List OerUrl -> Element Msg
viewVerticalListOfCards model userState oerUrls =
  let
      rowHeight =
        cardHeight + 50

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
            viewOerCard model userState [] (cardPositionAtIndex index) ("recents-"++ (String.fromInt index)) oer |> el [ centerX ]

      cards =
        oerUrls
        |> List.indexedMap viewCard
        |> List.map inFront
  in
      none
      |> el ([ height (rowHeight * nrows + 100|> px), spacing 20, paddingBottom 200, width fill, Border.rounded 2 ] ++ cards)
