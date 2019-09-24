module View.Bubblogram exposing (viewBubblogram)

import Dict exposing (Dict)
import Time exposing (Posix, millisToPosix, posixToMillis)
import Json.Decode as Decode

import List.Extra

import Html.Events

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onMouseOver, custom)

import Element exposing (Element, el, html, inFront, row, padding, spacing, px, moveDown, moveLeft, moveRight, above, below, none)
import Element.Font as Font
import Element.Background as Background
import Element.Events as Events
import Element.Border as Border

import Color -- avh4/elm-color

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)


viewBubblogram : Model -> OerId -> Bubblogram -> Element Msg
viewBubblogram model oerId {createdAt, bubbles} =
  let
      animationPhase =
        bubblogramAnimationPhase model createdAt

      labelPhase =
        animationPhase * 2 - 1 |> Basics.min 1 |> Basics.max 0

      svgBubbles =
        bubbles
        |> List.concatMap (viewTag model oerId animationPhase)

      background =
        rect [ width widthString, height heightString, fill "#191919" ] []

      findBubbleByEntityId : String -> Maybe Bubble
      findBubbleByEntityId entityId =
        bubbles |> List.filter (\bubble -> bubble.entity.id == entityId) |> List.reverse |> List.head

      entityLabels =
        if labelPhase <= 0 then
          []
        else
          bubbles
          |> List.concatMap entityLabel

      entityLabel ({entity} as bubble) =
        let
            {px, py} =
              { px = 9, py = bubblePosYfromIndex bubble + 3 }

            isHovering =
              hoveringBubbleOrFragmentsBarEntityId model == Just entity.id

            highlight =
              if isHovering then
                [ Font.underline ]
              else
                [ Element.alpha 0.8 ]

            labelClickHandler =
              [ onClickNoBubble (OverviewTagLabelClicked oerId) ]
        in
            entity.title
            |> captionNowrap ([ whiteText, moveRight px, moveDown py, Events.onMouseEnter <| OverviewTagLabelMouseOver entity.id oerId, htmlClass hoverableClass ] ++ highlight ++ labelClickHandler)
            |> inFront
            |> List.singleton

      popup =
        case model.popup of
          Just (BubblePopup state) ->
            if state.oerId==oerId then
              case findBubbleByEntityId state.entityId of
                Nothing -> -- shouldn't happen
                  []

                Just bubble ->
                  viewPopup model state bubble
            else
              []

          _ ->
            []

      clickHandler =
        case model.cachedOers |> Dict.get oerId of
          Nothing ->
            []

          Just oer ->
            let
                fragmentStart =
                  case model.selectedMentionInStory of
                    Nothing ->
                      0

                    Just (_, {positionInResource}) ->
                      positionInResource - 0.0007
            in
                [ onClickNoBubble <| InspectOer oer fragmentStart 0.01 True ]

  in
      [ background ] ++ svgBubbles
      |> svg [ width widthString, height heightString, viewBox <| "0 0 " ++ ([ widthString, heightString ] |> String.join " ") ]
      |> html
      |> el (clickHandler ++ entityLabels ++ popup)


