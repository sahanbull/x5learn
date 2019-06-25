module View.Bubblogram exposing (viewBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Html.Events

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseOver, custom)

import Element exposing (Element, el, html, inFront, row, padding, spacing, px, moveDown, moveLeft, moveRight, above, below, none)
import Element.Font as Font
import Element.Background as Background
import Element.Events as Events
import Element.Border as Border

import Color -- avh4/elm-color

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


viewBubblogram : Model -> OerUrl -> Bubblogram -> (Element Msg, List (Element.Attribute Msg))
viewBubblogram model oerUrl {createdAt, bubbles} =
  let
      animationPhase =
        bubblogramAnimationPhase model createdAt

      labelPhase =
        animationPhase * 2 - 1 |> Basics.min 1 |> Basics.max 0

      svgBubbles =
        bubbles
        |> List.concatMap (viewBubble model oerUrl animationPhase)

      background =
        rect [ width widthString, height heightString, fill "#191919" ] []

      findBubbleByEntityId : String -> Maybe Bubble
      findBubbleByEntityId entityId =
        bubbles |> List.filter (\bubble -> bubble.entity.id == entityId) |> List.reverse |> List.head

      entityLabels =
        if labelPhase <= 0 then
          []
        else
          bubbles
          |> List.concatMap entityLabel

      entityLabel ({entity} as bubble) =
        let
            {posX, posY, size} =
              animatedBubbleCurrentCoordinates animationPhase bubble

            isHovering =
              hoveringBubbleOrFragmentsBarEntityId model == Just entity.id

            highlight =
              if isHovering then
                [ Font.underline ]
              else
                [ Element.alpha (interp (size/3) (1.8*labelPhase-1) 0.8) ]
        in
            entity.title
            |> captionNowrap ([ whiteText, moveRight <| (posX + 0*size*1.1*bubbleZoom) * contentWidth + marginX, moveDown <| (posY + 0.1 -  0*size*1.1*bubbleZoom) * contentHeight + marginTop - 15, Events.onMouseEnter <| BubbleMouseOver entity.id, Events.onMouseLeave BubbleMouseOut, onClickNoBubble (BubbleClicked oerUrl), htmlClass hoverableClass ] ++ highlight)
            |> inFront
            |> List.singleton

      popup =
        case model.popup of
          Just (BubblePopup state) ->
            if state.oerUrl==oerUrl then
              case findBubbleByEntityId state.entityId of
                Nothing -> -- shouldn't happen
                  []

                Just bubble ->
                  viewPopup model state (animatedBubbleCurrentCoordinates animationPhase bubble)
            else
              []

          _ ->
            []

      graphic =
        [ background ] ++ svgBubbles
        |> svg [ width widthString, height heightString, viewBox <| "0 0 " ++ ([ widthString, heightString ] |> String.join " ") ]
        |> html
        |> el entityLabels
  in
      (graphic, popup)


viewBubble : Model -> OerUrl -> Float -> Bubble -> List (Svg Msg)
viewBubble model oerUrl animationPhase ({entity} as bubble) =
  let
      {posX, posY, size} =
        animatedBubbleCurrentCoordinates animationPhase bubble

      isHovering =
        hoveringBubbleOrFragmentsBarEntityId model == Just entity.id

      outline =
        if isHovering then
          -- [ stroke "#fff", strokeWidth "2", fill "#f93" ]
          [ fill "#f93" ]
        else
          []

      mentionDots =
        if isHovering then
          viewMentionDots model oerUrl bubble
        else
          []

      body =
        circle
          ([ cx (posX * (toFloat contentWidth) + marginX |> String.fromFloat)
          , cy (posY * (toFloat contentHeight) + marginTop |> String.fromFloat)
          , r (size * (toFloat contentWidth) * bubbleZoom|> String.fromFloat)
          , fill <| Color.toCssString <| colorFromBubble bubble
          , onMouseOver <| BubbleMouseOver entity.id
          , onMouseLeave <| BubbleMouseOut
          , custom "click" (Json.Decode.succeed { message = BubbleClicked oerUrl, stopPropagation = True, preventDefault = True })
          , class hoverableClass
          ] ++ outline)
          []
  in
      mentionDots ++ [ body ]


colorFromBubble : Bubble -> Color.Color
colorFromBubble {hue, alpha, saturation} =
  Color.hsla hue saturation 0.5 alpha


bubbleZoom =
  0.042


hoveringBubbleOrFragmentsBarEntityId model =
  case model.hoveringBubbleEntityId of
    Just entityId ->
      Just entityId

    Nothing ->
      case model.popup of
        Just (ChunkOnBar chunkPopup) ->
          case chunkPopup.entityPopup of
            Nothing ->
              Nothing

            Just entityPopup ->
              Just entityPopup.entityId

        _ ->
          Nothing


