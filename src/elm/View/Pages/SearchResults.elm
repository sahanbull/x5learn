module View.Pages.SearchResults exposing (viewPageSearchResults)

import Time exposing (posixToMillis)
import Url
import Dict

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

import Json.Decode as Decode

viewPageSearchResults : Model -> SearchState -> (Element Msg, (List (Attribute Msg)))
viewPageSearchResults model searchState =
  let
      modal =
        case searchState.inspectedSearchResult of
          Nothing ->
            []

          Just oer ->
            [ inFront <| viewModal model searchState oer ]
  in
      (viewSearchResults model searchState (List.isEmpty modal), modal)


viewModal model searchState oer =
  let
      closeIcon =
        image [  materialDarkAlpha, hoverCircleBackground] { src = svgPath "close", description = "close" }

      header =
        [ oer.title |> headlineWrap []
        , button [] { onPress = Just UninspectSearchResult, label = closeIcon }
        ]
        |> row [ width fill, spacing 16 ]

      player =
        case getYoutubeId oer of
          Nothing ->
            none

          Just youtubeId ->
            embedYoutubePlayer youtubeId

      description =
        oer.description
        |> bodyWrap []

      footerButton label =
        button [ hoverCircleBackground ] { onPress = Nothing, label = label }

      footer =
        [ newTabLink [] { url = oer.url, label = providerLink }
        , none |> el [ width fill ]
        , actions
        ]
        |> row [ spacing 20, width fill ]

      providerLink =
        [  oer.provider |> bodyNoWrap [ alignLeft]
        , image [ alignLeft, materialDarkAlpha, width (px 20) ] { src = svgPath "navigate_next", description = "external link" }
        ]
        |> row [ alignLeft, width fill ]

      actions =
        [ footerButton <| image [ materialDarkAlpha ] { src = svgPath "share", description = "share icon" }
        , footerButton <| image [ materialDarkAlpha ] { src = svgPath "bookmark_outline", description = "bookmark icon" }
        , footerButton <| image [ materialDarkAlpha ] { src = svgPath "more_vert", description = "more icon" }
        ]
        |> row [ spacing 20, alignRight ]

      sheet =
        [ header
        , player
        , description
        , footer
        ]
        |> column [ width (fill |> maximum 752), Background.color white, centerX, centerY, padding 16, spacing 16, htmlId modalHtmlId ]

      scrim =
        none
        |> el [ Background.color <| rgb 0 0 0, alpha 0.32, width fill, height (fill |> maximum (model.windowHeight - pageHeaderHeight)), moveDown pageHeaderHeight, onClickNoBubble UninspectSearchResult ]
  in
      sheet
      |> el [ width fill, height fill, behindContent scrim ]


viewSearchResults model searchState clickEnabled =
  case searchState.searchResults of
    Nothing ->
      "loading..." |> text

    Just oers ->
      oers
      |> List.indexedMap (viewSearchResult model searchState clickEnabled)
      |> wrappedRow [ centerX, spacing 30, width (fill |> maximum 1100) ]
      |> el [ padding 20, spacing 20, width fill, height fill ]


viewSearchResult model searchState clickEnabled index oer =
  let
      hovering =
        model.hoveringOerUrl == Just oer.url

      upperImage attrs url =
        none
        |> el ([ width fill, height (px 175), Background.image <| url, htmlClass "materialHoverZoomThumb" ] ++ attrs)

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
                  ((posixToMillis model.currentTime) - (posixToMillis model.timeOfLastMouseEnterOnCard)) // 2000 + 1

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
        oer.title |> subheaderWrap [ height fill ]

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
        [ oer.provider |> domainOnly |> captionNowrap []
        -- , "90 min" |> captionNowrap [ alignRight ]
        ]
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
      if clickEnabled then
        button [] { onPress = Just (InspectSearchResult oer), label = card }
      else
        button [] { onPress = Nothing, label = card }


selectByIndex : Int -> a -> List a -> a
selectByIndex index fallback elements =
  elements
  |> List.drop (index |> modBy (List.length elements))
  |> List.head
  |> Maybe.withDefault fallback


domainOnly : String -> String
domainOnly url =
  url |> String.split "//" |> List.drop 1 |> List.head |> Maybe.withDefault url |> String.split "/" |> List.head |> Maybe.withDefault url
