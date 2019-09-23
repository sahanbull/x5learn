module View.Card exposing (viewPathway, viewOerGrid, viewOerCard)

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
import View.Bubblogram exposing (..)

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



viewOerGrid : Model -> Playlist -> Element Msg
viewOerGrid model playlist =
  let
      helper id result =
        case Dict.get id model.cachedOers of
          Nothing ->
            result

          Just oer ->
            oer :: result

      oers =
        playlist.oerIds
        |> List.foldr helper []
  in
      if oers |> List.isEmpty then
        none
      else
        let
            rowHeight =
              cardHeight + verticalSpacingBetweenCards

            nColumns =
              if model.windowWidth > 1500 then
                3
              else
                2

            nrows =
              ((List.length oers) + (nColumns-1)) // nColumns

            leftMargin =
              (model.windowWidth - navigationDrawerWidth - nColumns*cardWidth - (nColumns-1)*horizontalSpacingBetweenCards) // 2

            cardPositionAtIndex index =
              let
                  x =
                    modBy nColumns index

                  y =
                    index//nColumns
              in
                  { x = x * (cardWidth + horizontalSpacingBetweenCards) + leftMargin |> toFloat, y = y * rowHeight + 110 |> toFloat }

            cards =
              oers
              |> List.indexedMap (\index oer -> viewOerCard model [] (cardPositionAtIndex index) (playlist.title++"-"++ (String.fromInt index)) True oer)
              |> List.reverse
              |> List.map inFront
        in
            [ playlist.title |> captionNowrap [ paddingLeft <| round <| (cardPositionAtIndex 0).x - 20, moveDown 55, Font.color grey80 ]
            -- [ playlist.title |> subSubheaderWrap [ whiteText, centerX ]
            -- [ playlist.title |> (if isLabStudy1 model then captionNowrap [ Font.color grey80 ] else subheaderWrap [ whiteText ])
            ]
            -- |> column ([ height (rowHeight * nrows + 100|> px), spacing 20, padding 20, width fill, Background.color transparentWhite, Border.rounded 2 ] ++ cards)
            |> column ([ height (rowHeight * nrows + 100|> px), spacing 20, padding 20, width fill, Border.rounded 2 ] ++ cards)


viewOerCard : Model -> List Fragment -> Point -> String -> Bool -> Oer -> Element Msg
viewOerCard ({pageScrollState} as model) recommendedFragments position barId enableShadow oer =
  let
      isCardInView =
        position.y + cardHeight > pageScrollState.scrollTop && position.y < pageScrollState.scrollTop + pageScrollState.viewHeight
  in
      if isCardInView then
        viewOerCardVisibleContent model recommendedFragments position barId enableShadow oer
      else
        none


viewOerCardVisibleContent : Model -> List Fragment -> Point -> String -> Bool -> Oer -> Element Msg
viewOerCardVisibleContent model recommendedFragments position barId enableShadow oer =
  let
      isHovering =
        model.hoveringOerId == Just oer.id

      fragmentsBar =
        case Dict.get oer.id model.wikichunkEnrichments of
          Nothing ->
            [ viewLoadingSpinner |> el [ moveDown 80, width fill ] |> inFront ]

          Just enrichment ->
            if enrichment.errors then
              []
            else
              viewFragmentsBar model oer enrichment.chunks recommendedFragments cardWidth barId
              |> el [ width fill, moveDown imageHeight ]
              |> inFront
              |> List.singleton

      title =
        let
            fontSize =
              if String.length oer.title < 90 then
                Font.size 16
              else
                Font.size 14
        in
            oer.title
            |> subSubheaderWrap [ paddingXY 16 0, centerY, fontSize ]
            |> el [ height <| px 72, clipY, moveDown 181 ]
            |> inFront

      -- modalityIcon =
      --   if hasYoutubeVideo oer.url then
      --     image [ moveRight 280, moveUp 50, width (px 30) ] { src = svgPath "playIcon", description = "play icon" }
      --   else
      --     none

      bottomInfo =
        let
            dateStr =
              if oer.date |> String.startsWith "Published on " then oer.date |> String.dropLeft ("Published on " |> String.length) else oer.date

            date =
              dateStr |> captionNowrap [ alignLeft ]

            provider =
              oer.provider |> domainOnly |> truncateSentence 32 |> captionNowrap [ if dateStr=="" then alignLeft else centerX ]

            duration =
              oer.duration |> captionNowrap [ alignRight, paddingRight 8 ]

            favoriteButton =
              let
                  heart =
                    viewHeartButton model oer.id
                    |> el [ moveRight 12, moveUp 14 ]
              in
                  none
                  |> el [ alignRight, width <| px 34, inFront heart ]


            content =
              [ date, provider, duration, favoriteButton ]
        in
            content
            |> row [ width fill, paddingXY 16 0, moveDown 255 ]
            |> inFront

      tagCloudView tagCloud =
        tagCloud
        |> List.indexedMap (\index label -> label |> wrapText [ Font.size (20-index), Font.color <| rgba 0 0 0 (0.8- ((toFloat index)/15)), height fill ])
        |> column [ padding 16, spacing 6, height <| px <| imageHeight-16 ]
        |> el [ paddingBottom 16 ]

      -- hoverPreview =
      --   if chunksFromOerId model oer.url |> List.isEmpty then
      --     carousel
      --   else
      --     case model.tagClouds |> Dict.get oer.id of
      --       Nothing ->
      --         carousel

      --       Just tagCloud ->
      --         tagCloudView tagCloud

      widthOfCard =
        width (px cardWidth)

      heightOfCard =
        height (px cardHeight)

      clickHandler =
        case openInspectorOnPress model oer of
          Just msg ->
            [ onClick msg ]

          Nothing ->
            []

      shadow =
        if enableShadow then [ htmlClass "materialCard" ] else [ Border.width 1, borderColorDivider ]

      card =
        viewCarousel model isHovering oer
        |> el ([ widthOfCard, heightOfCard, onMouseEnter (SetHover (Just oer.id)), onMouseLeave (SetHover Nothing), title, bottomInfo ] ++ fragmentsBar ++ shadow ++ clickHandler)

      wrapperAttrs =
        -- [ htmlClass "CloseInspectorOnClickOutside", widthOfCard, heightOfCard, inFront <| button [] { onPress = openInspectorOnPress model oer, label = card }, moveRight position.x, moveDown position.y ]
        [ htmlClass "CloseInspectorOnClickOutside OerCard", widthOfCard, heightOfCard, inFront <| card, moveRight position.x, moveDown position.y, htmlDataAttribute <| String.fromInt oer.id, htmlClass "CursorPointer" ]
  in
      none
      |> el wrapperAttrs


viewCarousel : Model -> Bool -> Oer -> Element Msg
viewCarousel model isHovering oer =
  let
      upperImage attrs url =
        none
        |> el ([ width fill, height <| px <| imageHeight, Background.image <| url, htmlClass (if isFromVideoLecturesNet oer then "materialHoverZoomThumb-videolectures" else "materialHoverZoomThumb") ] ++ attrs)
  in
      case oer.images of
        [] ->
          imgPath "thumbnail_unavailable.jpg"
          -- viewMediatypeIcon oer.mediatype isHovering
          |> upperImage []

        [ singleImage ] ->
          singleImage
          |> upperImage []

        firstImage :: otherImages ->
          let
              imageIndex =
                (millisSince model model.timeOfLastMouseEnterOnCard) // 1500 + 1
                |> modBy (List.length oer.images)

              currentImageUrl =
                oer.images
                |> selectByIndex imageIndex firstImage

              nextImageUrl =
                oer.images
                |> selectByIndex (imageIndex+1) firstImage

              -- dot url =
              --   none
              --   |> el [ width (px 6), height (px 6), Border.rounded 3, Background.color <| if url==currentImageUrl then white else semiTransparentWhite ]

              -- dotRow =
              --   oer.images
              --   |> List.map dot
              --   |> row [ spacing 5, moveDown 160, moveRight 16 ]
              --   |> inFront

              imageCounter txt =
                txt
                |> text
                |> el [ paddingXY 5 3, Font.size 12, whiteText, Background.color <| rgba 0 0 0 0.5, moveDown 157 ]
                |> inFront

              preloadImage url =
                url
                |> upperImage [ width (px 1), alpha 0.01 ]
                |> behindContent
          in
              currentImageUrl
              |> upperImage [ preloadImage nextImageUrl, imageCounter <| (imageIndex+1 |> String.fromInt) ++ " / " ++ (oer.images |> List.length |> String.fromInt) ]


-- viewMediatypeIcon mediatype isHovering =
--   let
--       stub =
--         if List.member mediatype [ "video", "audio", "text" ] then
--           "mediatype_" ++ mediatype
--         else
--           "mediatype_unknown"
--   in
--       image [ semiTransparent, centerX, centerY, width (px <| if isHovering then 60 else 50) ] { src = (svgPath stub), description = "" }
--       |> el [ width fill, height (px imageHeight), Background.color x5color ]
