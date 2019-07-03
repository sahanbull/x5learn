module Update.Bubblogram exposing (addBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Model exposing (..)


type alias Cluster = List EntityTitle

type alias Proximity = ((EntityTitle, EntityTitle), Float)

type alias PositionedCluster = { posX : Float, cluster : Cluster }


addBubblogram : Model -> OerUrl -> WikichunkEnrichment -> WikichunkEnrichment
addBubblogram model oerUrl ({chunks, graph, mentions, bubblogram, errors} as enrichment) =
  if errors || bubblogram /= Nothing then
    enrichment
  else
    let
        occurrences =
          chunks
          |> occurrencesFromChunks

        rankedEntities =
          occurrences
          |> entitiesFromOccurrences
          |> List.filter (\entity -> Dict.member entity.title graph && Dict.member entity.id model.entityDefinitions)

        clusters =
          clustersFromEntities (rankedEntities |> List.map .title) graph

        bubbles =
          rankedEntities
          |> List.map (bubbleFromEntity model occurrences rankedEntities)
          |> layoutBubbles clusters
    in
        { enrichment | bubblogram = Just { createdAt = model.currentTime, bubbles = bubbles } }


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


bubbleFromEntity : Model -> List Occurrence -> List Entity -> Entity -> Bubble
bubbleFromEntity model occurrences rankedEntities entity =
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
              |> mean

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
                  posX =
                    interp ((toFloat index) / ((clusters |> List.length |> toFloat) - 1)) 0.1 0.8
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


proximitiesByGraph : List EntityTitle -> Dict EntityTitle (List EntityTitle) -> Dict (EntityTitle, EntityTitle) Float
proximitiesByGraph entityTitles graph =
  let
      areEntitiesConnected : EntityTitle -> EntityTitle -> Bool
      areEntitiesConnected a b =
        let
            hasConnections : EntityTitle -> EntityTitle -> Bool
            hasConnections entityTitle otherEntityTitle =
              case graph |> Dict.get entityTitle of
                Nothing ->
                  False

                Just links ->
                  List.member otherEntityTitle links
        in
            hasConnections a b || hasConnections b a

      proximityBetween : EntityTitle -> EntityTitle -> Proximity
      proximityBetween otherEntityTitle entityTitle =
        let
            proximity =
              if areEntitiesConnected entityTitle otherEntityTitle then 1 else 0
        in
            ((entityTitle, otherEntityTitle), proximity)

      proximitiesPerEntity : Int -> EntityTitle -> List Proximity
      proximitiesPerEntity index entityTitle =
        entityTitles
        |> List.drop (index+1)
        |> List.map (proximityBetween entityTitle)
  in
      entityTitles
      |> List.indexedMap proximitiesPerEntity
      |> List.concat
      |> Dict.fromList


clustersFromEntities : List EntityTitle -> Dict EntityTitle (List EntityTitle) -> List Cluster
clustersFromEntities entityTitles graph =
  let
      proximities : Dict (EntityTitle, EntityTitle) Float
      proximities =
        proximitiesByGraph entityTitles graph

      getProximityBetweenEntityPair : (EntityTitle, EntityTitle) -> Float
      getProximityBetweenEntityPair pair =
        Dict.get pair proximities
        |> Maybe.withDefault 0

      nearestClusters : List Cluster -> List Cluster
      nearestClusters clusters =
        let
            proximityOfNearestPairOfEntities : List (EntityTitle, EntityTitle) -> Float
            proximityOfNearestPairOfEntities pairs =
              pairs
              |> List.map getProximityBetweenEntityPair
              |> List.maximum
              |> Maybe.withDefault 0

            proximityBetweenClusterPair : (Cluster, Cluster) -> Float
            proximityBetweenClusterPair (a, b) =
              allPairsBetween a b
              |> proximityOfNearestPairOfEntities
        in
            clusters
            |> allPairsWithin
            |> List.sortBy proximityBetweenClusterPair
            |> List.reverse
            |> tuplesToLists
            |> List.take 1
            |> List.concat

      combineNearestClusters : List Cluster -> List Cluster
      combineNearestClusters clusters =
        clusters
        |> combineClusters (nearestClusters clusters)
  in
      entityTitles
      |> List.map clusterFromEntityTitle
      -- |> Debug.log "clusters1"
      |> combineNearestClusters
      |> combineNearestClusters
      -- |> Debug.log "clusters3"


combineClusters : List Cluster -> List Cluster -> List Cluster
combineClusters clustersToBeCombined allClusters =
  let
      remainingClusters =
        allClusters
        |> List.filter (\cluster -> List.member cluster clustersToBeCombined |> not)
  in
      (clustersToBeCombined |> List.concat |> List.singleton) ++ remainingClusters


clusterFromEntityTitle : EntityTitle -> Cluster
clusterFromEntityTitle entityTitle =
  [ entityTitle ]


allPairsBetween : List a -> List b -> List (a, b)
allPairsBetween xs ys =
  let
      pairsWith x =
        ys
        |> List.map (\y -> (x, y))
  in
      xs
      |> List.concatMap pairsWith


allPairsWithin : List a -> List (a, a)
allPairsWithin xs =
  let
      pairsWith index otherX =
        xs
        |> List.drop (index+1)
        |> List.map (\x -> (x, otherX))
  in
      xs
      |> List.indexedMap pairsWith
      |> List.concat


tuplesToLists : List (a, a) -> List (List a)
tuplesToLists tuples =
  tuples
  |> List.map (\(x,y) -> [ x, y ])


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


mean : List Float -> Float
mean xs =
  (List.sum xs) / (List.length xs |> toFloat)


approximateLabelWidth : Bubble -> Float
approximateLabelWidth {entity} =
  (toFloat <| String.length entity.title) * 0.025
