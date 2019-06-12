module View.Bubblogram exposing (viewBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseOver, onMouseOut, custom)

import Element exposing (el, html, inFront, row, padding, spacing, px, moveDown, moveRight, above, none)
import Element.Font as Font
import Element.Background as Background

import Color -- avh4/elm-color

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


type alias Occurrence =
  { entity : Entity
  , posX : Float
  , posY : Float
  }


type alias Bubble =
  { entity : Entity
  , posX : Float
  , posY : Float
  , size : Float
  , hue : Float
  , alpha : Float
  , saturation : Float
  }


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


viewBubblogram model oerUrl chunks =
  let
      mergePhase =
        (millisSinceEnrichmentLoaded model oerUrl |> toFloat) / (toFloat enrichmentAnimationDuration) |> Basics.min 1

      widthString =
        containerWidth |> String.fromInt

      heightString =
        containerHeight |> String.fromInt

      rawBubbles =
        let
            occurrences =
              chunks
              |> occurrencesFromChunks
        in
            occurrences
            |> List.map (bubbleFromOccurrence model mergePhase occurrences)

      -- mergedBubbles =
      --   rawBubbles
      --   |> List.Extra.uniqueBy (\{entity} -> entity.title)
      --   |> List.map (\bubble -> { bubble | alpha = Basics.min 0.8 <| rawBubbleAlpha * (rawBubbles |> List.filter (\b -> b.entity == bubble.entity)  |> List.length |> toFloat) })
      --   |> List.sortBy .size
      --   |> List.reverse

      svgBubbles =
        rawBubbles
        |> List.sortBy frequency
        |> List.reverse
        |> List.map (viewBubble model oerUrl chunks)

      background =
        rect [ width widthString, height heightString, fill "#191919" ] []

      frequency bubble =
        rawBubbles
        |> List.filter (\b -> b.entity == bubble.entity)
        |> List.length

      findBubbleByEntityId : String -> Maybe Bubble
      findBubbleByEntityId entityId =
        rawBubbles |> List.filter (\bubble -> bubble.entity.id == entityId) |> List.reverse |> List.head

      entityLabel =
        case hoveringBubbleOrFragmentsBarEntityId model of
          Nothing ->
            []

          Just entityId ->
            case findBubbleByEntityId entityId of
              Nothing -> -- shouldn't happen
                []

              Just {entity, posX, posY, size} ->
                entity.title
                |> captionNowrap [ whiteText, moveRight <| (posX + size*1.1*bubbleZoom) * contentWidth + marginX, moveDown <| (posY - size*1.1*bubbleZoom) * contentHeight + marginTop - 15 ]
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
                  viewPopup model state bubble
            else
              []

          _ ->
            []
  in
      [ background ] ++ svgBubbles
      |> svg [ width widthString, height heightString, viewBox <| "0 0 " ++ ([ widthString, heightString ] |> String.join " ") ]
      |> html
      |> el (entityLabel ++ popup)


occurrencesFromChunks : List Chunk -> List Occurrence
occurrencesFromChunks chunks =
  let
      nChunksMinus1 = (List.length chunks) - 1
  in
      chunks
      |> List.indexedMap (occurrencesFromChunk nChunksMinus1)
      |> List.concat


occurrencesFromChunk : Int -> Int -> Chunk -> List Occurrence
occurrencesFromChunk nChunksMinus1 chunkIndex {entities, length} =
  let
      posX =
        (toFloat chunkIndex) / (toFloat nChunksMinus1)

      nEntitiesMinus1 =
        (List.length entities) - 1
  in
      entities
      |> List.indexedMap (occurrenceFromEntity posX nEntitiesMinus1)


occurrenceFromEntity : Float -> Int -> Int -> Entity -> Occurrence
occurrenceFromEntity posX nEntitiesMinus1 entityIndex entity =
  let
      posY =
        (toFloat entityIndex) / (toFloat nEntitiesMinus1)
  in
      Occurrence entity posX posY


