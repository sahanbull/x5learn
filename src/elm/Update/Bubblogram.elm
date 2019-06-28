module Update.Bubblogram exposing (addBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Model exposing (..)


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

        proximityMatrix =
          proximityMatrixFromEntities rankedEntities chunks occurrences

        bubbles =
          rankedEntities
          |> List.map (bubbleFromEntity model occurrences rankedEntities)
          |> layoutBubbles
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


-- fakeLexicalSimilarityToSearchTerm : String -> Float
-- fakeLexicalSimilarityToSearchTerm id =
--   if (String.length id) == 7 then 0.5 else 0


-- fakePredictedLevelOfKnowledgeFromEntity : String -> Float
-- fakePredictedLevelOfKnowledgeFromEntity id =
--   ((String.length id |> modBy 3) + 1 |> toFloat) / 3


-- fakePredictedLevelOfInterestFromEntity : String -> Float
-- fakePredictedLevelOfInterestFromEntity id =
--   (String.length id |> modBy 4 |> toFloat) / 3


-- fakedLevelOfTheSystemsConfidenceInHue : String -> Float
-- fakedLevelOfTheSystemsConfidenceInHue id =
--   (String.length id |> modBy 5 |> toFloat) / 5 * 100


layoutBubbles : List Bubble -> List Bubble
layoutBubbles bubbles =
  let
      medianPosX =
        case bubbles |> List.sortBy (\{initialCoordinates} -> initialCoordinates.posX) |> List.drop ((List.length bubbles)//2) |> List.head of
          Nothing -> -- shouldn't happen
            0.5

          Just bubble ->
            bubble.finalCoordinates.posX

      nBubblesMinus1max1 =
        (List.length bubbles) - 1 |> max 1 |> toFloat

      setPosY index ({finalCoordinates} as bubble) =
        { bubble | finalCoordinates = { finalCoordinates | posY = (toFloat index) / nBubblesMinus1max1 * 0.85 + 0.05 } }

      setPosX index ({entity, finalCoordinates} as bubble) =
        let
            approximateLabelWidth =
              (toFloat <| String.length entity.title) * 0.02

            posX =
              if finalCoordinates.posX < medianPosX then
                0.03 * finalCoordinates.size + (if index==1 || index==((List.length bubbles) - 1) then 0.06 else 0)
              else
                0.95 - approximateLabelWidth - 0.03 * finalCoordinates.size
        in
            { bubble | finalCoordinates = { finalCoordinates | posX = posX } }
  in
      bubbles
      |> List.sortBy (\{finalCoordinates} -> finalCoordinates.size)
      |> List.reverse
      |> List.indexedMap setPosX
      |> List.indexedMap setPosY


proximityMatrixFromEntities : List Entity -> List Chunk -> List Occurrence -> Dict (String, String) Float
proximityMatrixFromEntities entities chunks occurrences =
  let
      countOccurrencesOfEntity id =
        occurrences
        |> List.filter (\{entity} -> entity.id == id)
        |> List.length
        |> toFloat

      occurrenceCounts =
        entities
        |> List.map (\{id} -> (id, countOccurrencesOfEntity id))
        |> Dict.fromList
        |> Debug.log "occurrenceCounts"

      entityNamesForDebugging =
        entities
        |> List.map .title
        |> Debug.log "entityTitles"

      entityIds =
        entities
        |> List.map .id
        |> Debug.log "entityIds"

      cooccurrenceCountBetween : String -> String -> Int
      cooccurrenceCountBetween entityId otherEntityId =
        chunks
        |> List.foldl (\chunk sum -> sum + (if listContainsBoth entityId otherEntityId (chunk.entities |> List.map .id) then 1 else 0)) 0

      proximityBetween : String -> Float -> String -> Float
      proximityBetween otherEntityId otherOccurrenceCount entityId =
        let
            occurrenceCount =
              Dict.get entityId occurrenceCounts |> Maybe.withDefault 1
        in
            (cooccurrenceCountBetween entityId otherEntityId |> toFloat) / (max occurrenceCount otherOccurrenceCount)

      proximitiesPerEntity : String -> List Float
      proximitiesPerEntity entityId =
        let
            occurrenceCount =
              Dict.get entityId occurrenceCounts |> Maybe.withDefault 1
        in
            entityIds
            |> List.map (proximityBetween entityId occurrenceCount)
            -- |> Debug.log "proximitiesPerEntity"

      proximities =
        entityIds
        |> List.map proximitiesPerEntity
        |> Debug.log "proximities"
  in
      Dict.empty


listContainsBoth a b list =
  List.member a list && List.member b list
