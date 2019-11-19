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
import View.ContentFlowToggle exposing (..)

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
            |> row ([ width fill, paddingXY 8 12, spacing 28, Border.rounded 4 ] ++ background)
            |> if enabled then linkTo [ width fill ] url else el [ semiTransparent, htmlClass "CursorNotAllowed" ]

      navButtons =
        if isLabStudy1 model then
          [ viewContentFlowToggle model
          , model.course.items |> List.indexedMap (viewCourseItemInSidebar model) |> column [ spacing 20, borderTop 1, Border.color greyDivider, paddingTop 20 ]
          ]
          |> column [ spacing 30, width fill ]
        else
          -- [ navButton False "/next_steps" "nav_next_steps" "Next Steps"
          -- , navButton False "/journeys" "nav_journeys" "Journeys"
          -- [ navButton True "/favorites" "nav_favorites" "Favorites" |> heartAnimationWrapper
          -- , navButton True "/viewed" "nav_viewed" "Viewed"
          -- , navButton False "/peers" "nav_peers" "Peers"
          []
          |> column [ width fill, spacing 8 ]

      drawer =
        [ model.searchInputTyping |> viewSearchWidget model fill "Search"
        , navButtons
        ]
        |> column [ height fill, width (px navigationDrawerWidth), paddingXY 12 12, spacing 30, whiteBackground ]
        |> el [ height fill, width (px navigationDrawerWidth), paddingTop pageHeaderHeight ]
        |> inFront

      page =
        [ none |> el [ width (px navigationDrawerWidth) ]
        , pageContent
        ]
        |> row [ width fill, height fill ]

      heartAnimationWrapper =
        let
            animationLayer =
              case model.flyingHeartAnimation of
                Nothing ->
                  []

                Just {startTime} ->
                  case model.flyingHeartAnimationStartPoint of
                    Nothing ->
                      []

                    Just startPoint ->
                      let
                          phase =
                            ((millisSince model startTime |> toFloat) / (flyingHeartAnimationDuration - 300)) ^ 0.9 |> min 1

                          x =
                            startPoint.x * (1-phase)

                          y =
                            startPoint.y * (1-phase)

                          size =
                            px 25

                          opacity =
                            phase^0.8

                          transition =
                            htmlStyle "transition-duration" "0.1s"

                          heart =
                            none
                            |> el [ width <| size, height <| size, moveDown <| 10 + y, moveRight <| 6 + x, htmlClass "Heart HeartFilled HeartFlying PointerEventsNone", Element.alpha opacity, transition ]
                      in
                          [ inFront heart ]
        in
            el ([ width fill, htmlClass "HeartAnimWrapper" ] ++ animationLayer)
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


viewCourseItemInSidebar model index item =
  case model.cachedOers |> Dict.get item.oerId of
    Nothing ->
      none -- impossible
    Just oer ->
      let
          miniCard =
            [ index+1 |> String.fromInt |> bodyNoWrap []
            , oer.title |> bodyWrap []
            ]
            |> column [ spacing 5, Border.color <| greyDivider ]
      in
          button [] { onPress = Just <| InspectOer oer 0 False, label = miniCard }
