module View.NavigationDrawer exposing (withNavigationDrawer)

import Dict
import Set
import Json.Decode as Decode

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


withNavigationDrawer : Model -> PageWithModal -> PageWithModal
withNavigationDrawer model (pageContent, modal) =
  let
      navButton enabled url svgIconStub label =
        let
            background =
              if currentUrlMatches model url then
                [ Background.color <| rgba 0 0.5 1 0.3 ]
              else
                []
        in
            [ image [ width (px 20), alpha 0.66 ] { src = svgPath svgIconStub, description = "" }
            , label |> bodyNoWrap [ width fill ]
            ]
            |> row ([ width fill, paddingXY 0 12, spacing 30, Border.rounded 4 ] ++ background)
            |> if enabled then linkTo [ width fill ] url else el [ semiTransparent, htmlClass "CursorNotAllowed" ]

      navButtons =
        if isLabStudy1 model then
          none
        else
          -- [ navButton False "/next_steps" "nav_next_steps" "Next Steps"
          -- , navButton False "/journeys" "nav_journeys" "Journeys"
          [ navButton True "/notes" "nav_bookmarks" "Notes"
          , navButton True "/recent" "nav_recent" "Recent"
          -- , navButton True "/gains" "nav_gains" "Gains"
          -- , navButton False "/notes" "nav_notes" "Notes"
          -- , navButton False "/peers" "nav_peers" "Peers"
          ]
          |> column [ width fill, spacing 10 ]

      drawer =
        [ model.searchInputTyping |> (if isLabStudy1 model then dataSetSelectionWidget model else viewSearchWidget model fill "Search")
        , viewOverviewSelectionWidget model
        , navButtons
        ]
        |> column [ height fill, width (px navigationDrawerWidth), paddingXY 12 14, spacing 30, whiteBackground ]
        |> el [ height fill, width (px navigationDrawerWidth), paddingTop pageHeaderHeight ]
        |> inFront

      page =
        [ none |> el [ width (px navigationDrawerWidth) ]
        , pageContent
        ]
        |> row [ width fill, height fill ]
  in
      (page, modal ++ [ drawer ])




dataSetSelectionWidget model searchInputTyping =
  let
      submit =
        TriggerSearch searchInputTyping

      searchField =
        Input.text [ htmlId "SearchField", width fill, Input.focusedOnLoad, onEnter <| submit ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just ("Dataset" |> text |> Input.placeholder []), label = Input.labelHidden "search" }
        |> el [ width fill, centerX ]
  in
      searchField


viewOverviewSelectionWidget : Model -> Element Msg
viewOverviewSelectionWidget model =
  Input.radio
    [ paddingXY 0 20
    , spacing 20
    , width fill
    ]
    { onChange = SelectedOverviewType
    , selected = Just model.overviewType
    , label = Input.labelAbove captionTextAttrs (text "Preview")
    , options =
        [ Input.option BubblogramOverview (bodyNoWrap [] "Compact")
        , Input.option StoryOverview (bodyNoWrap [] "Detailed")
        ]
    }
    |> el [ width fill, padding 10, borderBottom 1, borderColorLayout ]
