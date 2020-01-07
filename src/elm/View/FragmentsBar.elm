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
import View.Utility exposing (..)
import Msg exposing (..)
import Animation exposing (..)


{-| Render the FragmentsBar, with or without ContentFlow enabled.
    Note that the FragmentsBar can appear on an OER card or in other places, such as the inspector modal.
    The behavior varies slightly. At the time of writing:
    A) on a card:
      - hover triggers the ChunkPopup AND causes scrubbing in the card's thumbnail
      - click opens the inspector modal
    B) otherwise:
      - hover triggers the ChunkPopup
      - click jumps to the position in the video (if applicable)
    NB The behaviour may further vary depending on:
    - the type of resource (video or otherwise)
    - whether ContentFlow is enabled or disabled
    - the return value of isLabStudy1
-}
viewFragmentsBar : Model -> Oer -> List Chunk -> Int -> String -> Element Msg
viewFragmentsBar model oer chunks barWidth barId =
  let
      visitedRangeMarkers =
        case model.videoUsages |> Dict.get oer.id of
          Nothing ->
            [] -- impossible

          Just ranges ->
            ranges
            |> List.map (\{start,length} -> none |> el [ width (length |> pxFromSeconds |> round |> max 4 |> px), height <| px 3, Background.color red, moveRight <| pxFromSeconds <| min start (oer.durationInSeconds-length), pointerEventsNone ] |> inFront)

      courseRangeMarkers =
        let
            maybeRangeFromDragging =
              case model.timelineHoverState of
                Nothing ->
                  Nothing
                Just timelineHoverState ->
                  if isHovering model oer || isInspecting model oer then
                    case timelineHoverState.mouseDownPosition of
                      Nothing ->
                        Nothing
                      Just dragStartPos ->
                        Just (Range dragStartPos (timelineHoverState.position - dragStartPos) |> multiplyRange oer.durationInSeconds)
                  else
                    Nothing

            maybeRangeFromCourse =
              case model.course.items |> List.filter (\item -> item.oerId==oer.id) |> List.head of
                Nothing ->
                  Nothing
                Just item ->
                  Just <| item.range

            ranges =
              case maybeRangeFromDragging of
                Just range ->
                  [ range ]
                Nothing ->
                  case maybeRangeFromCourse of
                    Just range ->
                      [ range ]
                    Nothing ->
                      []
            drawRange range =
              let
                  {start,length} =
                    range
                    |> invertRangeIfNeeded
              in
                  none
                  |> el [ width (length |> pxFromSeconds |> round |> max 4 |> px), height <| px 7, Background.color blue, Border.rounded 7, moveRight <| pxFromSeconds <| start, moveDown 4, pointerEventsNone ]
                  |> inFront
        in
            ranges
            |> List.map drawRange

      pxFromSeconds seconds =
        (barWidth |> toFloat) * seconds / oer.durationInSeconds

      -- A chunkTrigger is a transparent rectangle that triggers a ChunkPopup on mouseover.
      -- NB the mouse event handling on this one is fairly complex. It happens on the JavaScript side in port.js
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
                            none
                            |> el [ width fill, height fill, Background.color yellow, alpha <| 0.85 - (toFloat index)/4, pointerEventsNone ]
                            |> inFront
                            |> List.singleton
                in
                  ([ leftBorder ] ++ queryHighlight ++ bg)

            popup =
              if isPopupOpen then
                 [ viewChunkPopup model chunkPopup |> inFront ]
              else
                []

            chunkWidth =
              floor <| chunk.length * (toFloat barWidth) + (if chunkIndex == (List.length chunks)-1 then 0 else 1)
        in
            none
            |> el ([ htmlClass "ChunkTrigger", width <| px <| chunkWidth, height fill, moveRight <| chunk.start * (toFloat barWidth), popupOnMouseEnter (ChunkOnBar chunkPopup), closePopupOnMouseLeave ] ++ appearance ++ popup)
            |> inFront

      chunkTriggers =
        if isContentFlowEnabled model then
          chunks
          |> List.indexedMap chunkTrigger
        else
          []

      border =
        [ none |> el [ width fill , Background.color veryTransparentWhite, height <| px 1 ] |> above ]

      background =
        [ Background.color materialDark ]

      -- Here is where we define the effects of hover and click, depending on whether the bar is on a card or not
      scrubDisplayAndClickHandler =
        if isHovering model oer || isInspecting model oer then
          case model.timelineHoverState of
            Nothing ->
              []

            Just {position} ->
              let
                  scrubDisplay =
                    let
                        cursor =
                          none
                          |> el [ width <| px 2, height fill, Background.color white, moveRight ((barWidth - 2 |> toFloat) * position), pointerEventsNone ]
                          |> inFront

                        seconds =
                          position * oer.durationInSeconds
                          |> round

                        timeDisplay =
                          (seconds // 60 |> String.fromInt) ++":"++ (seconds |> modBy 60 |> String.fromInt |> String.pad 2 '0')
                          |> bodyNoWrap [ whiteText, moveRight ((barWidth - 20 |> toFloat) * position), moveUp 20, pointerEventsNone ]
                          |> inFront
                    in
                        [ cursor, timeDisplay ]

                  clickHandler =
                    if isHovering model oer then
                      onClickStopPropagation <| InspectOer oer position True
                    else
                      onClickStopPropagation <| StartCurrentHtml5Video (position * oer.durationInSeconds)
              in
                  scrubDisplay ++ [ clickHandler ]
        else
          []

      mouseLeaveHandler =
        [ onMouseLeave <| TimelineMouseLeave ]
  in
      none
      |> el ([ htmlClass "FragmentsBar", width fill, height <| px <| fragmentsBarHeight, moveUp fragmentsBarHeight ] ++ chunkTriggers ++ border ++ background ++ visitedRangeMarkers ++ courseRangeMarkers ++ scrubDisplayAndClickHandler ++ mouseLeaveHandler)


{-| Render the ChunkPopup as a (cascading) dropdown menu
-}
viewChunkPopup : Model -> ChunkPopup -> Element Msg
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


{-| Render a particular entity as a button in the dropdown menu
-}
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


{-| Render the submenu that contains the Entity's wikipedia definition (and potentially further action buttons)
-}
viewEntityPopup : Model -> ChunkPopup -> EntityPopup -> Entity -> List (Attribute Msg)
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


{-| Render a button that triggers an action associated with an entity (e.g. Search)
-}
entityActionButton : ChunkPopup -> EntityPopup -> (EntityTitle, Msg) -> Element Msg
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
      actionButtonWithoutIconStopPropagation attrs title clickAction


{-| Render an Entity's definition if available, or a placeholder otherwise
-}
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


{-| Height of the FragmentsBar in pixels
-}
fragmentsBarHeight = 16


{-| Check whether we are close to the right screen edge
    (In this case, the submenu should open on the LEFT to avoid exceeding the screen edge
-}
isHoverMenuNearRightEdge : Model -> Float -> Bool
isHoverMenuNearRightEdge model margin =
  model.mousePositionXwhenOnChunkTrigger > (toFloat model.windowWidth)-margin
