module View.Pages.Material exposing (viewMaterialPage)

import Url
import Dict
import Set
import List.Extra

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewMaterialPage : Model -> UserState -> PageWithModal
viewMaterialPage model userState =
  let
      materialId =
        model.nav.url.path
        |> String.dropLeft 10 -- TODO A much cleaner method is to use Url.Query.parser
        -- |> Maybe.withDefault ""
        |> Debug.log "materialId"

      page =
        case materialId |> String.toInt of
          Nothing -> -- Flask will prevent this
            viewCenterNote "The requested material was not found on the server."

          Just id ->
            viewCenterNote "The requested material was not found on the server."
            -- id
            -- |> String.fromInt
            -- |> text
  in
      (page, [])
