module View.Pages.Resource exposing (viewResourcePage)

import Url
import Dict
import Set
import List.Extra

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)
import View.Noteboard exposing (..)
import View.Html5VideoPlayer exposing (..)


import Msg exposing (..)

import Json.Decode as Decode


viewResourcePage : Model -> UserState -> PageWithModal
viewResourcePage model userState =
  let
      page =
        case model.currentResource of
          Nothing ->
            viewLoadingSpinner

          Just (Loaded oerUrl) ->
            viewResource model userState (getCachedOerWithBlankDefault model oerUrl)

          Just Error ->
            viewCenterNote "The requested resource was not found."
  in
      (page, [])


viewResource : Model -> UserState -> Oer -> Element Msg -- TODO remove some code duplication with Inspector.elm
viewResource model userState oer =
  let
      header =
        case oer.title of
          "" ->
            "Title unavailable" |> headlineWrap [ Font.italic ]

          title ->
            title |> headlineWrap []

      linkToFile =
        newTabLink [] { url = oer.url, label = oer.url |> bodyWrap [] }

      player =
        case getYoutubeVideoId oer.url of
          Nothing ->
            if isVideoFile oer.url then
              viewHtml5VideoPlayer model oer.url
            else
              none

          Just youtubeId ->
            let
                startTime =
                  0
            in
                embedYoutubePlayer youtubeId startTime

      description =
        case oer.description of
          "" ->
            "No description available" |> italicText |> el [ paddingTop 30 ]

          desc ->
            desc
            |> String.split("\n")
            |> List.filter (\line -> String.length line > 2)
            |> List.map (bodyWrap [])
            |> column [ spacing 7, height fill, scrollbarY, paddingTop 30 ]

      mainSection =
        let
            horizontalPadding =
              if model.windowWidth < 1300 then
                20
              else
                50
        in
            [ header |> el [ paddingBottom 20 ]
            , player
            , fragmentsBarWrapper
            ]
            |> column [ width fill, moveLeft (sidebarWidth model |> toFloat), Background.color <| grey 230, height fill, borderLeft 1, borderColorLayout, paddingXY horizontalPadding 30 ]

      sidebar =
        viewNoteboard model userState oer.url
        |> el [ width <| px (sidebarWidth model), height fill, alignTop, borderLeft 1, borderColorLayout, paddingTRBL 0 0 0 15, moveRight ((sheetWidth model) - (sidebarWidth model) |> toFloat), paddingXY 20 30, Background.color white ]

      body =
        [ sidebar
        , mainSection
        ]
        |> row [ height fill, width fill ]

      footer =
        []

      fragmentsBarWrapper =
        [ description
        , [ providerLink, linkToFile ] |> column [ width fill, spacing 15, paddingTop 30 ]
        , fragmentsBar
        ]
        |> column [ width (px playerWidth), height <| px fragmentsBarWrapperHeight, moveDown 1 ]

      fragmentsBar =
        if hasYoutubeVideo oer.url then
          case chunksFromUrl model oer.url of
            [] ->
              none

            wikichunks ->
              let
                  content =
                    viewFragmentsBar model userState oer wikichunks (model.nextSteps |> Maybe.withDefault [] |> List.concatMap .fragments) playerWidth "inspector" True
                    |> el [ width (px playerWidth), height (px 16) ]
              in
                  none |> el [ inFront content, moveUp (fragmentsBarWrapperHeight - fragmentsBarHeight) ]
        else
          none

      providerLink =
        case oer.provider of
          "" ->
            none

          provider ->
            [ "Provider:" |> bodyNoWrap []
            , newTabLink [] { url = oer.url, label = provider |> trimTailingEllipsisIfNeeded |> bodyNoWrap [] }
            ]
            |> row [ spacing 10 ]
  in
      body


sidebarWidth model =
  460
  |> min (model.windowWidth - navigationDrawerWidth - playerWidth - 100)


fragmentsBarWrapperHeight =
  200


sheetWidth model =
  model.windowWidth - navigationDrawerWidth
