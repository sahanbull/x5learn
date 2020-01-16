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
import View.Utility exposing (..)
import View.ContentFlowBar exposing (..)

import Msg exposing (..)


{-| This module is responsible for rendering a bubblogram.
    It exposes only a single function: viewBubblogram.
    The other functions are local helpers.
-}
viewBubblogram : Model -> BubblogramType -> OerId -> Bubblogram -> (Element Msg, List (Element.Attribute Msg))
viewBubblogram model bubblogramType oerId {createdAt, bubbles} =
  let
      animationPhase =
        bubblogramAnimationPhase model createdAt

      labelPhase =
        animationPhase * 2 - 1 |> Basics.min 1 |> Basics.max 0

      svgBubbles =
        bubbles
        |> List.concatMap (viewSvgBubbleIncludingMentions model bubblogramType oerId animationPhase)

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
              case bubblogramType of
                TopicNames ->
                  { px = 9, py = bubblePosYfromIndex bubble + 8 }

                TopicConnections ->
                  let
                      {posX, posY, size} =
                        animatedBubbleCurrentCoordinates animationPhase bubble
                  in
                      { px = (posX + 0*size*1.1*bubbleZoom) * (toFloat contentWidth) + marginX, py = (posY + 0.1 -  0*size*1.1*bubbleZoom) * (toFloat contentHeight) + marginTop - 15 }

                TopicMentions ->
                  { px = 9, py = bubblePosYfromIndex bubble + 3 }

            isHovering =
              isHoveringOverEntity model entity

            highlight =
              if isHovering then
                [ Font.underline ]
              else
                [ Element.alpha 0.8 ]

            labelClickHandler =
              [ onClickStopPropagation (OverviewTagLabelClicked oerId) ]

            textAttrs =
              case bubblogramType of
                TopicNames ->
                  ([ Font.size <| 17 - bubble.index ] ++ (if isEntityEqualToSearchTerm model entity.id then [ Font.bold, Font.color yellow ] else []))

                _ ->
                  []
        in
            entity.title
            |> captionNowrap ([ whiteText, moveRight px, moveDown py, Events.onMouseEnter <| OverviewTagLabelMouseOver entity.id oerId, htmlClass hoverableClass ] ++ highlight ++ labelClickHandler ++ textAttrs)
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
                  viewPopup model bubblogramType state bubble
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
                [ onClickStopPropagation <| InspectOer oer fragmentStart True ]

      graphic =
        [ background ] ++ svgBubbles
        |> svg [ width widthString, height heightString, viewBox <| "0 0 " ++ ([ widthString, heightString ] |> String.join " ") ]
        |> html
        |> el (clickHandler ++ entityLabels)
  in
      (graphic, popup)


