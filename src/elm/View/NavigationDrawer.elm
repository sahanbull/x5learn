module View.NavigationDrawer exposing (withNavigationDrawer)

import Dict
import Set

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


withNavigationDrawer : Model -> PageWithModal -> PageWithModal
withNavigationDrawer model (pageContent, modal) =
  let
      navButton url svgIconStub label =
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
            |> row ([ width fill, padding 12, spacing 30, Border.rounded 4 ] ++ background)
            |> linkTo [ width fill ] url

      navButtons =
        [ navButton "/next_steps" "nav_next_steps" "Next Steps"
        , navButton "/journeys" "nav_journeys" "Journeys"
        , navButton "/bookmarks" "nav_bookmarks" "Bookmarks"
        , navButton "/history" "nav_history" "History"
        , navButton "/notes" "nav_notes" "Notes"
        , navButton "/peers" "nav_peers" "Peers"
        ]
        |> column [ width fill, spacing 10 ]

      drawer =
        [ model.searchInputTyping |> viewSearchWidget fill "Search"
        , navButtons
        ]
        |> column [ height fill, width (px navigationDrawerWidth), paddingXY 12 14, spacing 30, whiteBackground ]

      page =
        [ drawer
        , pageContent
        ]
        |> row [ width fill, height fill ]
  in
      (page, modal)
