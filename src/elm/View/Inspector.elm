module View.Inspector exposing (viewInspectorModalOrEmpty)

import Set

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Json.Decode

import Model exposing (..)
import Msg exposing (..)

import View.Shared exposing (..)
import View.Noteboard exposing (..)
import View.Html5VideoPlayer exposing (..)

import Animation exposing (..)


viewInspectorModalOrEmpty : Model -> UserState -> List (Attribute Msg)
viewInspectorModalOrEmpty model userState =
  case model.inspectorState of
    Nothing ->
      []

    Just inspectorState ->
      [ inFront <| viewModal model userState inspectorState ]


viewModal : Model -> UserState -> InspectorState -> Element Msg
viewModal model userState inspectorState =
  let
      content =
        case inspectorState.activeMenu of
          Nothing ->
            inspectorContentDefault model userState inspectorState

          Just QualitySurvey ->
            inspectorContentDefault model userState inspectorState -- TODO

      header =
        [ content.header
        , button [] { onPress = Just UninspectSearchResult, label = closeIcon }
        ]
        |> row [ width fill, spacing 16 ]

      footer =
        content.footer
        |> row [ spacing 20, width fill ]

      hideWhileOpening =
        alpha <| if model.animationsPending |> Set.member modalId then 0.01 else 1

      body =
        content.body

      sheet =
        [ header
        , body
        , footer
        ]
        |> column [ htmlClass "CloseInspectorOnClickOutside", width (px sheetWidth), Background.color white, centerX, moveRight (navigationDrawerWidth/2),  centerY, padding 16, spacing 16, htmlId modalId, hideWhileOpening, dialogShadow, inFront content.fixed ]

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
                  materialScrimAlpha

                Prestart ->
                  0

                Started ->
                  materialScrimAlpha
        in
            none
            |> el [ Background.color <| rgba 0 0 0 opacity, width (model.windowWidth - navigationDrawerWidth |> px), height (fill |> maximum (model.windowHeight - pageHeaderHeight)), moveDown pageHeaderHeight, moveRight navigationDrawerWidth,  htmlClass "modalScrim" ]
  in
      sheet
      |> el [ width fill, height fill, behindContent scrim, inFront animatingBox ]


inspectorContentDefault model userState {oer, fragmentStart} =
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
                  fragmentStart * (durationInSecondsFromOer oer |> toFloat) |> floor
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
        [ player
        , fragmentsBarWrapper
        ]
        |> column [ width (px playerWidth), moveLeft notesWidth ]

      body =
        [ viewNoteboard model userState oer.url |> el [ width <| px notesWidth, height fill, alignTop, borderLeft 1, paddingTRBL 0 0 0 15, moveRight (sheetWidth - notesWidth - 30 ) ]
        , mainSection
        ]
        |> row []

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
        -- else
        --   actionButtonWithIcon IconRight "navigate_next" oer.provider (Just <| ShowProviderLinkInInspector)
        -- [ oer.provider |> bodyNoWrap [ alignLeft]
        -- , image [ alignLeft, materialDarkAlpha, width (px 20) ] { src = svgPath "navigate_next", description = "external link" }
        -- ]
        -- |> row [ alignLeft, width fill, onClick UninspectSearchResult ]

      -- actionButtons =
      --   [ actionButtonWithIcon IconLeft "share" "SHARE" Nothing
      --   , actionButtonWithIcon IconLeft "bookmarklist_add" "SAVE" <| Just <| OpenSaveToBookmarklistMenu inspectorState
      --   , footerButton <| svgIcon "more_vert"
      --   ]
      --   |> row [ spacing 20, alignRight ]
  in
      { header = header, body = body, footer = footer, fixed = none }


notesWidth =
  248


fragmentsBarWrapperHeight =
  200


sheetWidth =
  752+notesWidth+15
