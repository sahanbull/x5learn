module View.Bubblogram exposing (viewBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseOver, onMouseOut, custom)

import Element exposing (Element, el, html, inFront, row, padding, spacing, px, moveDown, moveRight, above, below, none)
import Element.Font as Font
import Element.Background as Background

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

      widthString =
        containerWidth |> String.fromInt

      heightString =
        containerHeight |> String.fromInt

      -- mergedBubbles =
      --   rawBubbles
      --   |> List.Extra.uniqueBy (\{entity} -> entity.title)
      --   |> List.map (\bubble -> { bubble | alpha = Basics.min 0.8 <| rawBubbleAlpha * (rawBubbles |> List.filter (\b -> b.entity == bubble.entity)  |> List.length |> toFloat) })
      --   |> List.sortBy .size
      --   |> List.reverse

      svgBubbles =
        bubbles
        |> List.map (viewBubble model oerUrl animationPhase)

      background =
        rect [ width widthString, height heightString, fill "#191919" ] []

      findBubbleByEntityId : String -> Maybe Bubble
      findBubbleByEntityId entityId =
        bubbles |> List.filter (\bubble -> bubble.entity.id == entityId) |> List.reverse |> List.head

      entityLabels =
        if animationPhase < 0.1 then
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
                [ Element.alpha (interp (size/3) (1.6*labelPhase-1) 0.6) ]
        in
            entity.title
            |> captionNowrap ([ whiteText, moveRight <| (posX + size*1.1*bubbleZoom) * contentWidth + marginX, moveDown <| (posY - size*1.1*bubbleZoom) * contentHeight + marginTop - 15 ] ++ highlight)
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



viewBubble : Model -> OerUrl -> Float -> Bubble -> Svg.Svg Msg
viewBubble model oerUrl animationPhase ({entity} as bubble) =
  let
      {posX, posY, size} =
        animatedBubbleCurrentCoordinates animationPhase bubble

      isHovering =
        hoveringBubbleOrFragmentsBarEntityId model == Just entity.id

      outline =
        if isHovering then
          [ stroke "white", strokeWidth "2" ]
        else
          []
  in
      circle
        ([ cx (posX * (toFloat contentWidth) + marginX |> String.fromFloat)
        , cy (posY * (toFloat contentHeight) + marginTop |> String.fromFloat)
        , r (size * (toFloat contentWidth) * bubbleZoom|> String.fromFloat)
        , fill <| Color.toCssString <| colorFromBubble bubble
        , onMouseOver <| BubbleMouseOver entity.id
        , onMouseOut <| BubbleMouseOut
        , custom "click" (Json.Decode.succeed { message = BubbleClicked oerUrl, stopPropagation = True, preventDefault = True })
        , class "UserSelectNone"
        ] ++ outline)
        []


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
      enlargementPhaseFromText text =
        (String.length text |> toFloat) / 200 - posY*0.5 |> Basics.min 1

      -- heightLimit =
      --   Element.height (Element.fill |> Element.maximum 110)

      (contentElement, enlargementPhase) =
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
                            ("“" ++ text ++ "” (Wikipedia)" |> bodyWrap [ Font.italic ], enlargementPhaseFromText text)

                        -- DefinitionUnavailable ->
                        -- unavailable
            in
                element

          MentionInBubblePopup {sentence} ->
            (sentence |> bodyWrap [], enlargementPhaseFromText sentence)

      box =
        contentElement
        |> List.singleton
        -- |> menuColumn [ Element.width <| px <| round popupWidth, padding 10, pointerEventsNone, heightLimit, Element.clipY ]
        |> menuColumn [ Element.width <| px <| round popupWidth, padding 10, pointerEventsNone, Element.clipY ]

      (horizontalOffset, popupWidth) =
        let
            allowedMargin =
              horizontalSpacingBetweenCards - 5

            smallest =
              { horizontalOffset = (posX/2 + 1/4) * contentWidth + marginX - 220/2, popupWidth = 220 }

            largest =
              { horizontalOffset = -allowedMargin, popupWidth = cardWidth + 2*allowedMargin }
        in
            (interp enlargementPhase smallest.horizontalOffset largest.horizontalOffset
            , interp enlargementPhase smallest.popupWidth largest.popupWidth)

      (verticalDirection, verticalOffset) =
        -- if posY > 0.2 then
        (above, Basics.max 10 <| (posY - size*3.5*bubbleZoom) * contentHeight + marginTop - 5)
        -- else
        --   (below, Basics.max 10 <| (posY + size*3.5*bubbleZoom) * contentHeight + marginTop + 5)
  in
      none
      |> el [ verticalDirection box, moveRight <| horizontalOffset, moveDown <| verticalOffset ]
      |> inFront
      |> List.singleton


containerWidth =
  cardWidth


containerHeight =
  imageHeight


contentWidth =
  cardWidth - 2*marginX


contentHeight =
  imageHeight - 2*marginX - (fragmentsBarHeight + 10)


marginTop =
  marginX + 18


marginX =
  25


animatedBubbleCurrentCoordinates : Float -> Bubble -> BubbleCoordinates
animatedBubbleCurrentCoordinates phase {initialCoordinates, finalCoordinates} =
  { posX = interp phase initialCoordinates.posX finalCoordinates.posX
  , posY = interp phase initialCoordinates.posY finalCoordinates.posY
  , size = interp phase initialCoordinates.size finalCoordinates.size
  }
