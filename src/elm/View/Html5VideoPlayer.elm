module View.Html5VideoPlayer exposing (viewHtml5VideoPlayer)

import Html
import Html.Attributes as Attributes

import Element


viewHtml5VideoPlayer model oerUrl =
  let
      height =
        [ Attributes.height (max 200 (model.windowHeight - 450)) ]
  in
      Html.source [ Attributes.src oerUrl ] []
      |> List.singleton
      |> Html.video ([ Attributes.controls True ] ++ height)
      |> Element.html
