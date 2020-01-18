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
explainify : Model -> String -> Element Msg -> Element Msg
explainify {isExplainerEnabled} blurb element =
  if not isExplainerEnabled then
    element
  else
    let
        wrapperAttrs =
          [ overlay ]
    in
        element
        |> el wrapperAttrs


overlay : Attribute Msg
overlay =
  let
      infoButton =
        simpleButton [ Background.color magenta, whiteText, alignRight, Font.size 12, paddingXY 5 4, moveUp 3, moveRight 3 ] "explain" Nothing

      content =
        infoButton

  in
      content
      |> el [ width fill, height fill, Border.width 3, Border.color magenta, htmlClass "ZIndex100" ]
      |> inFront
