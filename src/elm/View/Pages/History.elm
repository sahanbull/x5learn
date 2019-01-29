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

import Msg exposing (..)

import Json.Decode as Decode


viewHistoryPage : Model -> PageWithModal
viewHistoryPage model =
  let
      modal =
        []

      page =
        model.viewedFragments
        |> List.map (\fragment -> fragment.url)
        |> List.Extra.unique
        |> List.map (viewOerCardInHistory model)
        |> List.map (el [ centerX ])
        |> column [ paddingTop 20, spacing 20, width fill, height fill ]
  in
      (page, modal)


viewOerCardInHistory model _ =
  viewOerCard model bishopBook
