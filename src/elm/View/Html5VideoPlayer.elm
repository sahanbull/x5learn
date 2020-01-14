module View.Html5VideoPlayer exposing (viewHtml5VideoPlayer)

import Dict
import Url
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
viewHtml5VideoPlayer : Model -> Oer -> Element Msg
viewHtml5VideoPlayer model oer =
  let
      fallbackMessage =
        [ [ "Your browser does not support HTML5 video." |> Html.text ] |> Html.div []
        ]
        |> Html.div [ Attributes.class "Html5VideoPlayerMessage" ]

      subtitleTracks =
        oer.translations
        |> Dict.toList
        |> List.map subtitleTrack

      attrs =
        [ Attributes.id "Html5VideoPlayer"
        , Attributes.controls True
        ]

      children =
        [ Html.source [ Attributes.src oer.url ] []
        , fallbackMessage
        ] ++ subtitleTracks
  in
      children
      |> Html.video attrs
      |> Element.html
      |> el [ width <| px 720 ]


{-| Create an HTML tag like
-- <track src="subtitles_en.vtt" kind="subtitles" srclang="en" label="English">
-- except that src contains the vtt data directly as a data URI
-- https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs
-}
subtitleTrack : (String, String) -> Html.Html Msg
subtitleTrack (language, text) =
  let
      attrs =
        [ Attributes.src <| "data:,"++(text |> Url.percentEncode)
        , Attributes.kind "subtitles"
        , Attributes.srclang language
        -- , Attributes.label language
        ]
  in
      Html.track attrs []
