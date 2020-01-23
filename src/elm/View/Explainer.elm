module View.Explainer exposing (explainify)

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)

import Model exposing (..)
import View.Utility exposing (..)

import Msg exposing (..)


{-| Decorate an Element with an info button if isExplainerEnabled.
    This is achieved by wrapping the element in a transparent container
    which adds highlighting and additional functionality (button and popup).
-}
explainify : Model -> Explanation -> Element Msg -> Element Msg
explainify ({isExplainerEnabled} as model) explanation element =
  if not isExplainerEnabled then
    element
  else
    let
        wrapperAttrs =
          [ viewExplainerOverlayBorder
          , viewExplainerButton model explanation ]
    in
        element
        |> el wrapperAttrs


viewExplainerOverlayBorder : Attribute Msg
viewExplainerOverlayBorder =
  none
  |> el [ width fill, height fill, Border.width 3, Border.color magenta, htmlClass "ZIndex100", pointerEventsNone ]
  |> inFront


viewExplainerButton : Model -> Explanation -> Attribute Msg
viewExplainerButton {popup} {flyoutDirection, componentId, links} =
  let
      buttonAttrs =
        [ Background.color magenta, whiteText, alignRight, Font.size 12, paddingXY 5 4, htmlClass "ZIndex100 ClosePopupOnClickOutside" ] ++ explanationPopup

      explanationPopup =
        if popup == Just (ExplanationPopup componentId) then
          [ viewExplanationPopup flyoutDirection links ]
        else
          []
  in
      simpleButton buttonAttrs "explain" (Just <| OpenExplanationPopup componentId)
      |> inFront


viewExplanationPopup : FlyoutDirection -> List WebLink -> Attribute Msg
viewExplanationPopup flyoutDirection links =
  let
      introText =
        -- "This part of the interface uses the following AI components:"
        -- "The following AI components are used here"
        "AI components in use here:"

      weblinks =
        links
        |> List.map (\{label, url} -> label |> bodyNoWrap [ Font.color linkBlue ] |> newTabLinkTo [] url)
        |> column [ spacing 10 ]

      content =
        [ introText |> bodyWrap []
        , weblinks
        ]
        |> column [ spacing 15 ]
  in
      content
      |> el [ Background.color white, centerX, padding 16, dialogShadow, width <| px 208, moveRight (if flyoutDirection==Right then 80 else -80) ]
      |> below
