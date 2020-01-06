module View.Html5VideoPlayer exposing (viewHtml5VideoPlayer)

import Html
import Html.Attributes as Attributes

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font

import View.Utility exposing (..)
import Msg exposing (Msg)
import Model exposing (..)


{-| Render a standard HTML5 video player element
    https://www.w3schools.com/html/html5_video.asp
    https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video
-}
viewHtml5VideoPlayer : Model -> OerUrl -> Element Msg
viewHtml5VideoPlayer model oerUrl =
  let
      fallbackMessage =
        [ [ "Your browser does not support HTML5 video." |> Html.text ] |> Html.div []
        ]
        |> Html.div [ Attributes.class "Html5VideoPlayerMessage" ]
  in
        [ Html.source [ Attributes.src oerUrl ] []
        , fallbackMessage
        ]
        |> Html.video [ Attributes.id "Html5VideoPlayer", Attributes.controls True, Attributes.height (max 200 (model.windowHeight - 450)) ]
        |> Element.html
        |> el [ width <| px 720 ]
