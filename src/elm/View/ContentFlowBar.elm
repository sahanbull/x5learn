module View.ContentFlowBar exposing (..)

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


{-| Render the ContentFlowBar, with or without ContentFlow enabled.
    Note that the ContentFlowBar can appear on an OER card or in other places, such as the inspector.
    The behavior varies slightly. At the time of writing:
    A) on a card:
      - hover triggers the ChunkPopup AND causes scrubbing in the card's thumbnail
      - click opens the inspector
    B) otherwise:
      - hover triggers the ChunkPopup
      - click jumps to the position in the video (if applicable)
    NB The behaviour may further vary depending on:
    - the type of resource (video or otherwise)
    - whether ContentFlow is enabled or disabled
    - the return value of isLabStudy1
-}
viewContentFlowBar : Model -> Oer -> List Chunk -> Int -> String -> Element Msg
viewContentFlowBar model oer chunks barWidth barId =
  let
      visitedRangeMarkers =
        case model.videoUsages |> Dict.get oer.id of
          Nothing ->
            [] -- impossible

          Just ranges ->
            ranges
            |> List.map (\{start,length} -> none |> el [ width (length |> pxFromSeconds |> round |> max 4 |> px), height <| px 3, Background.color red, moveRight <| pxFromSeconds <| min start (oer.durationInSeconds-length), pointerEventsNone ] |> inFront)

      isOnCard =
        isHovering model oer

      courseRangeMarkers =
        let
            rangeFromDragging : List Range
            rangeFromDragging =
              case model.timelineHoverState of
                Nothing ->
                  []

                Just timelineHoverState ->
                  if isOnCard || isInspecting model oer then
                    case timelineHoverState.mouseDownPosition of
                      Nothing ->
                        []

                      Just dragStartPos ->
                        Range dragStartPos (timelineHoverState.position - dragStartPos)
                        |> multiplyRange oer.durationInSeconds
                        |> List.singleton
                  else
                    []

            rangesFromCourse : List Range
            rangesFromCourse =
              case model.course.items |> List.filter (\item -> item.oerId==oer.id) |> List.head of
                Nothing ->
                  []

                Just item ->
                  item.ranges

            drawRange range =
              let
                  {start,length} =
                    range
                    |> invertRangeIfNeeded
              in
                  none
                  |> el [ width (length |> pxFromSeconds |> round |> max 4 |> px), height <| px 7, Background.color electricBlue, Border.rounded 7, moveRight <| pxFromSeconds <| start, moveDown 4, pointerEventsNone ]
                  |> inFront
        in
            rangesFromCourse ++ rangeFromDragging
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
                      Just (ContentFlowPopup p) ->
                        p.entityPopup

                      _ ->
                        Nothing
              in
                  { barId = barId, oer = oer, chunk = chunk, entityPopup = entityPopup }

            isPopupOpen =
              case model.popup of
                Just (ContentFlowPopup p) ->
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
                    |> el [ width <| px 1, height <| px contentFlowBarHeight, Background.color veryTransparentWhite ]
                    |> inFront

                  queryHighlight =
                    case model.searchState of
                      Nothing ->
                        []

                      Just {lastSearchText} ->
                        case indexOf (String.toLower lastSearchText) (chunk.entities |> List.map (\{title} -> String.toLower title)) of
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
            |> el ([ htmlClass "ChunkTrigger", width <| px <| chunkWidth, height fill, moveRight <| chunk.start * (toFloat barWidth), popupOnMouseEnter (ContentFlowPopup chunkPopup), closePopupOnMouseLeave ] ++ appearance ++ popup)
            |> inFront

      chunkTriggers =
        case model.timelineHoverState of
          Nothing ->
            []

          Just {mouseDownPosition} ->
            case mouseDownPosition of
              Nothing -> -- mouse is not down, so the user is just hovering
                if isContentFlowEnabled model then
                  chunks
                  |> List.indexedMap chunkTrigger
                else
                  []

              Just _ -> -- mouse is down, so the user is either dragging a range or clicking. Either way, we want to hide contentflow in this case to avoid conflicting mouse events with the range menu.
                []

      border =
        [ none |> el [ width fill , Background.color veryTransparentWhite, height <| px 1 ] |> above ]

      background =
        [ Background.color midnightBlue ]

      -- Here is where we define the effects of hover and click, depending on whether the bar is on a card or not
      scrubDisplayAndClickHandler =
        if isOnCard || isInspecting model oer then
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
                    onClickStopPropagation <| ClickedOnContentFlowBar oer position isOnCard
              in
                  scrubDisplay ++ [ clickHandler ]
        else
          []

      mouseLeaveHandler =
        [ onMouseLeave TimelineMouseLeave ]

      postClickFlyout : List (Attribute Msg)
      postClickFlyout =
        if model.inspectorState==Nothing || barId==barIdInInspector then
          viewPostClickFlyoutPopup model oer barWidth
        else
          []
  in
      none
      |> el ([ htmlClass "ContentFlowBar", width fill, height <| px <| contentFlowBarHeight, moveUp contentFlowBarHeight ] ++ chunkTriggers ++ border ++ background ++ visitedRangeMarkers ++ courseRangeMarkers ++ scrubDisplayAndClickHandler ++ mouseLeaveHandler ++ postClickFlyout)


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
      |> el [ moveLeft 30, moveDown contentFlowBarHeight ]


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
        button ([ padding 5, width fill, popupOnMouseEnter (ContentFlowPopup { chunkPopup | entityPopup = Just { entityId = entity.id, hoveringAction = Nothing } }) ] ++ backgroundAndSubmenu) { onPress = Nothing, label = label }


