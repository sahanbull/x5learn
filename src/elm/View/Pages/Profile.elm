module View.Pages.Profile exposing (viewProfilePage)

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


viewProfilePage : Model -> UserProfile -> UserProfileForm -> PageWithModal
viewProfilePage model savedUserProfile {userProfile, saved} =
  let
      textInput field labelText valueText =
        Input.text [ width fill, onEnter SubmittedUserProfile ] { onChange = EditUserProfile field, text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = labelText |> text |> Input.labelAbove [ Font.size 16 ] }

      firstNameField =
        textInput FirstName "First Name" userProfile.firstName

      lastNameField =
        textInput LastName "Last Name" userProfile.lastName

      saveButton =
        if model.userProfileFormSubmitted then
          viewLoadingSpinner
          |> el [ width (px 77), height (px 37) ]
        else
          if saved then
            "✓ Saved" |> bodyWrap [ greyTextDisabled, width fill ]
          else
            button [ paddingXY 16 8, width fill, Background.color x5color, whiteText ] { onPress = Just SubmittedUserProfile, label = "Save" |> text |> el [] }

      page =
        -- [ "My profile" |> headlineWrap []
        [ image [ alpha 0.5, centerX, width <| px 75 ] { src = svgPath "user_default_avatar", description = "user menu" }
        , "Email: " ++ userProfile.email |> captionNowrap [ centerX ]
        , [ firstNameField, lastNameField ] |> wrappedRow [ spacing 20 ]
        , [ saveButton ] |> wrappedRow [ spacing 20, height <| px 40 ]
        ]
        |> column [ spacing 30, padding 5 ]
        |> milkyWhiteCenteredContainer
  in
      (page, [])