bubbleFromOccurrence : Model -> Float -> List Occurrence -> Occurrence -> Bubble
bubbleFromOccurrence model mergePhase occurrences {entity, posX, posY} =
  let
      occurrencesWithSameEntityId =
        occurrences
        |> List.filter (\o -> o.entity.id == entity.id)

      mergedPosX =
        occurrencesWithSameEntityId
        |> averageOf .posX

      mergedPosY =
        occurrencesWithSameEntityId
        |> averageOf .posY

      mergedSize =
        occurrencesWithSameEntityId |> List.length |> toFloat |> sqrt

      isSearchTerm =
        isEqualToSearchString model entity.title

      (hue, saturation, alpha) =
        if isSearchTerm then
          (0.145, 0.9, 0.15 + 0.55 * (1.0 / (occurrencesWithSameEntityId |> List.length |> toFloat)))
        else
          (0.536, fakeLexicalSimilarityToSearchTerm entity.id, rawBubbleAlpha)
  in
      { entity = entity
      , posX = interp mergePhase posX mergedPosX
      , posY = interp mergePhase posY mergedPosY
      , size = interp mergePhase 1 mergedSize
      , hue = hue
      , saturation = saturation
      , alpha = alpha
      }


fakeLexicalSimilarityToSearchTerm : String -> Float
fakeLexicalSimilarityToSearchTerm id =
  if (String.length id) == 7 then 0.5 else 0


-- fakePredictedLevelOfKnowledgeFromEntity : String -> Float
-- fakePredictedLevelOfKnowledgeFromEntity id =
--   ((String.length id |> modBy 3) + 1 |> toFloat) / 3


-- fakePredictedLevelOfInterestFromEntity : String -> Float
-- fakePredictedLevelOfInterestFromEntity id =
--   (String.length id |> modBy 4 |> toFloat) / 3


-- fakedLevelOfTheSystemsConfidenceInHue : String -> Float
-- fakedLevelOfTheSystemsConfidenceInHue id =
--   (String.length id |> modBy 5 |> toFloat) / 5 * 100


viewBubble : Model -> OerUrl -> List Chunk -> Bubble -> Svg.Svg Msg
viewBubble model oerUrl chunks ({entity, posX, posY, size} as bubble) =
  let
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
        , onMouseOver <| BubbleMouseOver oerUrl chunks entity
        , onMouseOut <| BubbleMouseOut
        , custom "click" (Json.Decode.succeed { message = BubbleClicked oerUrl, stopPropagation = True, preventDefault = True })
        , class "UserSelectNone"
        ] ++ outline)
        []


interp : Float -> Float -> Float -> Float
interp phase a b =
  phase * b + (1-phase) * a


colorFromBubble : Bubble -> Color.Color
colorFromBubble {hue, alpha, saturation} =
  Color.hsla hue saturation 0.5 alpha


averageOf getterFunction records =
  (records |> List.map getterFunction |> List.sum) / (records |> List.length |> toFloat)


rawBubbleAlpha =
  0.28


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


viewPopup : Model -> BubblePopupState -> Bubble -> List (Element.Attribute Msg)
viewPopup model {oerUrl, entityId, content} {posX, posY, size} =
  let
      (text, popupWidth) =
        case content of
          DefinitionInBubblePopup ->
            (entityId ++ " definition goes here", 170)

          MentionInBubblePopup {sentence} ->
            (sentence, 170) -- If we want to make it wider we need to find a solution to prevent the popup from being occluded by any OER card to the left

      box =
        text
        |> bodyWrap []
        |> List.singleton
        |> menuColumn [ Element.width <| px popupWidth, padding 10 ]
  in
      none
      |> el [ above box, moveRight <| posX * contentWidth + marginX - popupWidth/2, moveDown <| (posY - size*3.5*bubbleZoom) * contentHeight + marginTop - 5 ]
      |> inFront
      |> List.singleton
