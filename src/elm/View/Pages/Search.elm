module View.Pages.Search exposing (viewSearchPage)

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


viewSearchPage : Model -> SearchState -> PageWithModal
viewSearchPage model searchState =
  let
      modal =
        case model.inspectorState of
          Nothing ->
            []

          Just inspectorState ->
            [ inFront <| viewModal model inspectorState ]
  in
      (viewSearchResults model searchState (List.isEmpty modal), modal)


viewModal : Model -> InspectorState -> Element Msg
viewModal model ({oer} as inspectorState) =
  let
      closeIcon =
        image [  materialDarkAlpha, hoverCircleBackground] { src = svgPath "close", description = "close" }

      (headerContent, bodyContent, footerContent) =
        case inspectorState.activeMenu of
          Nothing ->
            inspectorContentDefault model inspectorState oer

          Just SaveToPlaylistMenu ->
            inspectorContentSaveToPlaylist model inspectorState oer

      header =
        [ headerContent
        , button [] { onPress = Just UninspectSearchResult, label = closeIcon }
        ]
        |> row [ width fill, spacing 16 ]

      footer =
        footerContent
        |> row [ spacing 20, width fill ]

      hideWhileOpening =
        alpha <| if model.animationsPending |> Set.member modalId then 0.01 else 1

      body =
        bodyContent

      sheet =
        [ header
        , body
        , footer
        ]
        |> column [ width (fill |> maximum 752), Background.color white, centerX, moveRight (navigationDrawerWidth/2),  centerY, padding 16, spacing 16, htmlId modalId, hideWhileOpening, dialogShadow ]

      animatingBox =
        case model.modalAnimation of
          Nothing ->
            none

          Just animation ->
            let
                (box, opacity) =
                  if animation.frameCount > 1 then
                    (animation.end, 5/((toFloat animation.frameCount)+5))
                  else
                    (interpolateBoxes animation.start animation.end, 0)
            in
                none
                |> el [ whiteBackground, width (box.sx |> round |> px), height (box.sy |> round |> px), moveRight box.x, moveDown box.y, htmlClass "modalAnimation", alpha opacity, Border.rounded 5 ]

      scrim =
        let
            opacity =
              case modalAnimationStatus model of
                Inactive ->
                  0.32

                Prestart ->
                  0

                Started ->
                  0.32
        in
            none
            |> el [ Background.color <| rgba 0 0 0 opacity, width (model.windowWidth - navigationDrawerWidth |> px), height (fill |> maximum (model.windowHeight - pageHeaderHeight)), moveDown pageHeaderHeight, moveRight navigationDrawerWidth, onClickNoBubble UninspectSearchResult, htmlClass "modalScrim" ]
  in
      sheet
      |> el [ width fill, height fill, behindContent scrim, inFront animatingBox ]


viewSearchResults model searchState clickEnabled =
  case searchState.searchResults of
    Nothing ->
      "loading..." |> wrapText [ primaryWhite, centerX, centerY ]
      |> el [ centerX, height fill ]
      |> el [ width fill, height fill ]

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
      if clickEnabled then
        button [] { onPress = Just (InspectSearchResult oer), label = card }
      else
        button [] { onPress = Nothing, label = card }


inspectorContentDefault model inspectorState oer =
  let
      header =
        oer.title |> headlineWrap []

      player =
        case getYoutubeId oer of
          Nothing ->
            none

          Just youtubeId ->
            embedYoutubePlayer youtubeId

      description =
        oer.description
        |> bodyWrap []

      body =
        [ player
        , description
        ]
        |> column [ spacing 16 ]

      footer =
        [ newTabLink [] { url = oer.url, label = providerLink }
        , none |> el [ width fill ]
        , actionButtons
        ]

      footerButton label =
        button [ hoverCircleBackground ] { onPress = Nothing, label = label }

      providerLink =
        [  oer.provider |> bodyNoWrap [ alignLeft]
        , image [ alignLeft, materialDarkAlpha, width (px 20) ] { src = svgPath "navigate_next", description = "external link" }
        ]
        |> row [ alignLeft, width fill ]

      actionButtons =
        [ actionButton "share" "SHARE" Nothing
        , actionButton "playlist_add" "SAVE" <| Just <| OpenSaveToPlaylistMenu inspectorState
        , footerButton <| svgIcon "more_vert"
        ]
        |> row [ spacing 20, alignRight ]
  in
      (header, body, footer)


inspectorContentSaveToPlaylist model inspectorState oer =
  let
      header =
        "Save to..." |> headlineWrap [ paddingXY 14 0 ]

      footer =
        [ actionButton "add" "Create new playlist" <| Nothing ]

      playlistButton : Playlist -> Element Msg
      playlistButton playlist =
        let
            (icon, action) =
              if isInPlaylist oer playlist then
                ("checkbox_ticked", RemoveFromPlaylist)
              else
                ("checkbox_unticked", AddToPlaylist)
        in
            actionButton icon playlist.title <| Just <| action playlist oer

      body =
        model.playlists
        |> List.map playlistButton
        |> column [ spacing 10 ]
  in
      (header, body, footer)
