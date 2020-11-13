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
import Html.Attributes

import I18Next exposing ( t, Delims(..) )

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
          playlistActionButtons model
          ]
          |> column [ spacing 40, width fill ]
        else if isLabStudy2 model then
          [ taskButtons model
          ]
          |> column [ spacing 40, width fill ]
        else
          case model.playlist of
              Nothing ->
                [ viewCourse model]
                |> column [ width fill, spacing 8 ]
          
              Just playist ->
                [ viewCourse model
                , playlistActionButtons model
                ]
                |> column [ width fill, spacing 8 ]

      selectPlaylistButton = 
        if isLoggedIn model then
          let
            buttonText = 
              case model.playlist of
                Nothing ->
                  (t model.translations "generic.btn_select_playlist") ++ " ▾"
            
                Just playlist ->
                  playlist.title ++ " ▾"
              
            newOption =
              link [ borderBottom 1, Border.color greyDivider, Font.size 14, bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] { url = "/create_playlist", label = italicText (t model.translations "generic.btn_create_new_playlist") }

            option playlist =
              actionButtonWithoutIcon [] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] playlist.title (Just <| SelectedPlaylist playlist)

            options : List (Attribute Msg)
            options =
              case model.popup of
                Just PlaylistPopup ->
                  [ newOption ] ++ List.map  (\x -> option x) (Maybe.withDefault [] model.userPlaylists)
                  |> menuColumn [ width fill]
                  |> below
                  |> List.singleton

                _ ->
                  []

            attrs =
              [ width fill, alignLeft, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
          in
            actionButtonWithoutIcon [ width fill, centerX, paddingXY 12 10, htmlClass "textOverflowControl" ] [ width fill, buttonRounding, Border.width 1, Border.color greyDivider ] buttonText (Just OpenedSelectPlaylistMenu)
            |> el attrs
        else
          guestCallToSignup model (t model.translations "alerts.lbl_guest_call_to_signup_create_playlists")
          |> el [ width fill, paddingXY 15 12, Background.color <| rgb 1 0.85 0.6 ]
          |> el []


      drawer =
        if model.promptedDeletePlaylist == True then
          let
            topRow =
              case model.playlist of
                Nothing ->
                  (t model.translations "playlist.lbl_delete_prompt") ++ " - Not Found ?" |> bodyWrap []

                Just playlist ->
                  (t model.translations "playlist.lbl_delete_prompt") ++ " - " ++ playlist.title ++" ?" |> bodyWrap []

            yesButton =
              case model.playlist of
                Nothing ->
                  Element.text (t model.translations "playlist.lbl_playlist_not_found")

                Just playlist ->
                  button [ width fill, paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| DeletePlaylist playlist, label = (t model.translations "generic.lbl_yes") |> captionNowrap [ width fill, whiteText, Font.center ] }

            noButton =
              button [ width fill, paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| PromptDeletePlaylist False, label = (t model.translations "generic.lbl_no") |> captionNowrap [ width fill, whiteText, Font.center ] }

            buttonRow =
              [ yesButton
              , noButton
              ]
              |> row [ width (fillPortion 2), spacing 10 ]

            miniCard =
              [ topRow
              , buttonRow
              ]
              |> column [ width fill, spacing 10, padding 10, buttonRounding, Border.width 1, Border.color greyDivider, smallShadow ]

          in
          [ if isLabStudy1 model || isLabStudy2 model then none else model.searchInputTyping |> viewSearchWidget model fill (t model.translations "generic.lbl_search") |> explainify model explanationForSearchField
          , miniCard
          ]
          |> column [ height fill, width (px navigationDrawerWidth), paddingXY 12 12, spacing 30, whiteBackground ]
          |> el [ height fill, width (px navigationDrawerWidth), paddingTop pageHeaderHeight ]
          |> inFront
        else if isLabStudy2 model then
          case model.playlist of
            Nothing ->
              [ navButtons 
              , selectPlaylistButton
              , viewCourse model
              ]
              |> column [ height fill, width (px navigationDrawerWidth), paddingXY 12 12, spacing 20, whiteBackground ]
              |> el [ height fill, width (px navigationDrawerWidth), paddingTop pageHeaderHeight ]
              |> inFront
            Just playist ->
              [ navButtons 
              , selectPlaylistButton
              , viewCourse model
              , playlistActionButtons model
              ]
              |> column [ height fill, width (px navigationDrawerWidth), paddingXY 12 12, spacing 20, whiteBackground ]
              |> el [ height fill, width (px navigationDrawerWidth), paddingTop pageHeaderHeight ]
              |> inFront
        else
          [ if (isLabStudy1 model || isLabStudy2 model) then none else model.searchInputTyping |> viewSearchWidget model fill (t model.translations "generic.lbl_search") |> explainify model explanationForSearchField
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

playlistActionButtons : Model -> Element Msg
playlistActionButtons model =
  case model.playlist of
      Nothing ->
          none
  
      Just playlist ->
        if List.length playlist.oerIds > 0 then
          let
            publishPlaylistTooltip = 
              htmlTitleAttribute (t model.translations "playlist.lbl_publish_tooltip")

            firstRow = 
              [ link [ whiteText, paddingXY 12 10, width fill, centerX,  Background.color primaryGreen, buttonRounding, Font.center, publishPlaylistTooltip ] { url = "/publish_playlist", label = Element.text (t model.translations "playlist.btn_publish") }
              , button [ whiteText, paddingXY 12 10, width fill, centerX,  Background.color red, buttonRounding, Font.center ] { label = Element.text (t model.translations "playlist.btn_delete"), onPress = Just <| PromptDeletePlaylist True }
              ]
              |> row [ spacing 10,  width (fillPortion 2)]

          in
            [  firstRow ]
            |> column [ paddingTop 20, width fill ]
        else
          let
            firstRow = 
              [ button [ whiteText, paddingXY 12 10, width fill, centerX, Background.color red, buttonRounding ] { label = Element.text (t model.translations "playlist.btn_delete"), onPress = Just <| PromptDeletePlaylist True }
              ]
              |> row [ spacing 10,  width fill]
          in
            [  firstRow ]
            |> column [ paddingTop 20, width fill ]
  
  
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
    if isLabStudy1 model then
      [ taskButton "Practice"
      , taskButton "Task 1"
      , taskButton "Task 2"
      ]
      |> column [ spacing 10 ]
    else if isLabStudy2 model then
      [ taskButton "Practice"
      , taskButton "Math"
      , taskButton "Interaction"
      ]
      |> column [ spacing 10 ]
    else
      [ Element.text "No Tasks Available"
      ]
      |> column [ spacing 10 ]


explanationForSearchField : Explanation
explanationForSearchField =
  { componentId = "searchField"
  , flyoutDirection = Right
  , links = [ explanationLinkForSearch ]
  }
