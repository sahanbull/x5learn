module Update.BubblePopup exposing (..)

import List.Extra
import Dict

import Model exposing (..)


updateBubblePopupOnClick : Model -> OerId -> Maybe Popup -> Maybe Popup
updateBubblePopupOnClick model oerId oldPopup =
  case model.hoveringBubbleEntityId of
    Nothing -> -- shouldn't happen
      oldPopup

    Just entityId ->
      let
          existingState =
            case model.popup of
              Just (BubblePopup state) ->
                if state.oerId==oerId && state.entityId==entityId then
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
              Just <| initialPopup model oerId entityId


initialPopup : Model -> OerId -> String -> Popup
initialPopup model oerId entityId =
  let
      nextContents : List BubblePopupContent
      nextContents =
        getMentions model oerId entityId
        |> List.map MentionInBubblePopup
  in
      BubblePopup <| BubblePopupState oerId entityId DefinitionInBubblePopup nextContents


updatedPopup : BubblePopupState -> Maybe Popup
updatedPopup state =
  case state.nextContents of
    [] ->
      Nothing

    x :: xs ->
      Just <| BubblePopup <| { state | content = x, nextContents = xs }
