module View.FragmentsBar exposing (..)

import Json.Decode

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onMouseLeave)
import Dict

import Model exposing (..)
import View.Shared exposing (..)
import Msg exposing (..)
import Animation exposing (..)


viewFragmentsBar : Model -> Oer -> List Chunk -> Int -> String -> Element Msg
viewFragmentsBar model oer chunks barWidth barId =
  let
      peekRanges =
        [ rangeMarkers red
        ]
        |> List.concat

      rangeMarkers color =
        case model.peeks |> Dict.get oer.id of
          Nothing ->
            [] -- impossible
          Just ranges ->
            ranges
            |> List.map (\{start,length} -> none |> el [ width (length |> pxFromFraction |> round |> px), height <| px 3, Background.color color, moveRight (start |> pxFromFraction) ] |> inFront)

      pxFromFraction fraction =
        (barWidth |> toFloat) * fraction

      chunkTrigger chunkIndex chunk =
        let
            chunkPopup =
              let
                  entityPopup =
                    case model.popup of
                      Just (ChunkOnBar p) ->
                        p.entityPopup

                      _ ->
                        Nothing
              in
                  { barId = barId, oer = oer, chunk = chunk, entityPopup = entityPopup }

            isPopupOpen =
              case model.popup of
                Just (ChunkOnBar p) ->
                  barId == p.barId && chunk == p.chunk

                _ ->
                  False

            appearance =
              let
                  bg =
                    if isPopupOpen then
                      [ Background.color grey80 ]
                    else
                      []

                  leftBorder =
                    none
                    |> el [ width <| px 1, height <| px fragmentsBarHeight, Background.color veryTransparentWhite ]
                    |> inFront

                  queryHighlight =
                    case model.searchState of
                      Nothing ->
                        []

                      Just {lastSearch} ->
                        case indexOf (String.toLower lastSearch) (chunk.entities |> List.map (\{title} -> String.toLower title)) of
                          Nothing ->
                            []

                          Just index ->
                            let
                                posY =
                                  ((toFloat index)*2.5 + 8 |> floor)
                            in
                                none
                                |> el [ width fill, height (px <| fragmentsBarHeight-posY), moveDown (toFloat <| posY + 1), Background.color white, htmlClass "ChunkQueryHighlight", pointerEventsNone ]
                                |> inFront
                                |> List.singleton
                in
                  ([ leftBorder ] ++ queryHighlight ++ bg)

            popup =
              if isPopupOpen then
                 [ viewChunkPopup model chunkPopup |> inFront ]
              else
                []

            clickHandler =
              case model.inspectorState of
                Nothing ->
                  [ onClickNoBubble <| InspectOer oer chunk.start chunk.length True ]

                _ ->
                  -- if hasYoutubeVideo oer.url then
                  --   [ onClickNoBubble <| YoutubeSeekTo chunk.start ]
                  -- else
                    []

            chunkWidth =
              floor <| chunk.length * (toFloat barWidth) + (if chunkIndex == (List.length chunks)-1 then 0 else 1)
        in
            none
            |> el ([ htmlClass "ChunkTrigger", width <| px <| chunkWidth, height fill, moveRight <| chunk.start * (toFloat barWidth), popupOnMouseEnter (ChunkOnBar chunkPopup), closePopupOnMouseLeave ] ++ appearance ++ popup ++ clickHandler)
            |> inFront

      chunkTriggers =
        chunks
        |> List.indexedMap chunkTrigger

      border =
        [ none |> el [ width fill , Background.color veryTransparentWhite, height <| px 1 ] |> above ]

      background =
        [ Background.color materialDark ]

      scrubCursor =
        if isHovering model oer then
          case model.scrubbing of
            Nothing ->
              []

            Just position ->
              none
              |> el [ width <| px 2, height fill, Background.color white, moveRight ((cardWidth - 2) * position), pointerEventsNone ]
              |> inFront
              |> List.singleton
        else
          []

      mouseLeaveHandler =
        [ onMouseLeave <| ScrubMouseLeave ]
  in
    none
    |> el ([ htmlClass "FragmentsBar", width fill, height <| px <| fragmentsBarHeight, moveUp fragmentsBarHeight ] ++ chunkTriggers ++ border ++ background ++ peekRanges ++ scrubCursor ++ mouseLeaveHandler)


viewChunkPopup model chunkPopup =
  let
      entitiesSection =
        if chunkPopup.chunk.entities |> List.isEmpty then
          [ "No data available" |> text ]
        else
          chunkPopup.chunk.entities
          |> List.map (viewEntityButton model chunkPopup)
          |> column [ width fill ]
          |> List.singleton
  in
      entitiesSection
      |> menuColumn []
      |> el [ moveLeft 30, moveDown fragmentsBarHeight ]


viewEntityButton : Model -> ChunkPopup -> Entity -> Element Msg
viewEntityButton model chunkPopup entity =
  let
      label =
        [ entity.title |> bodyNoWrap [ width fill ]
        , image [ alpha 0.5, alignRight ] { src = svgPath "arrow_right", description = "" }
        ]
          |> row [ width fill, paddingXY 10 5, spacing 10 ]

      backgroundAndSubmenu =
        case chunkPopup.entityPopup of
          Nothing ->
            []

          Just entityPopup ->
            -- if chunkPopup.chunk == chunk && entityPopup.entityId == entityId then
            if entityPopup.entityId == entity.id then
              superLightBackground :: (viewEntityPopup model chunkPopup entityPopup entity)
            else
              []
    in
        button ([ padding 5, width fill, popupOnMouseEnter (ChunkOnBar { chunkPopup | entityPopup = Just { entityId = entity.id, hoveringAction = Nothing } }) ] ++ backgroundAndSubmenu) { onPress = Nothing, label = label }


viewEntityPopup model chunkPopup entityPopup entity =
  let
      actionButtons =
        if isLabStudy1 model then
          []
        else
          [ ("Search", TriggerSearch entity.title)
          ]
          |> List.map (\item -> entityActionButton chunkPopup entityPopup item |> el [ width fill ])

      definition =
        viewDefinition model entity.id

      items =
        definition :: actionButtons
  in
      items
      |> menuColumn []
      |> (if isHoverMenuNearRightEdge model 300 then onLeft else onRight)
      |> List.singleton


entityActionButton chunkPopup entityPopup (title, clickAction) =
  let
      hoverAction =
        popupOnMouseEnter <| ChunkOnBar { chunkPopup | entityPopup = Just { entityPopup | hoveringAction = Just title } }

      background =
        if entityPopup.hoveringAction == Just title then
          [ superLightBackground, width fill ]
        else
          []

      attrs =
        hoverAction :: ([ width fill, padding 10 ] ++ background)
  in
      actionButtonWithoutIconNoBobble attrs title clickAction


viewDefinition : Model -> EntityId -> Element Msg
viewDefinition model entityId =
  let
      unavailable =
        "✗ Definition unavailable" |> bodyWrap [ padding 10 ]
  in
      case model.entityDefinitions |> Dict.get entityId of
        Nothing -> -- shouldn't happen
          unavailable

        Just definition ->
          case definition of
            DefinitionScheduledForLoading ->
              viewLoadingSpinner

            DefinitionLoaded text ->
              if text=="" then
                unavailable
              else
                "“" ++ text ++ "” (Wikipedia)" |> bodyWrap [ Font.italic, padding 10, width <| px 200 ]


fragmentsBarHeight = 16


isHoverMenuNearRightEdge model margin =
  model.mousePositionXwhenOnChunkTrigger > (toFloat model.windowWidth)-margin


