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
import View.Utility exposing (..)
import View.Explainer exposing (..)
import View.SearchWidget exposing (..)
import View.ContentFlowToggle exposing (..)
import View.Course exposing (..)

import Msg exposing (..)


{-| Add a navigation drawer (sidebar) to a given page
    https://material.io/components/navigation-drawer/
-}
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
          , taskButtons model
          , viewCourse model
          ]
          |> column [ spacing 40, width fill ]
        else
          -- [ navButton True "/favorites" "nav_favorites" "Favorites" |> heartAnimationWrapper
          []
          |> column [ width fill, spacing 8 ]

      drawer =
        [ if isLabStudy1 model then none else model.searchInputTyping |> viewSearchWidget model fill "Search" |> explainify model explanationForSearchField
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
                            ((millisSince model startTime |> toFloat) / ((toFloat flyingHeartAnimationDuration) - 300)) ^ 0.9 |> min 1

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


taskButtons : Model -> Element Msg
taskButtons model =
  let
      taskButton taskName =
        case model.currentTaskName of
          Nothing ->
            confirmButton [] ("Start "++taskName) <| Just <| StartTask taskName

          Just name ->
            if name==taskName then
              [ taskName++" started" |> bodyNoWrap []
              , stopButton [] "Complete" <| Just CompleteTask
              ]
              |> row [ spacing 20 ]
            else
              confirmButton [ alpha 0.3, greyText ] ("Start "++taskName) Nothing
  in
      [ taskButton "Practice"
      , taskButton "Task 1"
      , taskButton "Task 2"
      ]
      |> column [ spacing 10 ]


explanationForSearchField : Explanation
explanationForSearchField =
  { componentId = "searchField"
  , flyoutDirection = Right
  , blurb = "Text entered here is forwarded to the X5GON Discovery API. The results do not depend on your user data."
  , url = "https://platform.x5gon.org/products/discovery"
  }
