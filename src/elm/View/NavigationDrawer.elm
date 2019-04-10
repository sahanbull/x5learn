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
            |> row ([ width fill, padding 12, spacing 30, Border.rounded 4 ] ++ background)
            |> if enabled then linkTo [ width fill ] url else el [ semiTransparent, htmlClass "CursorNotAllowed" ]

      navButtons =
        -- [ navButton False "/next_steps" "nav_next_steps" "Next Steps"
        -- , navButton False "/journeys" "nav_journeys" "Journeys"
        [ navButton True "/bookmarks" "nav_bookmarks" "Bookmarks"
        , navButton True "/history" "nav_history" "History"
        -- , navButton True "/gains" "nav_gains" "Gains"
        -- , navButton False "/notes" "nav_notes" "Notes"
        -- , navButton False "/peers" "nav_peers" "Peers"
        ]
        |> column [ width fill, spacing 10 ]

      drawer =
        [ model.searchInputTyping |> viewSearchWidget model fill "Search"
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
