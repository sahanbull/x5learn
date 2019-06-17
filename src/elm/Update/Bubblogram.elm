module Update.Bubblogram exposing (addBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode

import List.Extra

import Model exposing (..)


addBubblogram : Model -> OerUrl -> WikichunkEnrichment -> WikichunkEnrichment
addBubblogram model oerUrl enrichment =
  if enrichment.errors || enrichment.bubblogram /= Nothing then
    enrichment
  else
    let
        occurrences =
          enrichment.chunks
          |> occurrencesFromChunks

        rankedEntities =
          occurrences
          |> entitiesFromOccurrences
          |> List.filter (\entity -> (String.length entity.title)>1 && Dict.member entity.id model.entityDefinitions && hasMentions model oerUrl entity.id)
          |> List.sortBy (entityRelevance occurrences)
          |> List.reverse
          |> List.take 5

        bubbles =
          rankedEntities
          |> List.map (bubbleFromEntity model occurrences rankedEntities)
    in
        { enrichment | bubblogram = Just bubbles }


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
      frequency -- also consider adding extra factors e.g. average rank (indexInChunk) and trueskill values


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
      positionInText =
        (toFloat chunkIndex) / (toFloat nChunksMinus1)

      nEntitiesMinus1 =
        (List.length entities) - 1
  in
      entities
      |> List.indexedMap (occurrenceFromEntity positionInText nEntitiesMinus1)


occurrenceFromEntity : Float -> Int -> Int -> Entity -> Occurrence
occurrenceFromEntity positionInText nEntitiesMinus1 entityIndex entity =
  let
      rank =
        (toFloat entityIndex) / (toFloat nEntitiesMinus1)
  in
      Occurrence entity positionInText rank


bubbleFromEntity : Model -> List Occurrence -> List Entity -> Entity -> Bubble
bubbleFromEntity model occurrencesOfAllEntities rankedEntities entity =
  let
      occurrencesOfThisEntity =
        occurrencesOfAllEntities
        |> List.filter (\o -> o.entity.id == entity.id)

      initialPosX =
        occurrencesOfThisEntity
        |> averageOf .positionInText
        |> (*) 0.6

      initialPosY =
        occurrencesOfThisEntity
        |> averageOf .rank

      initialSize =
        -- occurrencesOfThisEntity |> List.length |> toFloat |> sqrt
        0

      finalPosX =
        occurrencesOfThisEntity
        |> averageOf .positionInText
        |> (*) 0.6

      finalPosY =
        occurrencesOfThisEntity
        |> averageOf .rank

      finalSize =
        occurrencesOfThisEntity |> List.length |> toFloat |> sqrt

      isSearchTerm =
        isEqualToSearchString model entity.title

      (hue, saturation, alpha) =
        if isSearchTerm then
          (0.145, 0.9, 0.8)
        else
          (0.536, 0, defaultOpacity)

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


defaultOpacity =
  0.3
