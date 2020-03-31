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
            button [ paddingXY 16 8, width fill, Background.color primaryGreen, whiteText ] { onPress = Just SubmittedCreatePlaylist, label = "Save" |> text |> el [] }

      cancelButton = 
        link [ Font.center, width fill, Background.color yellow, bigButtonPadding, whiteText ] { url = "/home", label = Element.text "Cancel" }

      page =
        [ " Create Playlist" |> captionNowrap [ centerX, Font.size 16 ]
        , [ titleField ] |> wrappedRow []
        , [ createButton, cancelButton ] |> wrappedRow [ spacing 20, height <| px 40 ]
        ]
        |> column [ spacing 30, padding 5 ]
        |> milkyWhiteCenteredContainer
  in
      (page, [])
