module View.Card exposing (viewPathway, viewOerGrid, cardHeight, viewOerCard)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Json.Decode
import Dict exposing (Dict)

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)
import Animation exposing (..)


viewPathway model pathway =
  "pathway goes here"
  |> text
    -- let
    --     grid =
    --       oerPathwayContainer model pathway.fragments pathway.rationale (pathway.fragments |> List.map .oer)
    --       |> List.map inFront

    --     slotAtIndex index oer =
    --       let
    --           x =
    --             modBy 3 index

    --           y =
    --             index//3
    --       in
    --           viewOerCard model recommendedFragments { x = x*370 + 180 |> toFloat, y = y*310 + 70 |> toFloat } (gridKey ++"-"++ (String.fromInt index)) oer
  -- in
    --   oers
    --   |> List.indexedMap slotAtIndex
    --   |> List.reverse -- Rendering the cards in reverse order so that popup menus (to the bottom and right) are rendered above the neighboring card, rather than below.

    -- in
    --     [ pathway.rationale |> headlineWrap []
    --     ]
    --     |> column ([ height (px 380), spacing 20, padding 20, width fill, Background.color transparentWhite, Border.rounded 2 ] ++ grid)



viewOerGrid model playlist =
  if playlist.oers |> List.isEmpty then
    none
  else
    let
        rowHeight =
          cardHeight + 50

        nrows =
          ((List.length playlist.oers) + 2) // 3

        cardPositionAtIndex index =
          let
              x =
                modBy 3 index

              y =
                index//3
          in
              { x = x * (cardWidth + 50) +180 |> toFloat, y = y * rowHeight + 70 |> toFloat }

        cards =
          playlist.oers
          |> List.indexedMap (\index oer -> viewOerCard model [] (cardPositionAtIndex index) (playlist.title++"-"++ (String.fromInt index)) oer)
          |> List.reverse
          |> List.map inFront
    in
        [ playlist.title |> subheaderWrap [ whiteText ]
        ]
        -- |> column ([ height (rowHeight * nrows + 100|> px), spacing 20, padding 20, width fill, Background.color transparentWhite, Border.rounded 2 ] ++ cards)
        |> column ([ height (rowHeight * nrows + 100|> px), spacing 20, padding 20, width fill, Border.rounded 2 ] ++ cards)


viewOerCard : Model -> List Fragment -> Point -> String -> Oer -> Element Msg
viewOerCard model recommendedFragments position barId oer =
  let
      hovering =
        model.hoveringOerUrl == Just oer.url

      imageHeight =
        175

      upperImage attrs url =
        none
        |> el ([ width fill, height <| px <| imageHeight, Background.image <| url, htmlClass (if isFromVideoLecturesNet oer then "materialHoverZoomThumb-videolectures" else "materialHoverZoomThumb") ] ++ attrs)

      imageCounter txt =
        txt
        |> text
        |> el [ paddingXY 5 3, Font.size 12, whiteText, Background.color <| rgba 0 0 0 0.5, moveDown 157 ]
        |> inFront

      singleThumbnail =
        let
            attrs =
              case oer.images of
                first :: (second :: _) ->
                  [ preloadImage second ]

                _ ->
                  []
        in
            oer.images
            |> List.head
            |> Maybe.withDefault (imgPath "thumbnail_unavailable.jpg")
            |> upperImage attrs

      fragmentsBar =
        if oer.wikichunks |> List.isEmpty then
          []
        else
          [ inFront <| viewFragmentsBar model oer recommendedFragments cardWidth barId ]

      preloadImage url =
        url
        |> upperImage [ width (px 1), alpha 0.01 ]
        |> behindContent

      mediatypeIconInPlaceOfThumbnail =
        let
            stub =
              if List.member oer.mediatype [ "video", "audio", "text" ] then
                "mediatype_" ++ oer.mediatype
              else
                "mediatype_unknown"

            weblink =
              newTabLink [ centerX, alpha 0.7 ] { url = oer.url, label = oer.url |> shortUrl 40 |> bodyWrap [ whiteText ] }
              |> el [ width (px cardWidth), moveDown 130 ]
        in
            image [ semiTransparent, centerX, centerY, width (px <| if hovering then 60 else 50) ] { src = (svgPath stub), description = "" }
            |> el [ width fill, height (px imageHeight), Background.color x5color, inFront weblink ]

      carousel =
        case oer.images of
          [] ->
            mediatypeIconInPlaceOfThumbnail

          [ _ ] ->
            singleThumbnail

          head :: rest ->
            let
                imageIndex =
                  (millisSince model model.timeOfLastMouseEnterOnCard) // 1500 + 1
                  |> modBy (List.length oer.images)

                currentImageUrl =
                  oer.images
                  |> selectByIndex imageIndex head

                nextImageUrl =
                  oer.images
                  |> selectByIndex (imageIndex+1) head

                -- dot url =
                --   none
                --   |> el [ width (px 6), height (px 6), Border.rounded 3, Background.color <| if url==currentImageUrl then white else semiTransparentWhite ]

                -- dotRow =
                --   oer.images
                --   |> List.map dot
                --   |> row [ spacing 5, moveDown 160, moveRight 16 ]
                --   |> inFront

            in
                currentImageUrl
                |> upperImage [ preloadImage nextImageUrl, imageCounter <| (imageIndex+1 |> String.fromInt) ++ " / " ++ (oer.images |> List.length |> String.fromInt) ]

      title =
        oer.title |> subheaderWrap [ height (fill |> maximum 64), clipY ]

      modalityIcon =
        if hasYoutubeVideo oer then
          image [ moveRight 280, moveUp 50, width (px 30) ] { src = svgPath "playIcon", description = "play icon" }
        else
          none

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

      tagCloudView tagCloud =
        tagCloud
        |> List.indexedMap (\index label -> label |> wrapText [ Font.size (20-index), Font.color <| rgba 0 0 0 (0.8- ((toFloat index)/15)), height fill ])
        |> column [ padding 16, spacing 6, height <| px <| imageHeight-16 ]
        |> el [ paddingBottom 16 ]

      hoverPreview =
        if oer.wikichunks |> List.isEmpty then
          carousel
        else
          case model.tagClouds |> Dict.get oer.url of
            Nothing ->
              carousel

            Just tagCloud ->
              tagCloudView tagCloud

      info =
        [ title
        , bottomRow
        ]
        |> column ([ padding 16, width fill, height fill, inFront modalityIcon ] ++ fragmentsBar)

      closeButton =
        -- if hovering then
        --   button [ alignRight ] { onPress = Nothing, label = closeIcon }
        -- else
          none

      widthOfCard =
        width (px cardWidth)

      heightOfCard =
        height (px cardHeight)

      card =
        [ (if hovering then hoverPreview else carousel)
        , info
        ]
        |> column [ widthOfCard, heightOfCard, htmlClass "materialCard", onMouseEnter (SetHover (Just oer.url)), onMouseLeave (SetHover Nothing) ]

      onPress =
        case model.inspectorState of
          Nothing ->
            Just (InspectSearchResult oer 0)

          _ ->
            Nothing

      cardAttrs =
        [ htmlClass "CloseInspectorOnClickOutside", widthOfCard, heightOfCard, inFront <| button [] { onPress = onPress, label = card }, inFront closeButton, moveRight position.x, moveDown position.y ]
  in
      none
      |> el cardAttrs


cardWidth =
  332


cardHeight =
  280
