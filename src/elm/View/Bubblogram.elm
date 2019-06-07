module View.Bubblogram exposing (viewBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)

import List.Extra

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)

import Element exposing (el, html, inFront, row, padding, spacing, px, clipX)
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
  cardWidth - 2*margin


contentHeight =
  imageHeight - 2*margin - fragmentsBarHeight


margin =
  30


viewBubblogram model url chunks =
  let
      mergePhase =
        (millisSinceEnrichmentLoaded model url |> toFloat) / (toFloat enrichmentAnimationDuration) |> Basics.min 1

      widthString =
        containerWidth |> String.fromInt

      heightString =
        containerHeight |> String.fromInt

      bubbles =
        occurrencesFromChunks chunks
        |> bubblesFromOccurrences mergePhase
        |> List.sortBy .size
        |> List.reverse

      svgBubbles =
        bubbles
        |> List.indexedMap (viewBubble model url)

      background =
        rect [ width widthString, height heightString, fill "#191919" ] []

      keyConcepts =
        bubbles
        |> List.Extra.uniqueBy (\bubble -> bubble.entity.title)
        |> List.take 3
        |> List.map viewKeyConcept
        |> row [ spacing 18, padding 8, Element.width <| px <| containerWidth-8, clipX ]
        |> inFront
  in
      [ background ] ++ svgBubbles
      |> svg [ width widthString, height heightString, viewBox <| "0 0 " ++ ([ widthString, heightString ] |> String.join " ") ]
      |> html
      |> el [ keyConcepts ]


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


bubblesFromOccurrences : Float -> List Occurrence -> List Bubble
bubblesFromOccurrences mergePhase occurrences =
  occurrences
  |> List.map (bubbleFromOccurrence mergePhase occurrences)


bubbleFromOccurrence : Float -> List Occurrence -> Occurrence -> Bubble
bubbleFromOccurrence mergePhase occurrences occurrence =
  let
      occurrencesWithSameEntityId =
        occurrences
        |> List.filter (\o -> o.entity.id == occurrence.entity.id)

      mergedPosX =
        occurrencesWithSameEntityId
        |> averageOf .posX

      mergedPosY =
        occurrencesWithSameEntityId
        |> averageOf .posY

      mergedSize =
        occurrencesWithSameEntityId |> List.length |> toFloat |> sqrt
  in
      { entity = occurrence.entity
      , posX = interp mergePhase occurrence.posX mergedPosX
      , posY = interp mergePhase occurrence.posY mergedPosY
      , size = interp mergePhase 1 mergedSize
      , hue = 0.144 -- 240 - 180 * (fakeStringDistanceFromSearchTerm occurrence.entityId)
      , alpha = 0.3
      , saturation = fakeLexicalSimilarityToSearchTerm occurrence.entity.id
      }
      -- , hue = 240 - 180 * (fakePredictedLevelOfInterestFromEntity occurrence.entityId)
      -- , alpha = fakePredictedLevelOfKnowledgeFromEntity occurrence.entityId
      -- , saturation = fakedLevelOfTheSystemsConfidenceInHue occurrence.entityId


fakeLexicalSimilarityToSearchTerm : String -> Float
fakeLexicalSimilarityToSearchTerm id =
  if (String.length id) == 7 then 0.9 else 0


-- fakePredictedLevelOfKnowledgeFromEntity : String -> Float
-- fakePredictedLevelOfKnowledgeFromEntity id =
--   ((String.length id |> modBy 3) + 1 |> toFloat) / 3


-- fakePredictedLevelOfInterestFromEntity : String -> Float
-- fakePredictedLevelOfInterestFromEntity id =
--   (String.length id |> modBy 4 |> toFloat) / 3


-- fakedLevelOfTheSystemsConfidenceInHue : String -> Float
-- fakedLevelOfTheSystemsConfidenceInHue id =
--   (String.length id |> modBy 5 |> toFloat) / 5 * 100


viewBubble : Model -> OerUrl -> Int -> Bubble -> Svg.Svg Msg
viewBubble model oerUrl bubbleIndex ({entity, posX, posY, size} as bubble) =
  let
      bubbleIdentifier =
        BubbleIdentifier oerUrl bubbleIndex

      isHovering =
        model.hoveringBubbleIdentifier == Just bubbleIdentifier

      outline =
        if isHovering then
          [ stroke "white", strokeWidth "2" ]
        else
          []

      tooltip =
        if isHovering then
          [ Svg.title [] [ text <| entity.title ] ]
        else
          []
  in
      circle
        ([ cx (posX * (toFloat contentWidth) + margin |> String.fromFloat)
        , cy (posY * (toFloat contentHeight) + margin + 20 |> String.fromFloat)
        , r (size * (toFloat contentWidth) * 0.042 |> String.fromFloat)
        , fill <| Color.toCssString <| colorFromBubble bubble
        , onMouseOver <| MouseOverBubble <| Just <| bubbleIdentifier
        , onMouseOut <| MouseOverBubble Nothing
        ] ++ outline)
        tooltip


interp : Float -> Float -> Float -> Float
interp phase a b =
  phase * b + (1-phase) * a


colorFromBubble : Bubble -> Color.Color
colorFromBubble {hue, alpha, saturation} =
  Color.hsla hue saturation 0.5 alpha


averageOf getterFunction records =
  (records |> List.map getterFunction |> List.sum) / (records |> List.length |> toFloat)


viewKeyConcept bubble =
  bubble.entity.title
  |> truncateSentence 20
  -- |> captionNowrap [ Font.color <| elementColorFromElmColor <| colorFromBubble bubble ]
  |> captionNowrap [ whiteText ]


elementColorFromElmColor elmColor =
  elmColor
  |> Color.toRgba
  |> Element.fromRgb
