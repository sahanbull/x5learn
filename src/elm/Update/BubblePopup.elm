module Update.BubblePopup exposing (..)

import List.Extra

import Model exposing (..)


updateBubblePopup : Model -> OerUrl -> Entity -> List Chunk -> Maybe Popup -> Maybe Popup
updateBubblePopup model oerUrl entity chunks popup =
  let
      existingState =
        case model.popup of
          Just (BubblePopup state) ->
            if state.oerUrl==oerUrl && state.entityId==entity.id then
              Just state
            else
              Nothing

          _ ->
            Nothing
  in
      case existingState of
        Just state ->
          updatedPopup state

        Nothing ->
          Just <| initialPopup model oerUrl entity chunks


initialPopup : Model -> OerUrl -> Entity -> List Chunk -> Popup
initialPopup model oerUrl entity chunks =
  let
      entityTitleLowerCase =
        String.toLower entity.title

      mentionsInChunk : Chunk -> List { indexInChunk : Int, sentence : String}
      mentionsInChunk chunk =
        chunk.text
        |> extractSentences
        |> List.filter (\sentence -> String.contains entityTitleLowerCase (String.toLower sentence))
        |> List.indexedMap (\index sentence -> { indexInChunk = index, sentence = sentence})
        -- |> List.indexedMap (,)
--         |> List.indexedMap (\indexInChunk sentence -> { })

      nextContents : List BubblePopupContent
      nextContents =
        chunks
        |> List.map mentionsInChunk
        |> List.concat
        |> List.indexedMap (\chunkIndex {indexInChunk, sentence} -> MentionInOer chunkIndex indexInChunk sentence)
        |> List.Extra.uniqueBy .sentence
        |> List.map Mention
  in
      BubblePopup <| BubblePopupState oerUrl entity.id Definition nextContents


updatedPopup : BubblePopupState -> Maybe Popup
updatedPopup state =
  case state.nextContents of
    [] ->
      Nothing

    x :: xs ->
      Just <| BubblePopup <| { state | content = x, nextContents = xs }


looksRoughlyLikeAnEnglishSentence str =
  let
      words =
        str
        |> String.split " "

      nWords =
        words
        |> List.length

      nWordsThatLookRoughlyLikeEnglish =
        words
        |> List.filter (\word -> word |> String.all (\c -> Char.isUpper c || Char.isLower c))
        |> List.length

  in
      nWords > 4
      && nWords < 20
      && nWordsThatLookRoughlyLikeEnglish > (nWords // 2)


extractSentences text =
  text
  |> String.split ". "
  |> List.concatMap (String.split "? ")
  |> List.concatMap (String.split "! ")
  |> List.concatMap (String.split "\n")
  |> List.concatMap (String.split "\r")
  |> List.concatMap (String.split "\t")
  |> List.concatMap (String.split "")
  |> List.filter (\sentence -> looksRoughlyLikeAnEnglishSentence sentence)
