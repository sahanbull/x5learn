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
viewTopBar model ({lastSearch} as searchState) =
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
            -- row ([ width fill, paddingXY 15 8 ] ++ table)
            row ([ width fill, paddingXY 15 24 ] ++ table)

      toggleButton =
        let
            label =
              if model.collectionsMenuOpen then
                "Close" |> bodyNoWrap [ greyText ]
              else
                case Dict.get lastSearch model.cachedCollectionsSearchPredictions of
                  Nothing ->
                    "Other collections" |> bodyNoWrap [ whiteText ]

                  Just prediction ->
                    case getPredictedNumberOfSearchResults model model.oerCollection.title of
                      Nothing ->
                        "Other collections" |> bodyNoWrap [ whiteText ] -- shouldn't happen

                      Just nThis ->
                        let
                            nTotal =
                              prediction
                              |> Dict.values
                              |> List.sum

                            nOther =
                              nTotal - nThis
                        in
                            [ (numberOfResultsText nOther) ++ " in" |> bodyNoWrap [ greyText ]
                            , "other collections" |> bodyNoWrap [ whiteText ]
                            ]
                            |> row [ spacing 5, alignRight ]
        in
            button [] { label = label, onPress = (Just ToggleCollectionsMenu) }

      content =
        [ info
        -- , if model.collectionsMenuOpen then none else otherCollectionsSummary
        , toggleButton
        ]
        |> topRow

      info =
        case searchState.searchResults of
          Nothing ->
            "Searching in " ++ collectionTitle ++ " ..."
            |> bodyWrap [ whiteText ]

          Just oerIds ->
            collectionTitle ++ ": " ++ (numberOfResultsText <| List.length oerIds) ++ " for \""++ lastSearch ++ "\""
            -- (numberOfResultsText <| List.length oerIds) ++ " for \""++ lastSearch ++"\" in " ++ collectionTitle
            |> bodyWrap [ whiteText ]
  in
      content
      |> el [ width fill, Background.color grey40 ]


viewCollectionsTable : Model -> Element Msg
viewCollectionsTable model =
  let
      header =
        let
            results : Element Msg
            results =
              case model.searchState of
                Nothing ->
                  none

                Just {lastSearch} ->
                  if lastSearch=="" then
                     none
                  else
                    let
                        content =
                          "Results for \""++ lastSearch ++"\""
                          |> bodyNoWrap [ greyText, alignRight, moveLeft 40 ]
                    in
                        none
                        |> el [ onLeft <| content ]
        in
            [ "Collection title" |> bodyWrap [ greyText, padding 15, width <| px collectionTitleWidth ]
            , [ "Description" |> bodyWrap [ greyText, padding 15, width <| fillPortion 2 ]
              , results
              ]
              |> row [ width fill ]
            ]
            |> row [ width fill ]

      body =
        oerCollections
        |> List.map (viewCollection model)
        |> column [ width fill, spacing 0 ]
  in
      [ header
      , body
      ]
      |> column [ width fill, Background.color materialDark, padding 8 ]


viewCollection : Model -> OerCollection -> Element Msg
viewCollection model ({title, description, url} as collection) =
  let
      numberString =
        case getPredictedNumberOfSearchResults model title of
          Nothing ->
            "..."

          Just number ->
            if number<0 then "n/a" else (number |> String.fromInt)

      label =
        [ title |> bodyWrap [ whiteText, width (px collectionTitleWidth) ]
        , description |> bodyWrap [ greyText, width fill ]
        , numberString |> bodyNoWrap [ greyText, alignRight ]
        ]
        |> row [ width fill ]

      border =
        [ Border.color grey40, borderTop 1 ]

      background =
        [ Background.color (if collection == model.oerCollection then grey40 else materialDark) ]
  in
      [ button ([ padding 15, width fill, htmlClass "OerCollectionListItem" ] ++ border ++ background) { onPress = Just (SelectedOerCollection title), label = label }
      , image [ width (px 16), alpha 0.5 ] { src = svgPath "white_external_link", description = "external link" } |> newTabLinkTo [] url
      ]
      |> row [ width fill, spacing 15 ]


collectionTitleWidth =
  450


numberOfResultsText nResults =
  let
      numberText =
        case nResults of
          0 ->
            "No"

          n ->
            n
            |> String.fromInt
  in
      numberText ++ " result" ++ (if nResults==1 then "" else "s")
