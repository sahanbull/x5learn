module View.Pages.CreatePlaylist exposing (viewCreatePlaylistPage)

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
viewCreatePlaylistPage : Model -> CreatePlaylistForm -> PageWithInspector
viewCreatePlaylistPage model {playlist, saved} =
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
        link [ Font.center, width fill, Background.color red, bigButtonPadding, whiteText, alignRight ] { url = "/home", label = Element.text "Cancel" }

      page =
        [ " Create Playlist" |> captionNowrap [ centerX, Font.size 16 ]
        , [ titleField ] |> wrappedRow []
        , [ createButton, cancelButton ] |> wrappedRow [ width (fillPortion 2), spacing 20, height <| px 40 ]
        ]
        |> column [ spacing 30, padding 5 ]
        |> milkyWhiteCenteredContainer
      in
        (page, [])

    else
      let
        page =
          [ " Playlist Successfully Created!" |> captionNowrap [ centerX, Font.size 16 ]
          , link [ Font.size 16, Font.center, width fill, Background.color electricBlue, bigButtonPadding, whiteText ] { url = "/", label = Element.text "Go Back" }
          ]
          |> column [ spacing 30, padding 5 ]
          |> milkyWhiteCenteredContainer
      in
        (page, [])