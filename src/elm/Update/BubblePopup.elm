module Update.BubblePopup exposing (updateBubblePopupOnTagLabelClicked, setBubblePopupToMention)

import List.Extra
import Dict

import Model exposing (..)


updateBubblePopupOnTagLabelClicked : Model -> OerId -> Maybe Popup -> Maybe Popup
updateBubblePopupOnTagLabelClicked model oerId oldPopup =
  case model.hoveringTagEntityId of
    Nothing -> -- shouldn't happen
      oldPopup

    Just entityId ->
      case model.popup of
        Just (BubblePopup state) ->
          if state.oerId==oerId && state.entityId==entityId then
            case state.content of
              MentionInBubblePopup _ ->
                updatedPopup state

              _ ->
                initialPopup model oerId entityId
          else
            initialPopup model oerId entityId

        _ ->
          initialPopup model oerId entityId


setBubblePopupToMention : OerId -> EntityId -> MentionInOer -> Model -> Model
setBubblePopupToMention oerId entityId mention model =
  let
      popup =
            Just <| BubblePopup <| BubblePopupState oerId entityId (MentionInBubblePopup mention) []
  in
      { model | popup = popup }


initialPopup : Model -> OerId -> String -> Maybe Popup
initialPopup model oerId entityId =
  let
      mentionContents : List BubblePopupContent
      mentionContents =
        getMentions model oerId entityId
        |> List.map MentionInBubblePopup
  in
      case mentionContents of
        first::rest ->
          Just <| BubblePopup <| BubblePopupState oerId entityId first rest

        _ ->
          Nothing


updatedPopup : BubblePopupState -> Maybe Popup
updatedPopup state =
  case state.nextContents of
    [] ->
      Nothing

    x :: xs ->
      Just <| BubblePopup <| { state | content = x, nextContents = xs }
