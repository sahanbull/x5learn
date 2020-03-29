module View.NavigationDrawer exposing (withNavigationDrawer)

import Dict
import Set
import Json.Decode as Decode

import Element exposing (..)
import Element.Input as Input exposing (button, text)
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
withNavigationDrawer : Model -> PageWithInspector -> PageWithInspector
withNavigationDrawer model (pageContent, inspector) =
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
          , viewCourse model,
          playlistActionButtons
          ]
          |> column [ spacing 40, width fill ]
        else
          [ viewCourse model,
          playlistActionButtons
          ]
          |> column [ width fill, spacing 8 ]

      selectPlaylistButton = 
          let

            newOption =
              actionButtonWithoutIcon [] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ]  "Create New Playlist" (Just <| CreateNewPlaylist True)

            option playlist =
              actionButtonWithoutIcon [] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] playlist.title (Just <| SelectedPlaylist Nothing)

            options : List (Attribute Msg)
            options =
              case model.popup of
                Just PlaylistPopup ->
                  [ newOption
                  ]
                  |> menuColumn [ width fill]
                  |> below
                  |> List.singleton

                _ ->
                  []

            attrs =
              [ width fill, alignLeft, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
          in
            actionButtonWithoutIcon [ width fill, centerX, paddingXY 12 10 ] [ width fill, buttonRounding, Border.width 1, Border.color greyDivider ] "Select Playlist ▾"  (Just OpenedSelectPlaylistMenu)
            |> el attrs




      drawer =
        [ if isLabStudy1 model then none else model.searchInputTyping |> viewSearchWidget model fill "Search" |> explainify model explanationForSearchField
        , selectPlaylistButton
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
  in
      (page, inspector ++ [ drawer ])

playlistActionButtons : Element Msg
playlistActionButtons =
  [  button [ Font.center, width fill,  Background.color primaryGreen, bigButtonPadding, whiteText ] { label = Element.text "Save", onPress = (Just <| SelectedPlaylist Nothing)}
  ,  link [ Font.center, width fill, Background.color red, bigButtonPadding, whiteText ] { url = "/publish_playlist", label = Element.text "Publish" }
  ]
  |> row [ spacing 10,  width (fillPortion 2)]

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
  , links = [ explanationLinkForSearch ]
  }
