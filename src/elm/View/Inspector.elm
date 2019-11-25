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
import View.FragmentsBar exposing (..)
import View.Html5VideoPlayer exposing (..)
import View.HtmlPdfViewer exposing (..)

import Animation exposing (..)


viewInspectorModalOrEmpty : Model -> List (Attribute Msg)
viewInspectorModalOrEmpty model =
  case model.inspectorState of
    Nothing ->
      []

    Just inspectorState ->
      [ inFront <| viewModal model inspectorState ]


viewModal : Model -> InspectorState -> Element Msg
viewModal model inspectorState =
  let
      content =
        case inspectorState.activeMenu of
          Nothing ->
            inspectorContentDefault model inspectorState

          Just QualitySurvey ->
            inspectorContentDefault model inspectorState -- TODO

      header =
        [ content.header
        , fullPageButton
        , button [] { onPress = Just UninspectSearchResult, label = closeIcon }
        ]
        |> row [ width fill, spacing 4 ]

      fullPageButton =
        image [ alpha 0.8, hoverCircleBackground ] { src = svgPath "fullscreen", description = "View this resource in full-page mode" }
        |> linkTo [ alignRight ] (resourceUrlPath inspectorState.oer.id)

      -- footer =
      --   content.footer
      --   |> row [ spacing 20, width fill ]

      hideWhileOpening =
        alpha <| if model.animationsPending |> Set.member modalId then 0.01 else 1

      body =
        content.body

      sheet =
        [ header
        , body
        -- , footer
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


inspectorContentDefault model {oer, fragmentStart} =
  let
      header =
        case oer.title of
          "" ->
            "Title unavailable" |> headlineWrap [ Font.italic ]

          title ->
            title |> headlineWrap []

      player =
        case getYoutubeVideoId oer.url of
          Nothing ->
            if isVideoFile oer.url then
              viewHtml5VideoPlayer model oer.url
            else if isPdfFile oer.url then
              viewHtmlPdfPlayer oer.url "45vh"
            else
              none

          Just youtubeId ->
            let
                startTime =
                  fragmentStart * oer.durationInSeconds |> floor
            in
                embedYoutubePlayer youtubeId startTime

      body =
        [ player
        , viewFragmentsBarWrapper model oer
        ]
        |> column [ width (px playerWidth) ]

      footer =
        []
  in
      { header = header, body = body, footer = footer, fixed = none }



viewDescription oer =
  case oer.description of
    "" ->
      "No description available" |> italicText |> el [ paddingTop 30 ]

    desc ->
      desc
      |> String.split("\n")
      |> List.filter (\line -> String.length line > 2)
      |> List.map (bodyWrap [])
      |> column [ spacing 7, height fill, scrollbarY, paddingTop 30 ]


viewLinkToFile oer =
  newTabLink [] { url = oer.url, label = oer.url |> bodyWrap [] }


sheetWidth =
  752


viewProviderLinkAndFavoriteButton model oer =
  let
      favoriteButton =
        let
            heart =
              viewHeartButton model oer.id
              |> el [ moveRight 12, moveUp 14 ]
        in
            none
            |> el [ alignRight, width <| px 34, inFront heart ]

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
      [ providerLink
      , favoriteButton
      ]
      |> row [ width fill ]


viewCourseButton model oer =
  [ none |> el [ width fill ]
  , actionButtonWithIcon [] IconLeft "bookmarklist_add" "Add to workspace" <| Just <| AddedOerToCourse oer.id (Range 0 oer.durationInSeconds)
  ]


viewCourseSettings model oer {range, comment} =
  let
      topRow =
        [ "This video has been added to your workspace." |> bodyWrap [ width fill ]
        , actionButtonWithIcon [] IconLeft "delete" "Remove" <| Just <| RemovedOerFromCourse oer.id
        ]
        |> row [ width fill ]

      fields =
        [ "Selected Range:" |> bodyNoWrap [ width fill ]
        , range.start |> floor |> secondsToString |> bodyNoWrap [ width fill ]
        , "-" |> bodyNoWrap [ width fill ]
        , range.start + range.length |> floor |> secondsToString |> bodyNoWrap [ width fill ]
        ]
        |> row [ spacing 10 ]

      commentField =
        Input.text [ width fill, htmlId "textInputFieldForCommentOnCourseItem", onEnter <| SubmittedCourseItemComment, Border.color x5color, Font.size 14, padding 3, moveDown 5 ] { onChange = ChangedCommentTextInCourseItem oer.id, text = comment, placeholder = Just ("Enter any notes or comments about this item" |> text |> Input.placeholder [ Font.size 14, moveDown 6 ]), label = Input.labelHidden "Comment on course item" }
  in
      [ topRow
      , fields
      , commentField
      ]


viewFragmentsBarWrapper model oer =
  let
      components =
        if isLabStudy1 model then
          case getCourseItem model oer of
            Nothing ->
              viewCourseButton model oer

            Just item ->
              viewCourseSettings model oer item
        else
          [ viewDescription oer
          , [ viewLinkToFile oer, viewProviderLinkAndFavoriteButton model oer ] |> column [ width fill, spacing 15, paddingTop 30 ]
          ]

      containerHeight =
        if isLabStudy1 model then
          100
        else
          200

      fragmentsBar =
        if oer.mediatype == "video" then
          case chunksFromOerId model oer.id of
            [] ->
              []

            wikichunks ->
              let
                  barWrapper =
                    viewFragmentsBar model oer wikichunks playerWidth "inspector"
                    |> el [ width (px playerWidth), height (px 16) ]
              in
                  none
                  |> el [ inFront barWrapper, moveUp (0 - fragmentsBarHeight), height <| px containerHeight ]
                  |> inFront
                  |> List.singleton
        else
          []
  in
      components
      |> column ([ width (px playerWidth), height <| px <| containerHeight, moveDown 1, paddingTop 25, spacing 4 ] ++ fragmentsBar)