{-| Render the submenu that contains the Entity's wikipedia definition (and potentially further action buttons)
-}
viewEntityPopup : Model -> ChunkPopup -> EntityPopup -> Entity -> List (Attribute Msg)
viewEntityPopup model chunkPopup entityPopup entity =
  let
      actionButtons =
        if isLabStudy1 model then
          []
        else
          [ ("Search", TriggerSearch entity.title False)
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
        popupOnMouseEnter <| ContentFlowPopup { chunkPopup | entityPopup = Just { entityPopup | hoveringAction = Just title } }

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


{-| Height of the ContentFlowBar in pixels
-}
contentFlowBarHeight = 16


{-| Check whether we are close to the right screen edge
    (In this case, the submenu should open on the LEFT to avoid exceeding the screen edge
-}
isHoverMenuNearRightEdge : Model -> Float -> Bool
isHoverMenuNearRightEdge model margin =
  model.mousePositionXwhenOnChunkTrigger > (toFloat model.windowWidth)-margin


{-| Render the flyout that appears when the user clicked on the ContentFlowBar
-}
viewPostClickFlyoutPopup : Model -> Oer -> Int -> List (Attribute Msg)
viewPostClickFlyoutPopup model oer barWidth =
  case model.popup of
    Just (PopupAfterClickedOnContentFlowBar popupOer position isCard maybeRange) ->
      let
          buttonAttrs =
            [ bigButtonPadding ]

          playButton =
            if isVideoFile oer.url then
              if isCard then
                [ actionButtonWithoutIconStopPropagation buttonAttrs "▶ Play from here" (InspectOer oer position True "InspectOer PopupAfterClickedOnContentFlowBar Play from here")
                ]
              else
                [ actionButtonWithoutIconStopPropagation buttonAttrs "▶ Play from here" (StartCurrentHtml5Video (position * oer.durationInSeconds))
                ]
            else
              []

          rangeDeleteButton =
            case maybeRange of
              Nothing ->
                []

              Just range ->
                [ actionButtonWithoutIconStopPropagation buttonAttrs "❌ Remove Range" (PressedRemoveRangeButton oer.id range)
                ]

          cancelButton =
            [ actionButtonWithoutIconStopPropagation buttonAttrs "Cancel" ClosePopup
            ]

          buttons =
            playButton ++ rangeDeleteButton ++ cancelButton
      in
          if popupOer.id==oer.id then
            buttons
            |> menuColumn [ moveRight ((barWidth |> toFloat) * position - 15), moveUp 34 ]
            |> inFront
            |> List.singleton
          else
            []

    _ ->
      []
