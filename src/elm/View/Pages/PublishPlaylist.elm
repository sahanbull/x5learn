module View.Pages.PublishPlaylist exposing (viewPublishPlaylistPage)

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Utility exposing (..)
import View.ToggleIndicator exposing (..)

import Msg exposing (..)
import Dict

import I18Next exposing ( t, Delims(..) )

{-| Render the user profile page
-}
viewPublishPlaylistPage : Model -> PublishPlaylistForm -> PageWithInspector
viewPublishPlaylistPage model {playlist, published, originalTitle, blueprintUrl} =
  case blueprintUrl of
    Nothing ->
      let
        textInput field labelText valueText =
          Input.text [ width fill, onEnter SubmittedPublishPlaylist, Font.size 14 ] { onChange = EditPlaylist field, text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = labelText |> text |> Input.labelAbove [ Font.size 16 ] }

        textMultiline field labelText valueText =
          Input.multiline [ width fill, onEnter SubmittedPublishPlaylist, Font.size 14 ] { onChange = EditPlaylist field, text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = labelText |> text |> Input.labelAbove [ Font.size 16 ], spellcheck = False }

        titleField =
          textInput Title (t model.translations "playlist.lbl_playlist_title") playlist.title
        descriptionField =
          case playlist.description of
            Nothing ->
              textMultiline Description (t model.translations "playlist.lbl_playlist_description") ""

            Just val ->
              textMultiline Description (t model.translations "playlist.lbl_playlist_description") val
                  
        authorField =
          case playlist.author of
            Nothing ->
              textInput Author (t model.translations "playlist.lbl_playlist_author") ""

            Just val ->
              textInput Author (t model.translations "playlist.lbl_playlist_author") val

        publishButton =
          if model.playlistPublishFormSubmitted then
            viewLoadingSpinner
            |> el [ width (px 77), height (px 37) ]
          else
            if published then
              "✓ " ++ (t model.translations "playlist.btn_published") |> bodyWrap [ greyText, width fill ]
            else
              button [ paddingXY 16 8, Font.center, Background.color electricBlue, whiteText ] { onPress = Just SubmittedPublishPlaylist, label = (t model.translations "playlist.btn_submit") |> text |> el [] }

        cancelButton = 
          link [ Font.center, Background.color red, bigButtonPadding, whiteText, alignRight ] { url = "/home", label = Element.text (t model.translations "playlist.btn_playlist_cancel") }

        selectLicenseButton = 
            let

              buttonText = 
                case playlist.license of
                  Nothing ->
                    (t model.translations "playlist.btn_select_license") ++ " ▾"
              
                  Just license ->
                    filterLicense model.licenseTypes license
                

              option license =
                actionButtonWithoutIcon [ width fill ] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] license.description (Just <| SelectedLicense license)

              options : List (Attribute Msg)
              options =
                case model.popup of
                  Just SelectLicensePopup ->
                    List.map  (\x -> option x) model.licenseTypes
                    |> menuColumn [ width fill]
                    |> below
                    |> List.singleton

                  _ ->
                    []

              attrs =
                [ width fill, alignLeft, htmlClass "PreventClosingThePopupOnClick formButton", buttonRounding ] ++ options
            in
              actionButtonWithoutIcon [ width fill, centerX, paddingXY 12 10 ] [ width fill, buttonRounding, Border.width 1, Border.color greyDivider ] buttonText (Just OpenedSelectLicenseMenu)
              |> el attrs

        playlistItems = 
          List.map (\x -> viewPlaylistItem model x.oerId) model.course.items

        page =
          [ (t model.translations "playlist.lbl_publish_playlist") |> captionNowrap [ centerX, Font.size 16 ]
          , [ titleField ] |> wrappedRow [ width fill ]
          , [ descriptionField ] |> wrappedRow [ width fill ]
          , [ authorField ] |> wrappedRow [ width fill ]
          , [ text (t model.translations "playlist.lbl_playlist_license") ] |> wrappedRow [Font.size 16, width fill]
          , [ selectLicenseButton ] |> wrappedRow [ width fill, htmlClass "marginTop" ]
          , [ text (t model.translations "playlist.lbl_playlist_items") ] |> wrappedRow [ width fill, Font.size 16 ]
          , playlistItems |> wrappedRow [ htmlClass "blockContent marginTop" ]
          , [ publishButton, cancelButton ] |> wrappedRow [ width (fillPortion 2), spacing 20, height <| px 40 ]
          ]
          |> column [ spacing 30, padding 5 ]
          |> milkyWhiteCenteredContainer
      in
          (page, [])

    Just url ->
      let
        page =
          [ (t model.translations "alerts.lbl_publish_playlist_success") |> captionNowrap [ centerX, Font.size 16 ]
          , link [ Font.size 16, Font.center, width fill, Background.color electricBlue, bigButtonPadding, whiteText ] { url = url, label = Element.text (t model.translations "playlist.btn_view_published_playlist") }
          ]
          |> column [ spacing 30, padding 5 ]
          |> milkyWhiteCenteredContainer
      in
        (page, [])

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
        let

          title = 
            case getPlaylistTitle model oer.id of
              Nothing ->
                oer.title

              Just playlistTitle ->
                playlistTitle

        in
        [ text (" - " ++ title) ]
        |> column [ spacing 20, Font.size 14 ]


getPlaylistTitle : Model -> OerId -> Maybe String
getPlaylistTitle model oerId =
  case model.playlist of 
    Nothing ->
      Nothing

    Just playlist ->
      let

        playlistItemData =
          List.head ( List.filter (\x -> x.oerId == oerId ) playlist.playlistItemData)

      in
        case playlistItemData of
            Nothing ->
              Nothing
                
            Just itemData ->
              Just itemData.title
        
  
  
          