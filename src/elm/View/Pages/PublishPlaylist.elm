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


{-| Render the user profile page
-}
viewPublishPlaylistPage : Model -> PublishPlaylistForm -> PageWithInspector
viewPublishPlaylistPage model {playlist, published} =
  let
      textInput field labelText valueText =
        Input.text [ width fill, onEnter SubmittedPublishPlaylist ] { onChange = EditPlaylist field, text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = labelText |> text |> Input.labelAbove [ Font.size 16 ] }

      titleField =
        textInput Title "Title" playlist.title

      authorField =
        textInput Author "Author" ""

      licenseField =
        textInput License "License" ""

      publishButton =
        if model.playlistPublishFormSubmitted then
          viewLoadingSpinner
          |> el [ width (px 77), height (px 37) ]
        else
          if published then
            "✓ Published" |> bodyWrap [ greyText, width fill ]
          else
            button [ paddingXY 16 8, width fill, Background.color primaryGreen, whiteText ] { onPress = Just SubmittedPublishPlaylist, label = "Publish" |> text |> el [] }

      cancelButton = 
        link [ Font.center, width fill, Background.color yellow, bigButtonPadding, whiteText ] { url = "/home", label = Element.text "Cancel" }

      page =
        [ " Publish Playlist" |> captionNowrap [ centerX, Font.size 16 ]
        , [ titleField ] |> wrappedRow []
        , [ authorField ] |> wrappedRow []
        , [ licenseField ] |> wrappedRow []
        , [ publishButton, cancelButton ] |> wrappedRow [ spacing 20, height <| px 40 ]
        ]
        |> column [ spacing 30, padding 5 ]
        |> milkyWhiteCenteredContainer
  in
      (page, [])


viewDataCollectionConsentToggle : Bool -> Element Msg
viewDataCollectionConsentToggle enabled =
  [ "Allow X5GON to collect data about my activity on this site for research" |> bodyWrap [ width fill ]
  , viewToggleIndicator enabled (if enabled then "PrimaryGreenBackground" else "") |> el [ paddingRight 10 ]
  ]
  |> row [ spacing 10, onClick (ToggleDataCollectionConsent enabled), htmlClass "CursorPointer" ]
  |> el [ alignRight ]
