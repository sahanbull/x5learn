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


viewProfilePage : UserProfile -> UserProfileForm -> PageWithModal
viewProfilePage savedUserProfile {userProfile, saved} =
  let
      firstNameField =
        Input.text [ width fill ] { onChange = EditUserProfile FirstName, text = userProfile.firstName, placeholder = Just ("First Name" |> text |> Input.placeholder []), label = "First Name" |> text |> Input.labelAbove [ Font.size 16 ] }

      lastNameField =
        Input.text [ width fill ] { onChange = EditUserProfile LastName, text = userProfile.lastName, placeholder = Just ("Last Name" |> text |> Input.placeholder []), label = "Last Name" |> text |> Input.labelAbove [ Font.size 16 ] }

      saveButton =
        if saved then
          "✓ Saved" |> bodyWrap [ greyTextDisabled, width fill ]
        else
          button [ paddingXY 16 8, width fill, Background.color x5color, whiteText ] { onPress = Just ClickedSaveUserProfile, label = "Save" |> text |> el [] }

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
