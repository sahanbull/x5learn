module View.Pages.Search exposing (viewSearchPage)

import Url
import Dict

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font

import Model exposing (..)
import View.Shared exposing (..)
import View.Inspector exposing (..)
import View.Card exposing (..)

import Msg exposing (..)

import Json.Decode as Decode


viewSearchPage : Model -> SearchState -> PageWithModal
viewSearchPage model searchState =
  let
      modal =
        viewInspectorModalOrEmpty model

      content =
        [ viewTopBar model searchState
        , viewBody model searchState
        ]
        |> column [ width fill, height fill ]
  in
      (content, modal)


viewBody model searchState =
  case searchState.searchResults of
    Nothing ->
      viewLoadingSpinner

    Just [] ->
      "No results were found for \"" ++ searchState.lastSearch ++ "\". Please try a different search term." |> viewCenterNote

    Just oerIds ->
      Playlist "" oerIds
      |> viewOerGrid model
      |> el [ width fill, height fill, paddingTRBL 0 0 100 0 ]


viewTopBar : Model -> SearchState -> Element Msg
viewTopBar model searchState =
  let
      collectionTitle =
        model.oerCollection.title

      topRow =
        let
            table =
              if model.collectionsMenuOpen then
                [ below <| viewCollectionsTable model ]
              else
                []
        in
            row ([ width fill, paddingXY 15 8 ] ++ table)

      toggleButton =
        let
            str =
              if model.collectionsMenuOpen then
                "Hide"
              else
                "Collections"
        in
            actionButtonWithoutIcon [ greyText ] [] str (Just ToggleCollectionsMenu)

      content =
        [ info
        , toggleButton
        ]
        |> topRow

      info =
        case searchState.searchResults of
          Nothing ->
            "Searching in " ++ collectionTitle ++ " ..."
            |> bodyWrap [ whiteText ]

          Just oerIds ->
            let
                numberText =
                  case oerIds |> List.length of
                    0 ->
                      "No"

                    n ->
                      n
                      |> String.fromInt
            in
                numberText ++ " result" ++ (if List.length oerIds == 1 then "" else "s") ++ " for \""++ searchState.lastSearch ++"\" in " ++ collectionTitle
                |> bodyWrap [ whiteText ]
  in
      content
      |> el [ width fill, Background.color grey40 ]


viewCollectionsTable : Model -> Element Msg
viewCollectionsTable model =
  oerCollections
  |> List.map viewCollection
  |> column [ width fill, spacing 8, padding 8, Background.color materialDark ]


viewCollection : OerCollection -> Element Msg
viewCollection {title, description, url} =
  let
      label =
        [ title |> bodyWrap [ greyText ]
        , description |> bodyWrap [ greyText ]
        , url |> bodyWrap [ greyText ]
        ]
        |> row [ width fill ]
  in
      button [ padding 15, width fill, Background.color grey40, Border.rounded 4 ] { onPress = Just (SelectedOerCollection title), label = label }
