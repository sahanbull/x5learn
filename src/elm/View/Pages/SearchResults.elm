module View.Pages.SearchResults exposing (viewPageSearchResults)

import Url

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode

viewPageSearchResults : Model -> UserState -> Element Msg
viewPageSearchResults model userState =
  let
      results =
        mockSearchResults
        |> List.indexedMap viewSearchResult
        |> wrappedRow [ centerX, spacing 30, width (fill |> maximum 1100) ]
  in
      results
      |> el [ padding 20, spacing 20, width fill, height fill ]


viewSearchResult index oer =
  let
      thumbnail =
        none
        |> el [ width fill, height (px 175), Background.image <| imgPath ("mockthumb" ++ (index+1 |> String.fromInt) ++ ".jpg"), htmlClass "materialHoverZoomThumb" ]

      title =
        oer.title |> subheaderWrap []

      playIcon =
        image [ moveRight 260, moveDown 160, width (px 30) ] { src = (svgPath "playIcon"), description = "play icon" }

      bottomRow =
        [ "videolectures.net" |> captionNowrap []
        , "90 min" |> captionNowrap [ alignRight ]
        ]
        |> row [ width fill, paddingXY 16 0, moveUp 26 ]

      info =
        [ title
        ]
        |> column [ padding 16, height fill ]
  in
      [ thumbnail
      , info
      ]
      |> column [ width (px 332), height (px 280), htmlClass "materialCard", inFront playIcon, below bottomRow ]
