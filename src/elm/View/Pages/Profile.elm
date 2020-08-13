module View.Pages.Profile exposing (viewProfilePage)

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

import I18Next exposing ( t, Delims(..) )

{-| Render the user profile page
-}
viewProfilePage : Model -> UserProfile -> UserProfileForm -> PageWithInspector
viewProfilePage model savedUserProfile {userProfile, saved} =
  let
      textInput field labelText valueText =
        Input.text [ width fill, onEnter SubmittedUserProfile ] { onChange = EditUserProfile field, text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = labelText |> text |> Input.labelAbove [ Font.size 16 ] }

      firstNameField =
        textInput FirstName (t model.translations "profile.lbl_first_name") userProfile.firstName

      lastNameField =
        textInput LastName (t model.translations "profile.lbl_last_name") userProfile.lastName

      saveButton =
        if model.userProfileFormSubmitted then
          viewLoadingSpinner
          |> el [ width (px 77), height (px 37) ]
        else
          if saved then
            "✓ " ++ (t model.translations "profile.lbl_saved")  |> bodyWrap [ greyText, width fill ]
          else
            button [ paddingXY 16 8, width fill, Background.color primaryGreen, whiteText ] { onPress = Just SubmittedUserProfile, label = (t model.translations "profile.btn_save") |> text |> el [] }

      page =
        [ image [ alpha 0.5, centerX, width <| px 75 ] { src = svgPath "user_default_avatar", description = "user menu" }
        , (t model.translations "profile.lbl_email") ++ ": " ++ userProfile.email |> captionNowrap [ centerX ]
        , [ firstNameField, lastNameField ] |> wrappedRow [ spacing 20 ]
        , viewDataCollectionConsentToggle model userProfile.isDataCollectionConsent
        , [ saveButton ] |> wrappedRow [ spacing 20, height <| px 40 ]
        ]
        |> column [ spacing 30, padding 5 ]
        |> milkyWhiteCenteredContainer
  in
      (page, [])


viewDataCollectionConsentToggle : Model -> Bool -> Element Msg
viewDataCollectionConsentToggle model enabled =
  [ (t model.translations "profile.lbl_allow_data_collection_consent") |> bodyWrap [ width fill ]
  , viewToggleIndicator enabled (if enabled then "PrimaryGreenBackground" else "") |> el [ paddingRight 10 ]
  ]
  |> row [ spacing 10, onClick (ToggleDataCollectionConsent enabled), htmlClass "CursorPointer" ]
  |> el [ alignRight ]
