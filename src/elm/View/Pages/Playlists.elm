module View.Pages.Playlists exposing (viewPlaylistsPage)

import Url
import Dict
import Set

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import Animation exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewPlaylistsPage : Model -> PageWithModal
viewPlaylistsPage model =
  let
      modal =
        []

      page =
        model.playlists
        |> List.map (viewPlaylist model)
        |> column [ width fill, height fill ]
  in
      (page, modal)


viewPlaylist model playlist =
  [ playlist.title |> headlineWrap []
  , playlist.oers |> List.map (viewOerCardInPlaylist model) |> row [ spacing 20 ]
  ]
  |> column [ spacing 20, padding 20, width fill ]


viewOerCardInPlaylist model oer =
  let
      hovering =
        model.hoveringOerUrl == Just oer.url

      upperImage attrs url =
        none
        |> el ([ width fill, height (px 175), Background.image <| url, htmlClass (if isFromVideoLecturesNet oer then "materialHoverZoomThumb-videolectures" else "materialHoverZoomThumb") ] ++ attrs)

      imageCounter txt =
        txt
        |> text
        |> el [ paddingXY 5 3, Font.size 12, primaryWhite, Background.color <| rgba 0 0 0 0.5, moveDown 157 ]
        |> inFront

      thumbnail =
        let
            attrs =
              case oer.imageUrls of
                first :: (second :: _) ->
                  [ preloadImage second ]

                _ ->
                  if hovering then [ imageCounter "1 / 1" ] else []
        in
            oer.imageUrls |> List.head |> Maybe.withDefault (imgPath "thumbnail_unavailable.jpg")
            |> upperImage attrs

      preloadImage url =
        url
        |> upperImage [ width (px 1), alpha 0.01 ]
        |> behindContent

      carousel =
        case oer.imageUrls of
          [] ->
            thumbnail

          [ _ ] ->
            thumbnail

          head :: rest ->
            let
                imageIndex =
                  (millisSince model model.timeOfLastMouseEnterOnCard) // 1500 + 1
                  |> modBy (List.length oer.imageUrls)

                currentImageUrl =
                  oer.imageUrls
                  |> selectByIndex imageIndex head

                nextImageUrl =
                  oer.imageUrls
                  |> selectByIndex (imageIndex+1) head

                -- dot url =
                --   none
                --   |> el [ width (px 6), height (px 6), Border.rounded 3, Background.color <| if url==currentImageUrl then white else semiTransparentWhite ]

                -- dotRow =
                --   oer.imageUrls
                --   |> List.map dot
                --   |> row [ spacing 5, moveDown 160, moveRight 16 ]
                --   |> inFront

            in
                currentImageUrl
                |> upperImage [ preloadImage nextImageUrl, imageCounter <| (imageIndex+1 |> String.fromInt) ++ " / " ++ (oer.imageUrls |> List.length |> String.fromInt) ]

      title =
        oer.title |> subheaderWrap [ height (fill |> maximum 64), clipY ]

      modalityIcon =
        if hasVideo oer then
          image [ moveRight 280, moveDown 160, width (px 30) ] { src = svgPath "playIcon", description = "play icon" }
        else
          none
        -- let
        --     stub =
        --       if hasVideo oer then
        --         "playIcon"
        --       else
        --         "textIcon"
        -- in
        --     image [ moveRight 280, moveDown 160, width (px 30) ] { src = svgPath stub, description = "play icon" }

      bottomRow =
        let
            content =
              if oer.duration=="" then
                [ oer.provider |> domainOnly |> captionNowrap []
                , oer.date |> captionNowrap [ alignRight ]
                ]
              else
                [ oer.date |> captionNowrap []
                , oer.provider |> domainOnly |> captionNowrap [ centerX ]
                , oer.duration |> captionNowrap [ alignRight ]
                ]
        in
            content
            |> row [ width fill ]

      info =
        [ title
        , bottomRow
        ]
        |> column [ padding 16, width fill, height fill ]

      card =
        [ (if hovering then carousel else thumbnail)
        , info
        ]
        |> column [ width (px 332), height (px 280), htmlClass "materialCard", inFront modalityIcon, onMouseEnter (SetHover (Just oer.url)), onMouseLeave (SetHover Nothing) ]
  in
      button [] { onPress = Nothing, label = card }
