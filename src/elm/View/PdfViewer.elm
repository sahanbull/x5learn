module View.PdfViewer exposing (viewPdfViewer)

import Html
import Html.Attributes as Attributes

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font

import View.Utility exposing (..)
import Msg exposing (Msg)
import Model exposing (..)


{-| Render a simple embedded pdf viewer
-}
viewPdfViewer : OerUrl -> String -> Element Msg
viewPdfViewer oerUrl height =
  let
      fallbackContent =
        Html.a [ Attributes.href oerUrl ] [ Html.text oerUrl ]

      styles =
        [ Attributes.style "width" "100%"
        , Attributes.style "height" height
        ]
  in
      [ fallbackContent ]
      |> Html.object ([ Attributes.attribute "data" oerUrl, Attributes.type_ "application/pdf" ] ++ styles)
      |> html
