module Update.BubblePopup exposing (..)

import List.Extra
import Dict

import Model exposing (..)


updateBubblePopupOnClick : Model -> OerUrl -> Maybe Popup -> Maybe Popup
updateBubblePopupOnClick model oerUrl oldPopup =
  case model.hoveringBubbleEntityId of
    Nothing -> -- shouldn't happen
      oldPopup

    Just entityId ->
      let
          existingState =
            case model.popup of
              Just (BubblePopup state) ->
                if state.oerUrl==oerUrl && state.entityId==entityId then
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
              Just <| initialPopup model oerUrl entityId


initialPopup : Model -> OerUrl -> String -> Popup
initialPopup model oerUrl entityId =
  let
      nextContents : List BubblePopupContent
      nextContents =
        getMentions model oerUrl entityId
        |> Maybe.withDefault [] -- shouldn't happen
        |> List.map MentionInBubblePopup
  in
      BubblePopup <| BubblePopupState oerUrl entityId DefinitionInBubblePopup nextContents


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
        |> String.toLower
        |> String.split " "

      nWords =
        words
        |> List.length

      nWordsThatLookRoughlyLikeEnglish =
        words
        |> List.filter (\word -> word |> String.all (\c -> Char.isLower c))
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
