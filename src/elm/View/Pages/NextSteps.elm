module View.Pages.NextSteps exposing (viewNextStepsPage)

import Url
import Dict
import Set

import Html.Attributes

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import Animation exposing (..)
import View.Shared exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewNextStepsPage : Model -> PageWithModal
viewNextStepsPage model =
  let
      modal =
        []

      playlists =
        [ Playlist "Continue reading" [ bishopBook ]
        , Playlist "Videos similar to what you just read" []
        ]

      page =
        playlists
        |> List.map (viewPlaylist model)
        |> column [ width fill, height fill, spacing 20 ]
        |> el [ padding 50, width fill ]
  in
      (page, modal)


viewPlaylist model playlist =
  [ playlist.title |> headlineWrap []
  , if playlist.oers |> List.isEmpty then "No bookmarks" |> bodyNoWrap [centerX] else playlist.oers |> List.map (viewOerCard model) |> row [ spacing 20 ]
  ]
  |> column [ spacing 20, padding 20, width fill, Background.color transparentWhite, Border.rounded 2 ]
