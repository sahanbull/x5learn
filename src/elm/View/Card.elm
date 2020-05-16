module View.Card exposing (viewOerGrid, viewOerCard)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Json.Decode
import Dict exposing (Dict)

import Model exposing (..)
import View.Utility exposing (..)
import View.Explainer exposing (..)
import View.ContentFlowBar exposing (..)
import View.Bubblogram exposing (..)

import Msg exposing (..)
import Animation exposing (..)

import Url.Builder

{-| Render a list of OERs as cards on a grid
-}
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
              |> List.indexedMap (\index oer -> viewOerCard model (cardPositionAtIndex index) (playlist.title++"-"++ (String.fromInt index)) True oer)
              -- |> List.reverse
              |> List.map inFront

            overviewTypeMenu =
              if isLabStudy1 model then [] else [ viewOverviewTypeMenu model |> inFront ]

            playlistButtons =
              if model.searchIsPlaylist then [ viewPlaylistButtons model |> inFront ] else []

            rawAttributes =
              [ height (rowHeight * nrows + 100 |> px), spacing 20, padding 20, width fill ] ++ cards ++ overviewTypeMenu ++ playlistButtons

            attrs =
              if model.popup == Just OverviewTypePopup then
                rawAttributes -- render the menu in front of the card content
              else
                rawAttributes |> List.reverse -- render the card content (particularly the speech bubbles) in front of the menu
        in
            [ playlist.title |> captionNowrap [ paddingLeft <| round <| (cardPositionAtIndex 0).x - 20, moveDown 55, Font.color grey80 ]
            ]
            |> column attrs


{-| Render an OER as a card
    (only if it is within screen boundaries, taking scrolling into account)
-}
viewOerCard : Model -> Point -> String -> Bool -> Oer -> Element Msg
viewOerCard ({pageScrollState} as model) position barId enableShadow oer =
  let
      isCardInView =
        position.y + (toFloat cardHeight) > pageScrollState.scrollTop && position.y < pageScrollState.scrollTop + pageScrollState.viewHeight
  in
      if isCardInView then
        viewVisibleOerCard model position barId enableShadow oer
      else
        none


