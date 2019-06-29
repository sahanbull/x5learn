module Update.Bubblogram exposing (addBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Model exposing (..)


type alias EntityId = String

type alias Cluster = List EntityId

type alias Proximity = ((EntityId, EntityId), Float)


addBubblogram : Model -> OerUrl -> WikichunkEnrichment -> WikichunkEnrichment
addBubblogram model oerUrl ({chunks, bubblogram, errors} as enrichment) =
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
          |> List.filter (\entity -> (String.length entity.title)>1 && Dict.member entity.id model.entityDefinitions && hasMentions model oerUrl entity.id)
          |> List.sortBy (entityRelevance occurrences)
          |> List.reverse
          |> List.take 5

        clusters =
          clustersFromEntities (rankedEntities |> List.map .id) occurrences chunks

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
      medianPosX =
        case bubbles |> List.sortBy (\{initialCoordinates} -> initialCoordinates.posX) |> List.drop ((List.length bubbles)//2) |> List.head of
          Nothing -> -- shouldn't happen
            0.5

          Just bubble ->
            bubble.finalCoordinates.posX

      nBubblesMinus1max1 =
        (List.length bubbles) - 1 |> max 1 |> toFloat

      -- setPosY ({finalCoordinates} as bubble) =
      --   let
      --       index =
      --         indexOf bubble.entity.id (clusters |> List.concat)
      --   in
      --       { bubble | finalCoordinates = { finalCoordinates | posY = (toFloat index) / nBubblesMinus1max1 * 0.85 + 0.05 } }

      -- setPosX index ({entity, finalCoordinates} as bubble) =
      --   let
      --       approximateLabelWidth =
      --         (toFloat <| String.length entity.title) * 0.02

      --       posX =
      --         if finalCoordinates.posX < medianPosX then
      --           0.03 * finalCoordinates.size + (if index==1 || index==((List.length bubbles) - 1) then 0.06 else 0)
      --         else
      --           0.95 - approximateLabelWidth - 0.03 * finalCoordinates.size
      --   in
      --       { bubble | finalCoordinates = { finalCoordinates | posX = posX } }

      -- bubblesPositionedByCluster =
      --   clustersWithPositions
      --   |> List.

  in
      bubbles
      |> List.sortBy (\{finalCoordinates} -> finalCoordinates.size)
      |> List.reverse
      -- |> List.indexedMap setPosX
      -- |> List.map setPosY


proximitiesByCooccurrence : List EntityId -> List Occurrence -> List Chunk -> Dict (EntityId, EntityId) Float
proximitiesByCooccurrence entityIds occurrences chunks =
  let
      countOccurrencesOfEntity id =
        occurrences
        |> List.filter (\{entity} -> entity.id == id)
        |> List.length
        |> toFloat

      occurrenceCounts =
        entityIds
        |> List.map (\id -> (id, countOccurrencesOfEntity id))
        |> Dict.fromList
        |> Debug.log "occurrenceCounts"

      cooccurrenceCountBetween : EntityId -> EntityId -> Int
      cooccurrenceCountBetween entityId otherEntityId =
        chunks
        |> List.foldl (\chunk sum -> sum + (if listContainsBoth entityId otherEntityId (chunk.entities |> List.map .id) then 1 else 0)) 0

      proximityBetween : EntityId -> Float -> EntityId -> Proximity
      proximityBetween otherEntityId otherOccurrenceCount entityId =
        let
            occurrenceCount =
              Dict.get entityId occurrenceCounts |> Maybe.withDefault 1

            proximity =
              (cooccurrenceCountBetween entityId otherEntityId |> toFloat) / (max occurrenceCount otherOccurrenceCount)
        in
            ((entityId, otherEntityId), proximity)

      proximitiesPerEntity : Int -> EntityId -> List Proximity
      proximitiesPerEntity index entityId =
        let
            occurrenceCount =
              Dict.get entityId occurrenceCounts |> Maybe.withDefault 1
        in
            entityIds
            |> List.drop (index+1)
            |> List.map (proximityBetween entityId occurrenceCount)
  in
      entityIds
      |> List.indexedMap proximitiesPerEntity
      |> List.concat
      |> Dict.fromList
      |> Debug.log "proximities"


clustersFromEntities : List EntityId -> List Occurrence -> List Chunk -> List Cluster
clustersFromEntities entityIds occurrences chunks =
  let
      proximities : Dict (EntityId, EntityId) Float
      proximities =
        proximitiesByCooccurrence entityIds occurrences chunks

      getProximityBetweenEntityPair : (EntityId, EntityId) -> Float
      getProximityBetweenEntityPair pair =
        Dict.get pair proximities
        |> Maybe.withDefault 0

      nearestClusters : List Cluster -> List Cluster
      nearestClusters clusters =
        let
            proximityOfNearestPairOfEntities : List (EntityId, EntityId) -> Float
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
            |> Debug.log "nearestClusters"

      combineNearestClusters : List Cluster -> List Cluster
      combineNearestClusters clusters =
        clusters
        |> combineClusters (nearestClusters clusters)

      iteration1 =
        entityIds
        |> List.map clusterFromEntityId
        -- proximities entityIds
        -- |> Dict.toList
        -- |> List.reverse
        -- |> combineFirstTwo
        |> Debug.log "iteration1"

      iteration2 =
        iteration1
        |> combineNearestClusters
        |> Debug.log "iteration2"

      iteration3 =
        iteration2
        |> combineNearestClusters
        |> Debug.log "iteration3"
  in
      iteration3


combineClusters : List Cluster -> List Cluster -> List Cluster
combineClusters clustersToBeCombined allClusters =
  let
      remainingClusters =
        allClusters
        |> List.filter (\cluster -> List.member cluster clustersToBeCombined |> not)
  in
      (clustersToBeCombined |> List.concat |> List.singleton) ++ remainingClusters


clusterFromEntityId : EntityId -> Cluster
clusterFromEntityId entityId =
  [ entityId ]


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
