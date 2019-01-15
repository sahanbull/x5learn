module View.Pages.SearchResults exposing (viewPageSearchResults)

import Url

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode

viewPageSearchResults : Model -> UserState -> Element Msg
viewPageSearchResults model userState =
  let
      modal =
        case userState.inspectedSearchResult of
          Nothing ->
            []

          Just oer ->
            [ inFront <| viewModal userState oer ]
  in
      viewSearchResults model userState modal


viewModal userState oer =
  let
      closeIcon =
        image [  materialDarkAlpha, hoverCircleBackground] { src = svgPath "close", description = "close" }

      header =
        [ oer.title |> headlineWrap []
        , button [] { onPress = Just (UninspectSearchResult userState), label = closeIcon }
        ]
        |> row [ width fill, spacing 16 ]

      player =
        image [ width (px 873) ] { src = imgPath "mockVideoPlayer.png", description = "mockup video player" }

      footerButton label =
        button [ hoverCircleBackground ] { onPress = Nothing, label = label }

      footer =
        [ newTabLink [] { url = "http://videolectures.net", label = providerLink }
        , none |> el [ width fill ]
        , actions
        ]
        |> row [ spacing 20, width fill ]

      providerLink =
        [ "videolectures.net" |> bodyNoWrap [ alignLeft]
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
        , footer
        ]
        |> column [ Background.color white, centerX, centerY, padding 16, spacing 16 ]

      scrim =
        none
        |> el [ Background.color <| rgb 0 0 0, alpha 0.32, width fill, height fill, onClickNoBubble (UninspectSearchResult userState) ]
  in
      sheet
      |> el [ width fill, height fill, behindContent scrim ]


viewSearchResults model userState modal =
  mockSearchResults
  |> List.indexedMap (viewSearchResult userState (List.isEmpty modal))
  |> wrappedRow [ centerX, spacing 30, width (fill |> maximum 1100) ]
  |> el ([ padding 20, spacing 20, width fill, height fill ] ++ modal)


viewSearchResult userState isClickable index oer =
  let
      thumbnail =
        none
        |> el [ width fill, height (px 175), Background.image <| imgPath ("mockthumb" ++ (index+1 |> String.fromInt) ++ ".jpg"), htmlClass "materialHoverZoomThumb" ]

      title =
        oer.title |> subheaderWrap [ height fill ]

      playIcon =
        image [ moveRight 260, moveDown 160, width (px 30) ] { src = svgPath "playIcon", description = "play icon" }

      bottomRow =
        [ "videolectures.net" |> captionNowrap []
        , "90 min" |> captionNowrap [ alignRight ]
        ]
        |> row [ width fill ]

      info =
        [ title
        , bottomRow
        ]
        |> column [ padding 16, width fill, height fill ]

      card =
        [ thumbnail
        , info
        ]
        |> column [ width (px 332), height (px 280), htmlClass "materialCard", inFront playIcon ]
  in
      if isClickable then
        button [] { onPress = Just (InspectSearchResult userState oer), label = card }
      else
        -- card -- TODO In theory, the cards wouldn't need to be buttons when the modal is active. However, toggling between button and non-button causes a flicker issue when closing the modal, at least on Chrome desktop. Keyboard users should be able to tab through the cards but not when the modal is active. What is the best way to achieve this?
        button [] { onPress = Nothing, label = card }