{-| Render the OER as a card, having previously ensured that it is within screen boundaries
-}
viewVisibleOerCard : Model -> Point -> String -> Bool -> Oer -> Element Msg
viewVisibleOerCard model position barId enableShadow oer =
  let
      contentFlowBar =
        case Dict.get oer.id model.wikichunkEnrichments of
          Nothing ->
            [ viewLoadingSpinner |> el [ moveDown 80, width fill ] |> inFront ]

          Just enrichment ->
            if enrichment.errors then
              []
            else
              viewContentFlowBar model oer enrichment.chunks cardWidth barId
              |> el [ width fill, moveDown (toFloat imageHeight) ]
              |> inFront
              |> List.singleton

      (graphic, popup) =
        case model.overviewType of
          ThumbnailOverview ->
            (viewCarousel model oer, [])

          BubblogramOverview bubblogramType ->
            case Dict.get oer.id model.wikichunkEnrichments of
              Nothing ->
                (none |> el [ width fill, height (px imageHeight), Background.color primaryGreen ]
                , [])

              Just enrichment ->
                if enrichment.errors then
                  if isVideoFile oer.url then
                    (image [ alpha 0.9, centerX, centerY ] { src = svgPath "playIcon", description = "Video file" }
                     |> el [ width fill, height (px imageHeight), Background.color oxfordBlue ]
                    , [])
                  else
                    ("no preview available" |> captionNowrap [ alpha 0.75, whiteText, centerX, centerY ]
                     |> el [ width fill, height (px imageHeight), Background.color oxfordBlue ]
                    , [])
                else
                  case enrichment.bubblogram of
                    Nothing -> -- shouldn't happen for more than a second
                      (none |> el [ width <| px cardWidth, height <| px imageHeight, Background.color <| rgb255 0 10 20, inFront viewLoadingSpinner ], [])

                    Just bubblogram ->
                      viewBubblogram model bubblogramType oer.id bubblogram

      availableTranslations =
        if oer.mediatype/="video" || Dict.isEmpty oer.translations then
          []
        else
          let
              languages =
                oer.translations
                |> Dict.keys
          in
              "Subtitles: " ++ (languages |> String.join " ")
              |> captionNowrap [ paddingXY 3 2, Background.color slightlyTransparentBlack, greyText ]
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

      bottomInfo =
        let
            dateStr =
              if oer.date |> String.startsWith "Published on " then oer.date |> String.dropLeft ("Published on " |> String.length) else oer.date

            date =
              dateStr |> captionNowrap [ alignLeft ]

            provider =
              oer.provider |> domainOnly |> truncateSentence 32 |> captionNowrap [ if dateStr=="" then alignLeft else centerX ]

            duration =
              if oer.mediatype=="video" && oer.duration=="" && oer.durationInSeconds>1 then
                -- hack to fix videolectures.net
                -- https://github.com/sahanbull/x5learn/issues/255
                let
                    minutes =
                      oer.durationInSeconds / 60
                      |> floor
                      |> max 1
                      |> String.fromInt
                in
                    (minutes ++ " min") |> captionNowrap [ alignRight, paddingRight 8 ]
              else
                oer.duration |> captionNowrap [ alignRight, paddingRight 8 ]

            content =
              [ date, provider, duration ]
        in
            content
            |> row [ width fill, paddingXY 16 0, moveDown 255 ]
            |> inFront

      widthOfCard =
        width (px cardWidth)

      heightOfCard =
        height (px cardHeight)

      clickHandler =
        if isInspecting model oer then
          []
        else
          [ onClick <| InspectOer oer 0 False "Click on card" ]

      shadow =
        if enableShadow then [ htmlClass "MaterialCard" ] else [ Border.width 1, borderColorDivider ]

      card =
        [ graphic ]
        |> column ([ widthOfCard, heightOfCard, onMouseEnter (SetHover (Just oer.id)), onMouseLeave (SetHover Nothing), title, bottomInfo ] ++ availableTranslations ++ contentFlowBar ++ shadow ++ clickHandler ++ popup)
        |> explanationWrapper

      explanationWrapper =
        explainify model explanationForOerCard

      wrapperAttrs =
        [ htmlClass "PreventClosingInspectorOnClick OerCard", widthOfCard, heightOfCard, inFront <| card, moveRight position.x, moveDown position.y, htmlDataAttribute <| String.fromInt oer.id, htmlClass "CursorPointer" ]
  in
      none
      |> el wrapperAttrs

{-| If the Oer has several images, show them as a slideshow
-}
viewCarousel : Model -> Oer -> Element Msg
viewCarousel model oer =
  let
      thumbFromSpritesheet =
        if oer.mediatype/="video" then
          []
        else
          let
              defaultThumb =
                none
                |> el [ width <| px cardWidth, height <| px imageHeight, htmlStyle "background" ("url('"++ (thumbUrl oer) ++"')") ]
                |> inFront
                |> List.singleton
          in
              if isHovering model oer then
                case model.timelineHoverState of
                  Nothing ->
                    defaultThumb

                  Just {position} ->
                    [ viewScrubImage model oer position |> inFront ]
              else
                defaultThumb
  in
      viewCoverImage model oer thumbFromSpritesheet


