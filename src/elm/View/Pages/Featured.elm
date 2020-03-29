module View.Pages.Featured exposing (viewFeaturedPage)

import Url

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Font as Font

import Model exposing (..)
import View.Utility exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Time exposing (millisToPosix)

import Json.Decode as Decode


{-| Render landing page including featured OER content
-}
viewFeaturedPage : Model -> PageWithInspector
viewFeaturedPage model =
  let
      title =
        if isLabStudy1 model then
          [ "Please follow the researcher's instructions" |> text |> el [ Font.size 20, centerX ]
          ]
          |> column [ centerX, centerY, spacing 30 ]
          |> el [ width fill, height <| fillPortion 3 ]
        else
          userGreeting model
          |> column [ centerX, centerY, spacing 30 ]
          |> el [ width fill, height <| fillPortion 3 ]

      page =
        [ title
        , if isLabStudy1 model then none else viewFeaturedOers model
        ]
        |> column [ centerX, paddingXY 15 80, spacing 20, width fill, height fill ]
  in
      (page, viewInspector model)


{-| Render multiple OERs (when loaded)
-}
viewFeaturedOers : Model -> Element Msg
viewFeaturedOers model =
  case model.featuredOers of
    Nothing ->
      viewLoadingSpinner

    Just oers ->
      Playlist "Featured Content" Nothing Nothing Nothing Nothing (Time.millisToPosix 0) Nothing True Nothing  (Time.millisToPosix 0) oers
      |> viewOerGrid model


{-| Big text to show to the user
-}
userGreeting : Model -> List (Element Msg)
userGreeting model =
  let
      headingAttrs =
        [ whiteText, Font.size 60, centerX, htmlClass "BigHeadingFont" ]
  in
  if isLoggedIn model then
    [ "Welcome back" |> text |> el headingAttrs
    ]
  else
    [ "Welcome to X5Learn" |> text |> el headingAttrs
    , "Find your personal learning pathway" |> text |> el [ whiteText, Font.size 20, centerX ]
    ]
