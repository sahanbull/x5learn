module View.ConceptBubbles exposing (viewConceptBubbles)

import Svg exposing (..)
import Svg.Attributes exposing (..)

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


type alias Bubble =
  { posX : Float
  , posY : Float
  , size : Float
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
  20


viewConceptBubbles chunks =
  let
      widthString =
        containerWidth |> String.fromInt

      heightString =
        containerHeight |> String.fromInt

      bubbles =
        bubblesFromChunks chunks
        |> List.map viewBubble

      background =
        rect [ width widthString, height heightString, fill "#191919" ] []
  in
      [ background ] ++ bubbles
      |> svg [ width widthString, height heightString, viewBox <| "0 0 " ++ ([ widthString, heightString ] |> String.join " ") ]


bubblesFromChunks : List Chunk -> List Bubble
bubblesFromChunks chunks =
  let
      nChunksMinus1 = (List.length chunks) - 1
  in
      chunks
      |> List.indexedMap (bubblesFromChunk nChunksMinus1)
      |> List.concat


bubblesFromChunk : Int -> Int -> Chunk -> List Bubble
bubblesFromChunk nChunksMinus1 chunkIndex {entities, length} =
  let
      posX =
        (toFloat chunkIndex) / (toFloat nChunksMinus1)

      nEntitiesMinus1 =
        (List.length entities) - 1
  in
      entities
      |> List.indexedMap (bubbleFromEntity posX nEntitiesMinus1)


bubbleFromEntity : Float -> Int -> Int -> Entity -> Bubble
bubbleFromEntity posX nEntitiesMinus1 entityIndex {id} =
  let
      posY =
        (toFloat entityIndex) / (toFloat nEntitiesMinus1)
  in
      Bubble posX posY 0.05


viewBubble : Bubble -> Svg.Svg Msg
viewBubble {posX, posY, size} =
  circle
    [ cx (posX * (toFloat contentWidth) + margin |> String.fromFloat)
    , cy (posY * (toFloat contentHeight) + margin |> String.fromFloat)
    , r (size * (toFloat contentWidth) |> String.fromFloat)
    , fill "blue"
    ]
    []
