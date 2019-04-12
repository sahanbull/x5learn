module View.Pages.Gains exposing (viewGainsPage)

import Url
import Dict
import Set

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


viewGainsPage : Model -> PageWithModal
viewGainsPage model =
  let
      page =
        case model.gains of
          Nothing ->
            viewLoadingSpinner

          Just gainsOrEmpty ->
            case gainsOrEmpty of
              [] ->
                viewCenterNote "Your gains will appear here"

              gains ->
                viewTable gains
                |> el [ whiteBackground, centerX, centerY, padding 50 ]
                |> el [ width fill, padding 50 ]
  in
      (page, [])


viewTable gains =
  let
      columnHeader =
        headlineWrap []

      cellWithTopPadding =
        bodyWrap [ paddingTop 17 ]
  in
      table []
        { data = gains
        , columns =
          [ { header = "Concept" |> headlineWrap []
            , width = fillPortion 5
            , view =
                \gain ->
                  gain.title |> cellWithTopPadding
            }
          , { header = columnHeader "Level"
            , width = fillPortion 2
            , view =
                \gain ->
                  gain.level |> String.fromFloat |> cellWithTopPadding
            }
          , { header = columnHeader "Confidence"
            , width = fillPortion 3
            , view =
                \gain ->
                  gain.confidence |> String.fromFloat |> cellWithTopPadding
            }
          , { header = columnHeader "Actions"
            , width = fillPortion 4
            , view =
                \_ ->
                  [ actionButtonWithIcon IconLeft "test_me" "Test me" <| Nothing
                  , actionButtonWithIcon IconLeft "train_me" "Train me" <| Nothing
                  ]
                  |> row [ spacing 20 ]
            }
          ]
        }
