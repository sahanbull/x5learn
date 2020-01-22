module Update.BubblePopup exposing (updateBubblePopupOnTopicLabelClicked, setBubblePopupToMention)

import List.Extra
import Dict

import Model exposing (..)


{-| This module is responsible for updating the popup in a bubblogram
-}
updateBubblePopupOnTopicLabelClicked : Model -> OerId -> Maybe Popup -> Maybe Popup
updateBubblePopupOnTopicLabelClicked model oerId oldPopup =
  case model.hoveringEntityId of
    Nothing -> -- shouldn't happen
      oldPopup

    Just entityId ->
      case model.popup of
        Just (BubblePopup state) ->
          if state.oerId==oerId && state.entityId==entityId then
            case state.content of
              MentionInBubblePopup _ ->
                stepPopup state

              _ ->
                initialPopup model oerId entityId
          else
            initialPopup model oerId entityId

        _ ->
          initialPopup model oerId entityId


{-| Change the popup content to show the text of a particular mention
-}
setBubblePopupToMention : OerId -> EntityId -> MentionInOer -> Model -> Model
setBubblePopupToMention oerId entityId mention model =
  let
      popup =
            Just <| BubblePopup <| BubblePopupState oerId entityId (MentionInBubblePopup mention) []
  in
      { model | popup = popup }


{-| Initial popup content
-}
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


{-| Change the popup content to the next in the queue
-}
stepPopup : BubblePopupState -> Maybe Popup
stepPopup state =
  case state.nextContents of
    [] ->
      Nothing

    x :: xs ->
      Just <| BubblePopup <| { state | content = x, nextContents = xs }