viewPopup : Model -> BubblePopupState -> BubbleCoordinates -> List (Element.Attribute Msg)
viewPopup model {oerUrl, entityId, content} {posX, posY, size} =
  let
      zoomFromText text =
        (String.length text |> toFloat) / 200 - posY*0.5 |> Basics.min 1

      (contentElement, zoom) =
        case content of
          DefinitionInBubblePopup ->
            let
                unavailable =
                  ("✗ Definition unavailable" |> bodyWrap [], 0)

                element =
                  case model.entityDefinitions |> Dict.get entityId of
                    Nothing -> -- shouldn't happen
                      unavailable

                    Just definition ->
                      case definition of
                        DefinitionScheduledForLoading ->
                          (viewLoadingSpinner, 0)

                        DefinitionLoaded text ->
                          if text=="" then
                            unavailable
                          else
                            ("“" ++ text ++ "” (Wikipedia)" |> bodyWrap [ Font.italic ], zoomFromText text)

                        -- DefinitionUnavailable ->
                        -- unavailable
            in
                element

          MentionInBubblePopup {sentence} ->
            (sentence |> bodyWrap [], zoomFromText sentence)

      box =
        let
            roundedBorder =
              case content of
                MentionInBubblePopup _ ->
                  [ Border.rounded 12 ]

                _ ->
                  []
        in
            contentElement
            |> List.singleton
            |> menuColumn ([ Element.width <| px <| round popupWidth, padding 10, pointerEventsNone, Element.clipY ] ++ roundedBorder)

      tail =
        case content of
          MentionInBubblePopup {positionInResource} ->
            let
                sizeY =
                  containerHeight - verticalOffset

                hs =
                  sizeY
                  |> String.fromFloat

                tipX =
                  positionInResource * containerWidth

                rootX =
                  horizontalOffset + (if positionInResource<0.5 then rootMargin else popupWidth-rootMargin-rootWidth) |> Basics.max 5 |> Basics.min (containerWidth - rootMargin - 15)

                rootWidth =
                  20

                rootMargin =
                  22

                corners =
                  [ (rootX + 0, 0)
                  , (rootX + rootWidth, 0)
                  , (tipX, sizeY-12)
                  ]
                  |> svgPointsFromCorners
            in
                [ polygon [ fill "white", points corners, class "PointerEventsNone" ] [] ]
                |> svg [ width widthString, height hs, viewBox <| "0 0 " ++ ([ widthString, hs ] |> String.join " ") ]
                |> html
                |> el [ moveDown <| sizeY-1, moveLeft horizontalOffset, pointerEventsNone ]
                |> above
                |> List.singleton

          _ ->
            []

      (horizontalOffset, popupWidth) =
        let
            allowedMargin =
              horizontalSpacingBetweenCards - 5

            smallest =
              { horizontalOffset = (posX/2 + 1/4) * contentWidth + marginX - 220/2, popupWidth = 220 }

            largest =
              { horizontalOffset = -allowedMargin, popupWidth = cardWidth + 2*allowedMargin }
        in
            (interp zoom smallest.horizontalOffset largest.horizontalOffset
            , interp zoom smallest.popupWidth largest.popupWidth)

      verticalOffset =
        popupVerticalPositionFromBubble posY size
  in
      none
      |> el ([ above box, moveRight <| horizontalOffset, moveDown <| verticalOffset ]++tail)
      |> inFront
      |> List.singleton


containerWidth =
  cardWidth


containerHeight =
  imageHeight


contentWidth =
  cardWidth - 2*marginX


contentHeight =
  imageHeight - 2*marginX - fragmentsBarHeight - 10


marginTop =
  marginX + 18


marginX =
  25


widthString =
  containerWidth |> String.fromInt

heightString =
  containerHeight |> String.fromInt


animatedBubbleCurrentCoordinates : Float -> Bubble -> BubbleCoordinates
animatedBubbleCurrentCoordinates phase {initialCoordinates, finalCoordinates} =
  { posX = interp phase initialCoordinates.posX finalCoordinates.posX
  , posY = interp phase initialCoordinates.posY finalCoordinates.posY
  , size = interp phase initialCoordinates.size finalCoordinates.size
  }


hoverableClass =
  "UserSelectNone CursorPointer"


viewMentionDots : Model -> OerUrl -> Bubble -> List (Svg Msg)
viewMentionDots model oerUrl bubble =
  if isAnyChunkPopupOpen model then
    []
  else
    let
        circlePosY =
          containerHeight - 8
          |> String.fromFloat

        dot : MentionInOer -> Svg Msg
        dot {positionInResource, sentence} =
          let
              isInPopup =
                case model.popup of
                  Just (BubblePopup state) ->
                    if state.oerUrl==oerUrl && state.entityId==bubble.entity.id then
                      case state.content of
                        MentionInBubblePopup mention ->
                          mention.sentence==sentence

                        _ ->
                          False

                    else
                      False

                  _ ->
                    False

              circlePosX =
                positionInResource * containerWidth
                |> String.fromFloat

              circleRadius =
                "5"
          in
              circle [ cx circlePosX, cy circlePosY, r circleRadius, fill "orange" ] []

        mentions =
          getMentions model oerUrl bubble.entity.id
    in
        mentions
        |> List.map dot


svgPointsFromCorners : List (Float, Float) -> String
svgPointsFromCorners corners =
  corners
  |> List.map (\(x,y) -> (x |> String.fromFloat)++","++(y |> String.fromFloat))
  |> String.join " "


onMouseLeave : msg -> Attribute msg
onMouseLeave msg =
  Html.Events.on "mouseleave" (Json.Decode.succeed msg)


popupVerticalPositionFromBubble posY size =
  Basics.max 10 <| (posY - size*3.5*bubbleZoom) * contentHeight + marginTop - 5
