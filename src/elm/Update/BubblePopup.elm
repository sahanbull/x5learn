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