{-| When the user hovers over the timeline, show the appropriate tumbnail at that point
-}
viewScrubImage : Model -> Oer -> Float -> Element Msg
viewScrubImage model oer position =
  let
      spriteImageIndex =
        (min 0.999 position) * spriteSheetNumberOfColumns * spriteSheetNumberOfRows
        |> floor

      offsetX =
        (modBy spriteSheetNumberOfColumns spriteImageIndex) * cardWidth
        |> String.fromInt

      offsetY =
        (spriteImageIndex // spriteSheetNumberOfColumns) * imageHeight
        |> String.fromInt

      backgroundValue =
        "url('"++ (spritesheetUrl oer) ++"') -"++offsetX++"px -"++offsetY++"px"
  in
      none
      |> el [ width <| px cardWidth, height <| px imageHeight, htmlStyle "background" backgroundValue ]


{-| Render the default cover image
-}
viewCoverImage : Model -> Oer -> List (Attribute Msg) -> Element Msg
viewCoverImage model oer thumbFromSpritesheet =
  let
      upperImage attrs url =
        none
        |> el ([ width fill, height <| px <| imageHeight, Background.image <| url, htmlClass (if isFromVideoLecturesNet oer then "MaterialHoverZoomThumb__Videolectures" else "MaterialHoverZoomThumb") ] ++ thumbFromSpritesheet ++ attrs)
  in
      case oer.images of
        [] ->
          imgPath "thumbnail_unavailable.jpg"
          |> upperImage []

        [ singleImage ] ->
          thumbUrlAlt singleImage
          |> upperImage []

        firstImage :: otherImages ->
          let
              imageIndex =
                (millisSince model model.timeOfLastMouseEnterOnCard) // 1500 + 1
                |> modBy (List.length oer.images)

              currentImageUrl =
                oer.images
                |> selectByIndex imageIndex (thumbUrlAlt firstImage)

              nextImageUrl =
                oer.images
                |> selectByIndex (imageIndex+1) (thumbUrlAlt firstImage)

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
--       |> el [ width fill, height (px imageHeight), Background.color primaryGreen ]


spriteSheetNumberOfRows =
  10


spriteSheetNumberOfColumns =
  10


spritesheetUrl : Oer -> String
spritesheetUrl oer =
  "http://145.14.12.115/files/sprite_sheets/sprite_"++(String.fromInt oer.id)++"_10x10_332x175.jpg"


thumbUrl : Oer -> String
thumbUrl oer =
  "http://145.14.12.115/files/thumbs/tn_"++(String.fromInt oer.id)++"_332x175.jpg"


thumbUrlAlt : String -> String
thumbUrlAlt filename = 
  Url.Builder.relative [ "files/thumbs", filename ] []


viewOverviewTypeMenu : Model -> Element Msg
viewOverviewTypeMenu model =
  let
      option overviewType =
        actionButtonWithoutIcon [] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] (overviewTypeDisplayName overviewType) (Just <| SelectedOverviewType overviewType)

      options : List (Attribute Msg)
      options =
        let
          menuDraw = if model.searchIsPlaylist then below else onLeft
        in
        case model.popup of
          Just OverviewTypePopup ->
            [ option ThumbnailOverview
            , option <| BubblogramOverview TopicNames
            , option <| BubblogramOverview TopicBubbles
            , option <| BubblogramOverview TopicSwimlanes
            ]
            |> menuColumn []
            |> menuDraw
            |> List.singleton

          _ ->
            []

      attrs =
        [ alignRight, moveLeft 130, moveDown 30, Border.width 2, Border.color white, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
  in
      -- actionButtonWithIcon [ whiteText, paddingXY 12 10 ] [] IconLeft 0.9 "format_list_white" "View ▾" (Just OpenedOverviewTypeMenu)
      actionButtonWithoutIcon [ whiteText, paddingXY 12 10 ] [] "View ▾" (Just OpenedOverviewTypeMenu)
      |> el attrs


viewPlaylistButtons : Model -> Element Msg
viewPlaylistButtons model =
  let
    downloadButton =
      if isLoggedIn model then
        newTabLink [ bigButtonPadding, whiteText, Font.center, width fill, Font.size 14 ] { url = "/playlist/download/" ++ Maybe.withDefault "" model.publishedPlaylistId, label = Element.text "Download" }
      else
        actionButtonWithoutIcon [whiteText] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] "Download" (Just <| SetPlaylistState (Just PlaylistClone))

    cloneButton =
      actionButtonWithoutIcon [whiteText] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] "Clone" (Just <| SetPlaylistState (Just PlaylistClone))

    shareButton =
      actionButtonWithoutIcon [whiteText] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] "Share" (Just <| SetPlaylistState (Just PlaylistShare))

    infoButton =
      actionButtonWithoutIcon [whiteText] [ bigButtonPadding, width fill, htmlClass "HoverGreyBackground" ] "Info" (Just <| SetPlaylistState (Just PlaylistInfo))

    attrs =
        [ alignRight, moveLeft 210, moveDown 30, spacing 6 ]
  in
    [ infoButton |> el [ Border.width 2, Border.color white, buttonRounding]
    , shareButton |> el [ Border.width 2, Border.color white, buttonRounding]
    , cloneButton |> el [ Border.width 2, Border.color white, buttonRounding]
    , downloadButton |> el [ Border.width 2, Border.color white, buttonRounding]
    ]
    |> row attrs


explanationForOerCard : Explanation
explanationForOerCard =
  { componentId = "oerCard"
  , flyoutDirection = Left
  , links = [ explanationLinkForWikification, explanationLinkForTranslation ]
  }