{-| Render a single bubble as SVG.
    When applicable, also render the mentions as interactive dots.
-}
viewSvgBubbleIncludingMentions : Model -> BubblogramType -> OerId -> Float -> Bubble -> List (Svg Msg)
viewSvgBubbleIncludingMentions model bubblogramType oerId animationPhase ({entity, index} as bubble) =
  let
      {posX, posY, size} =
        animatedBubbleCurrentCoordinates animationPhase bubble

      isHovering =
        isHoveringOverEntity model entity

      outline =
        case bubblogramType of
          TopicNames ->
            if isHovering then
              [ fill "rgba(255,255,255,0.1)" ]
            else
              [ fill "rgba(255,255,255,0)" ]

          TopicConnections ->
            if isHovering then
              [ fill "#f93" ]
            else
              []

          TopicMentions ->
            if isHovering then
              [ fill "rgba(255,255,255,0.1)" ]
            else
              [ fill "rgba(255,255,255,0)" ]

      isSearchTerm =
        isEntityEqualToSearchTerm model entity.id

      mentionDots =
        if bubblogramType==TopicNames then
          []
        else if isHovering || bubblogramType==TopicMentions then
          viewMentionDots model bubblogramType oerId entity.id bubble isHovering isSearchTerm
        else
          []

      body =
        case bubblogramType of
          TopicNames ->
            rect
              ([ x "0"
              , y (bubblePosYfromIndex bubble |> floor |> String.fromInt)
              , width (containerWidth |> String.fromInt)
              , height (containerHeight // 5 |> String.fromInt)
              , onMouseOver <| OverviewTagMouseOver entity.id oerId
              , onMouseLeave <| OverviewTagMouseOut
              , class <| hoverableClass ++ " StoryTag"
              ] ++ outline)
              []

          TopicConnections ->
            circle
              ([ cx (posX * (toFloat contentWidth) + marginX |> String.fromFloat)
              , cy (posY * (toFloat contentHeight) + marginTop |> String.fromFloat)
              , r (size * (toFloat contentWidth) * bubbleZoom|> String.fromFloat)
              , fill <| Color.toCssString <| if isSearchTerm then (Color.hsla 0.145 0.9 0.5 0.8) else colorFromBubble bubble
              ] ++ outline)
              []

          TopicMentions ->
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


{-| Get a bubble's color
-}
colorFromBubble : Bubble -> Color.Color
colorFromBubble {hue, alpha, saturation} =
  Color.hsla hue saturation 0.5 alpha


{-| Check whether the mouse is hovering over a particular entity
-}
isHoveringOverEntity : Model -> Entity -> Bool
isHoveringOverEntity model entity =
  case model.hoveringTagEntityId of
    Just entityId ->
      entityId == entity.id

    Nothing ->
      case model.popup of
        Just (ChunkOnBar chunkPopup) ->
          case chunkPopup.entityPopup of
            Nothing ->
              False

            Just entityPopup ->
              entityPopup.entityId == entity.id

        _ ->
          False


{-| Render the popup
-}
viewPopup : Model -> BubblogramType -> BubblePopupState -> Bubble -> List (Element.Attribute Msg)
viewPopup model bubblogramType {oerId, entityId, content} bubble =
  let
      {posX, posY, size} =
        animatedBubbleCurrentCoordinates 1 bubble

      -- Scale the zoom factor, depending on bubblogramType and text length
      zoomFromText text =
        case bubblogramType of
          TopicNames ->
            (String.length text |> toFloat) / 200 - ((toFloat bubble.index)*0.05) |> Basics.min 1

          TopicConnections ->
            (String.length text |> toFloat) / 200 - posY*0.5 |> Basics.min 1

          TopicMentions ->
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
            in
                element

          MentionInBubblePopup {sentence} ->
            (sentence |> bodyWrap [], zoomFromText sentence)

      -- render the main part of the popup as a box with rounded corners
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

      -- render the pointy-triangle part of the popup that makes it look like a speech bubble, pointing to the current mention
      tail =
        case content of
          MentionInBubblePopup {positionInResource} ->
            let
                sizeY : Float
                sizeY =
                  case bubblogramType of
                    TopicNames ->
                      35

                    TopicConnections ->
                      (toFloat containerHeight) - verticalOffset

                    TopicMentions ->
                      35

                tailHeightString =
                  sizeY
                  |> String.fromFloat

                tipX : Float
                tipX =
                  positionInResource * (toFloat containerWidth)

                rootX =
                  tipX * 3 / 4 + ((toFloat containerWidth)/8)
                  |> Basics.min (popupWidth-rootMargin-rootWidth - 30)
                  |> Basics.min ((toFloat containerWidth) - rootMargin - 35)
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

      -- calculate horizontal position and width of the popup
      (horizontalOffset, popupWidth) =
        let
            allowedMargin =
              horizontalSpacingBetweenCards - 5

            smallest : { horizontalOffset : Float, popupWidth : Float }
            smallest =
              { horizontalOffset = (posX/2 + 1/4) * (toFloat contentWidth) + marginX - 300/2, popupWidth = 300 }

            largest : { horizontalOffset : Float, popupWidth : Float }
            largest =
              { horizontalOffset = -allowedMargin |> toFloat, popupWidth = cardWidth + 2*allowedMargin |> toFloat }
        in
            (interp zoom smallest.horizontalOffset largest.horizontalOffset
            , interp zoom smallest.popupWidth largest.popupWidth)

      -- calculate vertical position
      verticalOffset =
        case bubblogramType of
          TopicNames ->
            bubblePosYfromIndex bubble

          TopicConnections ->
            Basics.max 10 <| (posY - size*3.5*bubbleZoom) * (toFloat contentHeight) + marginTop - 5

          TopicMentions ->
            bubblePosYfromIndex bubble
  in
      none
      |> el ([ above box, moveRight <| horizontalOffset, moveDown <| verticalOffset ]++tail)
      |> inFront
      |> List.singleton


{-| Outer width of the bubblogram
-}
containerWidth =
  cardWidth


{-| Outer height of the bubblogram
-}
containerHeight =
  imageHeight - contentFlowBarHeight


{-| Inner width of the bubblogram
-}
contentWidth =
  cardWidth - 2*marginX


{-| Inner height of the bubblogram
-}
contentHeight =
  imageHeight - 2*marginX - contentFlowBarHeight - 10


{-| Space between the upper edge and content
-}
marginTop =
  marginX + 10


{-| Space between the left and right edges and the content
-}
marginX =
  25


{-| The width as a String
    (SVG uses string parameters)
-}
widthString : String
widthString =
  containerWidth |> String.fromInt


{-| The height as a String
    (SVG uses string parameters)
-}
heightString : String
heightString =
  containerHeight |> String.fromInt


{-| Current coordinates of a particular bubble, taking animation into account
-}
animatedBubbleCurrentCoordinates : Float -> Bubble -> BubbleCoordinates
animatedBubbleCurrentCoordinates phase {initialCoordinates, finalCoordinates} =
  { posX = interp phase initialCoordinates.posX finalCoordinates.posX
  , posY = interp phase initialCoordinates.posY finalCoordinates.posY
  , size = interp phase initialCoordinates.size finalCoordinates.size
  }


{-| CSS class to control mouseover behaviour
-}
hoverableClass =
  "UserSelectNone CursorPointer"


{-| Render the mentions as interactive dots
-}
viewMentionDots : Model -> BubblogramType -> OerId -> EntityId -> Bubble -> Bool -> Bool -> List (Svg Msg)
viewMentionDots model bubblogramType oerId entityId bubble isHoveringOnCurrentTag isSearchTerm =
  let
      circlePosY =
        String.fromFloat <|
          case bubblogramType of
            TopicNames ->
              (bubblePosYfromIndex bubble) + 23

            TopicConnections ->
              containerHeight - 8 |> toFloat

            TopicMentions ->
              (bubblePosYfromIndex bubble) + 23

      dot : MentionInOer -> Svg Msg
      dot ({positionInResource, sentence} as mention) =
        let
            circlePosX =
              positionInResource * (toFloat containerWidth)
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

            hoverHandler =
              case bubblogramType of
                TopicNames ->
                  []

                TopicConnections ->
                  [ onMouseOver <| MouseEnterMentionInBubbblogramOverview oerId entityId mention ]

                TopicMentions ->
                  []
        in
            circle ([ cx circlePosX, cy circlePosY, r circleRadius, fill color ]++hoverHandler) []

      mentions =
        getMentions model oerId bubble.entity.id
  in
      mentions
      |> List.map dot


{-| Convert corners to SVG points
-}
svgPointsFromCorners : List (Float, Float) -> String
svgPointsFromCorners corners =
  corners
  |> List.map (\(x,y) -> (x |> String.fromFloat)++","++(y |> String.fromFloat))
  |> String.join " "


{-| mouseleave handler
-}
onMouseLeave : msg -> Attribute msg
onMouseLeave msg =
  Html.Events.on "mouseleave" (Decode.succeed msg)


{-| Calculate vertical bubble position from its index
-}
bubblePosYfromIndex : Bubble -> Float
bubblePosYfromIndex bubble =
  bubble.index * containerHeight // 5
  |> toFloat


{-| Check whether a particular entity is what the user searched for.
    Used to control yellow highlighting
-}
isEntityEqualToSearchTerm : Model -> EntityId -> Bool
isEntityEqualToSearchTerm model entityId =
  case getEntityTitleFromEntityId model entityId of
    Nothing ->
      False

    Just title ->
      isEqualToSearchString model title
