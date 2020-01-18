module View.Explainer exposing (explainify)

-- import Dict
-- import Set
-- import Json.Decode as Decode

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)

import Model exposing (..)
import View.Utility exposing (..)

import Msg exposing (..)


{-| Decorate an Element with an info button if isExplainerEnabled
    This is achieved by wrapping the element in a transparent container
    which adds highlighting and additional functionality
-}
explainify : Model -> String -> String -> String -> Element Msg -> Element Msg
explainify ({isExplainerEnabled} as model) componentId blurb url element =
  if not isExplainerEnabled then
    element
  else
    let
        wrapperAttrs =
          [ overlay model componentId blurb url ]
    in
        element
        |> el wrapperAttrs


overlay : Model -> String -> String -> String -> Attribute Msg
overlay {popup} componentId blurb url =
  let
      infoButton =
        let
            buttonAttrs =
              [ Background.color magenta, whiteText, alignRight, Font.size 12, paddingXY 5 4, moveUp 3, moveRight 3, htmlClass "ClosePopupOnClickOutside" ] ++ explanationPopup
        in
            simpleButton buttonAttrs "explain" (Just <| OpenExplanationPopup componentId)

      explanationPopup =
        if popup == Just (ExplanationPopup componentId) then
          viewExplanationPopup blurb url
        else
          []

      content =
        infoButton
  in
      content
      |> el [ width fill, height fill, Border.width 3, Border.color magenta, htmlClass "ZIndex100" ]
      |> inFront


viewExplanationPopup : String -> String -> List (Attribute Msg)
viewExplanationPopup blurb url =
  let
      content =
        [ blurb |> bodyWrap []
        , "Learn more" |> bodyNoWrap [ Font.color linkBlue ] |> newTabLinkTo [] url
        ]
        |> column [ spacing 15 ]
  in
      content
      |> el [ Background.color white, centerX, padding 16, dialogShadow, width <| px 220 ]
      |> onRight
      |> List.singleton
