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


{-| Render the user profile page
-}
viewProfilePage : Model -> UserProfile -> UserProfileForm -> PageWithInspector
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
            "✓ Saved" |> bodyWrap [ greyText, width fill ]
          else
            button [ paddingXY 16 8, width fill, Background.color primaryGreen, whiteText ] { onPress = Just SubmittedUserProfile, label = "Save" |> text |> el [] }

      page =
        [ image [ alpha 0.5, centerX, width <| px 75 ] { src = svgPath "user_default_avatar", description = "user menu" }
        , "Email: " ++ userProfile.email |> captionNowrap [ centerX ]
        , [ firstNameField, lastNameField ] |> wrappedRow [ spacing 20 ]
        , viewDataCollectionConsentToggle userProfile.isDataCollectionConsent
        , [ saveButton ] |> wrappedRow [ spacing 20, height <| px 40 ]
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
