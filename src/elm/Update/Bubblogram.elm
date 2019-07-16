module Update.Bubblogram exposing (addBubblogram)

import Dict exposing (Dict)
import Set exposing (Set)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Model exposing (..)


type alias PositionedCluster = { posX : Float, cluster : Cluster }


addBubblogram : Model -> OerId -> WikichunkEnrichment -> WikichunkEnrichment
addBubblogram model oerId ({chunks, clusters, mentions, bubblogram, errors} as enrichment) =
  if errors || bubblogram /= Nothing || List.isEmpty clusters then
    enrichment
  else
    let
        occurrences =
          chunks
          |> occurrencesFromChunks

        entitiesWithAndWithoutDefinitions =
          occurrences
          |> entitiesFromOccurrences
          |> List.filter (\entity -> List.member entity.title (clusters |> List.concat))

        entitiesWithDefinitions =
          entitiesWithAndWithoutDefinitions
          |> List.filter (\entity -> Dict.member entity.id model.entityDefinitions)
    in
        -- if (List.length entitiesWithDefinitions) == (List.length entitiesWithAndWithoutDefinitions) then
        if (List.length entitiesWithDefinitions) > 0 then
          let
              bubbles =
                entitiesWithDefinitions
                |> List.map (bubbleFromEntity model occurrences)
                |> layoutBubbles clusters
          in
              { enrichment | bubblogram = Just { createdAt = model.currentTime, bubbles = bubbles } }
        else
          enrichment


entitiesFromOccurrences : List Occurrence -> List Entity
entitiesFromOccurrences occurrences =
  occurrences
  |> List.map .entity
  |> List.Extra.uniqueBy .id


entityRelevance occurrences entity =
  let
      frequency =
        occurrences
        |> List.filter (\occurrence -> occurrence.entity.id == entity.id)
        |> List.length
  in
      frequency -- also consider adding extra factors e.g. average rank (e.g. index in chunk) and trueskill values


occurrencesFromChunks : List Chunk -> List Occurrence
occurrencesFromChunks chunks =
  let
      nChunksMinus1max1 = (List.length chunks) - 1 |> max 1 |> toFloat
  in
      chunks
      |> List.indexedMap (occurrencesFromChunk nChunksMinus1max1)
      |> List.concat


occurrencesFromChunk : Float -> Int -> Chunk -> List Occurrence
occurrencesFromChunk nChunksMinus1max1 chunkIndex {entities, length} =
  let
      approximatePositionInText =
        (toFloat chunkIndex) / nChunksMinus1max1

      nEntitiesMinus1 =
        (List.length entities) - 1
  in
      entities
      |> List.indexedMap (occurrenceFromEntity approximatePositionInText nEntitiesMinus1)


occurrenceFromEntity : Float -> Int -> Int -> Entity -> Occurrence
occurrenceFromEntity approximatePositionInText nEntitiesMinus1 entityIndex entity =
  let
      rank =
        (toFloat entityIndex) / (toFloat nEntitiesMinus1)
  in
      Occurrence entity approximatePositionInText rank


bubbleFromEntity : Model -> List Occurrence -> Entity -> Bubble
bubbleFromEntity model occurrences entity =
  let
      occurrencesOfThisEntity =
        occurrences
        |> List.filter (\o -> o.entity.id == entity.id)

      initialPosX =
        occurrencesOfThisEntity
        |> averageOf .approximatePositionInText
        |> (*) 0.6

      initialPosY =
        occurrencesOfThisEntity
        |> averageOf .rank

      initialSize =
        -- occurrencesOfThisEntity |> List.length |> toFloat |> sqrt
        0

      finalPosX =
        occurrencesOfThisEntity
        |> averageOf .approximatePositionInText
        |> (*) 0.6

      finalPosY =
        occurrencesOfThisEntity
        |> averageOf .rank

      finalSize =
        0.4 + (occurrencesOfThisEntity |> List.length |> toFloat |> sqrt) / 2

      isSearchTerm =
        isEqualToSearchString model entity.title

      (hue, saturation, alpha) =
        if isSearchTerm then
          (0.145, 0.9, 0.8)
        else
          (0.536, 0, 0.05 + 0.3 * finalSize)

      initialCoordinates =
        { posX = initialPosX
        , posY = initialPosY
        , size = initialSize
        }

      finalCoordinates =
        { posX = finalPosX
        , posY = finalPosY
        , size = finalSize
        }
  in
      { entity = entity
      , hue = hue
      , saturation = saturation
      , alpha = alpha
      , initialCoordinates = initialCoordinates
      , finalCoordinates = finalCoordinates
      }


