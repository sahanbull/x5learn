module View.Html5VideoPlayer exposing (viewHtml5VideoPlayer)

import Html
import Html.Attributes as Attributes

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font

import View.Shared exposing (..)


viewHtml5VideoPlayer model oerUrl =
  let

      fallbackMessage =
        [ [ "Your browser does not support HTML5 video." |> Html.text ] |> Html.div []
        -- , [ oerUrl |> Html.text ] |> Html.a [ Attributes.href oerUrl, Attributes.target "_blank" ] |> List.singleton |> Html.p []
        ]
        |> Html.div [ Attributes.class "Html5VideoPlayerMessage" ]
  in
        [ Html.source [ Attributes.src oerUrl ] []
        , fallbackMessage
        ]
        |> Html.video [ Attributes.controls True, Attributes.height (max 200 (model.windowHeight - 450)) ]
        |> Element.html
        |> el [ width <| px 720 ]
