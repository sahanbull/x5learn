module View.Modal exposing (viewModal)

import Set

import Html
import Html.Attributes as Attributes exposing (style)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Json.Decode

import Model exposing (..)
import Msg exposing (..)

import View.Utility exposing (..)

import Animation exposing (..)

viewModal : Model -> List (Attribute Msg)
viewModal model =
    [ inFront <| viewTheModal model ]


viewTheModal : Model -> Element Msg
viewTheModal model =
    let
        title = "Title unavailable" |> subheaderWrap [ Font.italic ]

        hideWhileOpening =
            alpha <| if model.animationsPending |> Set.member inspectorId then 0.01 else 1

        header =
            [ title
            , button [] { onPress = Nothing, label = closeIcon }
            ]
            |> row [ width fill, spacing 4 ]

        body = 
            [ text "Body Goes Here"]
            |> row []

        sheet =
            [ header
            , body
            ]
            |> column [ width (px <| 300), Background.color white, centerX, moveRight (navigationDrawerWidth/2),  centerY, padding 16, spacing 16, htmlId inspectorId, hideWhileOpening, dialogShadow ]

        animatingBox =
            case model.inspectorAnimation of
            Nothing ->
                none

            Just animation ->
                let
                    (box, opacity) =
                        if animation.frameCount > 1 then
                            (animation.end, 5/((toFloat animation.frameCount)+5))
                        else
                            (interpolateBoxes animation.start animation.end, 0)
                in
                    none
                    |> el [ whiteBackground, width (box.sx |> round |> px), height (box.sy |> round |> px), moveRight box.x, moveDown box.y, htmlClass "InspectorAnimation", alpha opacity, Border.rounded 5 ]

        scrim =
            let
                opacity =
                    case inspectorAnimationStatus model of
                        Inactive ->
                            materialScrimAlpha

                        Prestart ->
                            0

                        Started ->
                            materialScrimAlpha
            in
                none
                |> el [ Background.color <| rgba 0 0 0 opacity, width (model.windowWidth - navigationDrawerWidth |> px), height (fill |> maximum (model.windowHeight - pageHeaderHeight)), moveDown (toFloat pageHeaderHeight), moveRight navigationDrawerWidth,  htmlClass "InspectorScrim" ]
    in
        sheet
        |> el [ width fill, height fill, behindContent scrim, inFront animatingBox ]