viewTag : Model -> OerId -> Float -> Bubble -> List (Svg Msg)
viewTag model oerId animationPhase ({entity, index} as bubble) =
  let
      {posX, posY, size} =
        animatedBubbleCurrentCoordinates animationPhase bubble

      isHovering =
        hoveringBubbleOrFragmentsBarEntityId model == Just entity.id

      outline =
        if isHovering then
          [ fill "rgba(255,255,255,0.1)" ]
        else
          [ fill "rgba(255,255,255,0)" ]

      isSearchTerm =
        isEntityEqualToSearchTerm model entity.id

      mentionDots =
        if isHovering then
          viewMentionDots model oerId entity.id bubble isHovering isSearchTerm
        else
          []

      body =
        let
            strokeAttrs =
              if index==0 then
                []
              else
                [ stroke "#444"
                , strokeDasharray <| (cardWidth |> String.fromInt) ++ " 1000" -- only draw the top border of the rectangle
                ]
        in
            rect
              ([ x "0"
              , y (bubblePosYfromIndex bubble |> floor |> String.fromInt)
              , width (containerWidth |> String.fromInt)
              , height (containerHeight // 5 |> String.fromInt)
              , onMouseOver <| OverviewTagMouseOver entity.id oerId
              , onMouseLeave <| OverviewTagMouseOut
              , class <| hoverableClass ++ " StoryTag"
              ] ++ outline ++ strokeAttrs)
              []

  in
      mentionDots ++ [ body ]


colorFromBubble : Bubble -> Color.Color
colorFromBubble {hue, alpha, saturation} =
  Color.hsla hue saturation 0.5 alpha


hoveringBubbleOrFragmentsBarEntityId model =
  case model.hoveringTagEntityId of
    Just entityId ->
      Just entityId

    Nothing ->
      case model.popup of
        Just (ChunkOnBar chunkPopup) ->
          case chunkPopup.entityPopup of
            Nothing ->
              Nothing

            Just entityPopup ->
              Just entityPopup.entityId

        _ ->
          Nothing


viewPopup : Model -> BubblePopupState -> Bubble -> List (Element.Attribute Msg)
viewPopup model {oerId, entityId, content} bubble =
  let
      {posX, posY, size} =
        animatedBubbleCurrentCoordinates 1 bubble

      zoomFromText text =
        (String.length text |> toFloat) / 200 - ((toFloat bubble.index)*0.05) |> Basics.min 1

      (contentElement, zoom) =
        case content of
          DefinitionInBubblePopup ->
            let
                unavailable =
                  ("✗ Definition unavailable" |> bodyWrap [], 0)

                element =
                  case model.entityDefinitions |> Dict.get entityId of
                    Nothing -> -- shouldn't happen
                      unavailable

                    Just definition ->
                      case definition of
                        DefinitionScheduledForLoading ->
                          (viewLoadingSpinner, 0)

                        DefinitionLoaded text ->
                          if text=="" then
                            unavailable
                          else
                            ("“" ++ text ++ "” (Wikipedia)" |> bodyWrap [ Font.italic ], zoomFromText text)

                        -- DefinitionUnavailable ->
                        -- unavailable
            in
                element

          MentionInBubblePopup {sentence} ->
            (sentence |> bodyWrap [], zoomFromText sentence)

      box =
        let
            roundedBorder =
              case content of
                MentionInBubblePopup _ ->
                  [ Border.rounded 12 ]

                _ ->
                  []
        in
            contentElement
            |> List.singleton
            |> menuColumn ([ Element.width <| px <| round popupWidth, padding 10, pointerEventsNone, Element.clipY ] ++ roundedBorder)

      tail =
        case content of
          MentionInBubblePopup {positionInResource} ->
            let
                sizeY =
                  35

                tailHeightString =
                  sizeY
                  |> String.fromFloat

                tipX =
                  positionInResource * containerWidth

                rootX =
                  tipX * 3 / 4 + (containerWidth/8)
                  |> Basics.min (popupWidth-rootMargin-rootWidth - 30)
                  |> Basics.min (containerWidth - rootMargin - 35)
                  |> Basics.max 25

                rootWidth =
                  20

                rootMargin =
                  22

                corners =
                  [ (rootX + 0, 0)
                  , (rootX + rootWidth, 0)
                  , (tipX, sizeY-12)
                  ]
                  |> svgPointsFromCorners
            in
                [ polygon [ fill "white", points corners, class "PointerEventsNone" ] [] ]
                |> svg [ width widthString, height tailHeightString, viewBox <| "0 0 " ++ ([ widthString, tailHeightString ] |> String.join " ") ]
                |> html
                |> el [ moveDown <| sizeY-1, moveLeft horizontalOffset, pointerEventsNone ]
                |> above
                |> List.singleton

          _ ->
            []

      (horizontalOffset, popupWidth) =
        let
            allowedMargin =
              horizontalSpacingBetweenCards - 5

            smallest =
              { horizontalOffset = (posX/2 + 1/4) * contentWidth + marginX - 300/2, popupWidth = 300 }

            largest =
              { horizontalOffset = -allowedMargin, popupWidth = cardWidth + 2*allowedMargin }
        in
            (interp zoom smallest.horizontalOffset largest.horizontalOffset
            , interp zoom smallest.popupWidth largest.popupWidth)

      verticalOffset =
        bubblePosYfromIndex bubble
  in
      none
      |> el ([ above box, moveRight <| horizontalOffset, moveDown <| verticalOffset ]++tail)
      |> inFront
      |> List.singleton


containerWidth =
  cardWidth


containerHeight =
  imageHeight - fragmentsBarHeight


contentWidth =
  cardWidth - 2*marginX


contentHeight =
  imageHeight - 2*marginX - fragmentsBarHeight - 10


marginTop =
  marginX + 10


marginX =
  25


widthString =
  containerWidth |> String.fromInt

heightString =
  containerHeight |> String.fromInt


animatedBubbleCurrentCoordinates : Float -> Bubble -> BubbleCoordinates
animatedBubbleCurrentCoordinates phase {initialCoordinates, finalCoordinates} =
  { posX = interp phase initialCoordinates.posX finalCoordinates.posX
  , posY = interp phase initialCoordinates.posY finalCoordinates.posY
  , size = interp phase initialCoordinates.size finalCoordinates.size
  }


hoverableClass =
  "UserSelectNone CursorPointer"


viewMentionDots : Model -> OerId -> EntityId -> Bubble -> Bool -> Bool -> List (Svg Msg)
viewMentionDots model oerId entityId bubble isHoveringOnCurrentTag isSearchTerm =
  let
      circlePosY =
        String.fromFloat <|
          (bubblePosYfromIndex bubble) + 23

      dot : MentionInOer -> Svg Msg
      dot ({positionInResource, sentence} as mention) =
        let
            circlePosX =
              positionInResource * containerWidth
              |> String.fromFloat

            circleRadius =
              if isHoveringOnCurrentTag then
                "5"
              else
                "2.5"

            color =
              if isSearchTerm then
                "rgba(255,240,0,1)"
              else if isHoveringOnCurrentTag then
                "rgba(255,140,0,1)"
              else
                "rgba(255,140,0,0.4)"
        in
            circle [ cx circlePosX, cy circlePosY, r circleRadius, fill color ] []

      mentions =
        getMentions model oerId bubble.entity.id
  in
      mentions
      |> List.map dot


svgPointsFromCorners : List (Float, Float) -> String
svgPointsFromCorners corners =
  corners
  |> List.map (\(x,y) -> (x |> String.fromFloat)++","++(y |> String.fromFloat))
  |> String.join " "


onMouseLeave : msg -> Attribute msg
onMouseLeave msg =
  Html.Events.on "mouseleave" (Decode.succeed msg)


bubblePosYfromIndex : Bubble -> Float
bubblePosYfromIndex bubble =
  bubble.index * containerHeight // 5
  |> toFloat


isEntityEqualToSearchTerm model entityId =
  case getEntityTitleFromEntityId model entityId of
    Nothing ->
      False

    Just title ->
      isEqualToSearchString model title