layoutBubbles : List Cluster -> List Bubble -> List Bubble
layoutBubbles clusters bubbles =
  let
      nBubblesMinus1max1 =
        (List.length bubbles) - 1 |> max 1 |> toFloat

      setPosY ({finalCoordinates} as bubble) =
        let
            index =
              indexOf bubble.entity.title (clusters |> List.concat)
        in
            { bubble | finalCoordinates = { finalCoordinates | posY = (toFloat index) / nBubblesMinus1max1 * 0.85 + 0.05 } }

      setPosXbyCluster ({entity, finalCoordinates} as bubble) =
        let
            {cluster, posX} =
              getPositionedCluster entity.title

            indexInCluster =
              indexOf bubble.entity.title cluster

            offsetX =
              0
              -- let
              --     n =
              --       List.length cluster
              --     amount =
              --       if n<3 then
              --         0*0.04
              --       else
              --         0*0.06
              -- in
              --     amount * (indexInCluster + n + 1 |> modBy 2 |> toFloat)
        in
            { bubble | finalCoordinates = { finalCoordinates | posX = posX + offsetX } }

      getPositionedCluster : EntityTitle -> PositionedCluster
      getPositionedCluster entityTitle =
        let
            helper positionedClusters =
              case positionedClusters of
                positionedCluster :: rest ->
                  if positionedCluster.cluster |> List.member entityTitle then
                    positionedCluster
                  else
                    helper rest

                [] ->
                  PositionedCluster 0.9 []
        in
            helper clustersWithXpositions

      clustersWithXpositions : List PositionedCluster
      clustersWithXpositions =
        let
            getBubbleXposition : EntityTitle -> Float
            getBubbleXposition entityTitle =
              case bubbles |> List.filter (\{entity} -> entity.title == entityTitle) |> List.head of
                Nothing ->
                  0.1

                Just bubble ->
                  bubble.finalCoordinates.posX

            meanXPosition : Cluster -> Float
            meanXPosition entityTitles =
              entityTitles
              |> List.map getBubbleXposition
              |> mean 0.5

            measureBoundariesX {cluster, posX} =
              let
                  bubblesInThisCluster =
                    bubbles
                    |> List.filter (\{entity} -> List.member entity.title cluster)

                  minX =
                    posX - sizeOfBiggestBubble

                  maxX =
                    posX + widthOfWidestLabel

                  sizeOfBiggestBubble : Float
                  sizeOfBiggestBubble =
                    bubblesInThisCluster
                    |> List.map .finalCoordinates
                    |> List.map .size
                    |> List.map ((*) bubbleZoom)
                    |> List.maximum
                    |> Maybe.withDefault 0.1

                  widthOfWidestLabel =
                    bubblesInThisCluster
                    |> List.filter (\{entity} -> List.member entity.title cluster)
                    |> List.map approximateLabelWidth
                    |> List.maximum
                    |> Maybe.withDefault 0.2
              in
                  { cluster = cluster, posX = posX, minX = minX, maxX = maxX }

            quantizeXposition index positionedCluster =
              let
                  n =
                    (clusters |> List.length |> toFloat) - 1 |> max 1
                  posX =
                    interp ((toFloat index) / n) 0.1 0.8
              in
                  { positionedCluster | posX = posX }

            clustersWithPreliminaryXpositionsAndBoundaries =
              clusters
              |> List.map (\cluster -> { posX = meanXPosition cluster, cluster = cluster })
              |> List.sortBy .posX
              |> List.indexedMap quantizeXposition
              |> List.map measureBoundariesX

            overallMinX =
              clustersWithPreliminaryXpositionsAndBoundaries
              |> List.map .minX
              |> List.minimum
              |> Maybe.withDefault 0

            overallMaxX =
              clustersWithPreliminaryXpositionsAndBoundaries
              |> List.map .maxX
              |> List.maximum
              |> Maybe.withDefault 1

            transformToFitClusterToContainerX {cluster, posX} =
              { cluster = cluster, posX = posX / (overallMaxX - overallMinX) * 0.85 - overallMinX + 0.05 }
        in
            clustersWithPreliminaryXpositionsAndBoundaries
            |> List.map transformToFitClusterToContainerX
  in
      bubbles
      |> List.sortBy (\{finalCoordinates} -> finalCoordinates.size)
      |> List.reverse
      |> List.map setPosY
      |> List.map setPosXbyCluster


indexOf : a -> List a -> Int
indexOf element list =
  let
      helper index xs =
        case xs of
          x::rest ->
            if x==element then
              index
            else
              helper (index+1) rest

          _ ->
            -1
  in
      helper 0 list


mean : Float -> List Float -> Float
mean default xs =
  if xs == [] then
     default
  else
    (List.sum xs) / (List.length xs |> toFloat)


approximateLabelWidth : Bubble -> Float
approximateLabelWidth {entity} =
  (toFloat <| String.length entity.title) * 0.025
