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

import Animation exposing (..)


viewInspectorModalOrEmpty : Model -> List (Attribute Msg)
viewInspectorModalOrEmpty model =
  case model.inspectorState of
    Nothing ->
      []

    Just inspectorState ->
      [ inFront <| viewModal model inspectorState ]


viewModal : Model -> InspectorState -> Element Msg
viewModal model ({oer} as inspectorState) =
  let
      content =
        case inspectorState.activeMenu of
          Nothing ->
            inspectorContentDefault model inspectorState oer

          Just SaveToBookmarklistMenu ->
            inspectorContentSaveToBookmarklist model inspectorState oer

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
        |> column [ htmlClass "InspectorAutoclose", width (fill |> maximum 752), Background.color white, centerX, moveRight (navigationDrawerWidth/2),  centerY, padding 16, spacing 16, htmlId modalId, hideWhileOpening, dialogShadow, inFront content.fixed ]

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
        |> column [ spacing 30 ]

      footer =
        [ providerLink
        , none |> el [ width fill ]
        , actionButtons
        ]

      fragmentsBar =
        let
            content =
              viewFragmentsBar model oer (model.nextSteps |> Maybe.withDefault [] |> List.concatMap .fragments) playerWidth "inspector"
              |> el [ width (px playerWidth), height (px 16) ]
        in
            none |> el [ inFront content, moveDown 487, moveRight 16 ]

      footerButton label =
        button [ hoverCircleBackground ] { onPress = Nothing, label = label }

      providerLink =
        -- if inspectorState.providerLinkShown then
          newTabLink [] { url = oer.url, label = oer.provider |> bodyNoWrap [] }
        -- else
        --   actionButtonWithIcon IconRight "navigate_next" oer.provider (Just <| ShowProviderLinkInInspector)
        -- [ oer.provider |> bodyNoWrap [ alignLeft]
        -- , image [ alignLeft, materialDarkAlpha, width (px 20) ] { src = svgPath "navigate_next", description = "external link" }
        -- ]
        -- |> row [ alignLeft, width fill, onClick UninspectSearchResult ]

      actionButtons =
        [ actionButtonWithIcon IconLeft "share" "SHARE" Nothing
        , actionButtonWithIcon IconLeft "bookmarklist_add" "SAVE" <| Just <| OpenSaveToBookmarklistMenu inspectorState
        , footerButton <| svgIcon "more_vert"
        ]
        |> row [ spacing 20, alignRight ]
  in
      { header = header, body = body, footer = footer, fixed = fragmentsBar }


inspectorContentSaveToBookmarklist model inspectorState oer =
  let
      header =
        "Save to..." |> headlineWrap [ paddingXY 14 0 ]

      footer =
        [ actionButtonWithIcon IconLeft "add" "Create new list" <| Nothing ]

      bookmarklistButton : Playlist -> Element Msg
      bookmarklistButton playlist =
        let
            (icon, action) =
              if isInPlaylist oer playlist then
                ("checkbox_ticked", RemoveFromBookmarklist)
              else
                ("checkbox_unticked", AddToBookmarklist)
        in
            actionButtonWithIcon IconLeft icon playlist.title <| Just <| action playlist oer

      body =
        model.bookmarklists
        |> List.map bookmarklistButton
        |> column [ spacing 10 ]
  in
      { header = header, body = body, footer = footer, fixed = none }
