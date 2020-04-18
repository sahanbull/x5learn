module View.Pages.Search exposing (viewSearchPage)

import Url
import Url.Builder
import Dict
import Set

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Utility exposing (..)
import View.SearchWidget exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Time exposing (millisToPosix)

import Json.Decode as Decode


{-| Render the search page, mainly including the search results
    Note that the search field is part of the NavigationDrawer
-}
viewSearchPage : Model -> SearchState -> PageWithInspector
viewSearchPage model searchState =
  case model.playlistState of
    Nothing ->
      let
        inspector =
          viewInspector model

        content =
          viewBody model searchState
      in
        (content, inspector)

    Just PlaylistInfo ->
      let
      
        inspector =
          viewInspector model

        content =
          viewPlaylistInfoPage model
      in
        (content, inspector)

    Just PlaylistShare ->
      let
      
        inspector =
          viewInspector model

        content =
          viewPlaylistSharePage model

      in
        (content, inspector)

    Just PlaylistClone ->
      let
          inspector =
            viewInspector model

          content =
            viewClonePlaylistPage model model.playlistCreateForm

      in
          (content, inspector)



{-| Render the main part of the search pge
-}
viewBody : Model -> SearchState -> Element Msg
viewBody model searchState =
  case searchState.searchResults of
    Nothing ->
      viewLoadingSpinner

    Just [] ->
      "No results were found for \"" ++ searchState.lastSearchText ++ "\". Please try a different search term." |> viewCenterMessage

    Just oerIds ->
      if isLabStudy1 model && model.currentTaskName==Nothing then
        "Please wait for the researcher's instructions." |> viewCenterMessage
      else
        Playlist Nothing "" Nothing Nothing Nothing Nothing True Nothing oerIds Nothing
        |> viewOerGrid model
        |> el [ width fill, height fill, paddingBottom 100 ]


viewPlaylistInfoPage : Model -> Element Msg
viewPlaylistInfoPage model =
  case model.publishedPlaylist of
    Nothing ->
      viewLoadingSpinner

    Just publishedPlaylist ->
      let
        licenseType = 
          case publishedPlaylist.license of
              Nothing ->
                ""
          
              Just license ->
                filterLicense model.licenseTypes license

        closeButton =
          button [ width fill, paddingXY 16 8, Font.center, Background.color electricBlue, whiteText ] { onPress = (Just (SetPlaylistState Nothing)), label = "Close" |> text }
          
        content =
          [ "Playlist Information" |> captionNowrap [ Font.center, centerX, Font.size 16 ]
          , [ text "Title : ", text publishedPlaylist.title] |> wrappedRow [ Font.size 14]
          , [ text "Description : ", text (Maybe.withDefault " - " publishedPlaylist.description)] |> wrappedRow [ Font.size 14 ]
          , [ text "Author : ", text (Maybe.withDefault " - " publishedPlaylist.author)] |> wrappedRow [ Font.size 14 ]
          , [ text "License : ", text licenseType] |> wrappedRow [ Font.size 14 ]
          , [closeButton] |> row [ width fill, Font.center ]
          ]
          |> column [ spacing 30, padding 5, width (px 400) ]
          |> milkyWhiteCenteredContainer
      in
        content


viewPlaylistSharePage : Model -> Element Msg
viewPlaylistSharePage model =
  case model.publishedPlaylist of
    Nothing ->
      viewLoadingSpinner

    Just publishedPlaylist ->
      let
        closeButton =
          button [ width fill, paddingXY 16 8, Font.center, Background.color electricBlue, whiteText ] { onPress = (Just (SetPlaylistState Nothing)), label = "Close" |> text }

        url =
          case publishedPlaylist.url of
            Nothing -> 
              "URL not found"

            Just playlistUrl ->
              playlistUrl

        content =
          [ "Share Playlist" |> captionNowrap [ centerX, Font.size 16 ]
          , [ text url ] |> row [ Font.size 14 ]
          , closeButton
          ]
          |> column [ spacing 30, padding 5 ]
          |> milkyWhiteCenteredContainer
      in
        content

viewClonePlaylistPage : Model -> CreatePlaylistForm -> Element Msg
viewClonePlaylistPage model {playlist, saved} =
  if saved == False then
    let
      textInput field labelText valueText =
        Input.text [ width fill, onEnter SubmittedCreatePlaylist ] { onChange = EditNewPlaylist field, text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = labelText |> text |> Input.labelAbove [ Font.size 16 ] }

      titleField =
        textInput Title "Title" playlist.title

      createButton =
        if model.playlistCreateFormSubmitted then
          viewLoadingSpinner
          |> el [ width (px 77), height (px 37) ]
        else
          if saved then
            "✓ Saved" |> bodyWrap [ greyText, width fill ]
          else
            button [ paddingXY 16 8, width fill, Background.color electricBlue, whiteText, Font.center ] { onPress = Just SubmittedCreatePlaylist, label = "Save" |> text }

      cancelButton = 
        button [ width fill, paddingXY 16 8, Font.center, Background.color red, whiteText ] { onPress = Just (SetPlaylistState Nothing), label = "Cancel" |> text }

      playlistItems = 
        List.map (\x -> viewPlaylistItem model x) playlist.oerIds
      page =
        [ " Clone Playlist" |> captionNowrap [ centerX, Font.size 16 ]
        , [ titleField ] |> wrappedRow []
        , [ text "Playlist Items" ] |> wrappedRow [ width fill, Font.size 16 ]
        , playlistItems |> wrappedRow [ htmlClass "blockContent marginTop" ]
        , [ createButton, cancelButton ] |> wrappedRow [ width (fillPortion 2), spacing 20, height <| px 40 ]
        ]
        |> column [ spacing 30, padding 5 ]
        |> milkyWhiteCenteredContainer
      in
        page

    else
      let
        page =
          [ " Playlist Successfully Cloned!" |> captionNowrap [ centerX, Font.size 16 ]
          , button [ width fill, paddingXY 16 8, Font.center, Background.color electricBlue, whiteText ] { onPress = Just (SetPlaylistState Nothing), label = "Go Back" |> text }
          ]
          |> column [ spacing 30, padding 5 ]
          |> milkyWhiteCenteredContainer
      in
        page



filterLicense : List LicenseType -> Int -> String
filterLicense licenses license =
  let
    matches = List.filter (\x -> x.id == license) licenses
  in
    case List.head matches of
        Nothing ->
            ""
    
        Just firstMatch ->
            firstMatch.description

viewPlaylistItem : Model -> Int -> Element Msg
viewPlaylistItem model id =
  case model.cachedOers |> Dict.get id of
      Nothing ->
        none

      Just oer ->
        [ text (" - " ++ oer.title) ]
        |> column [ spacing 20, Font.size 14 ]

