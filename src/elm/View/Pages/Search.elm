module View.Pages.Search exposing (viewSearchPage)

import Url
import Dict
import Set

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
      topRow =
        let
            table =
              if model.collectionsMenuOpen then
                [ below <| viewCollectionsTable model ]
              else
                []
        in
            row ([ width fill, paddingXY 15 27 ] ++ table)

      toggleButton =
        let
            label =
              if model.collectionsMenuOpen then
                "Close" |> bodyNoWrap [ greyText ]
              else
                "More" |> bodyNoWrap [ whiteText ]
        in
            button [] { label = label, onPress = (Just ToggleCollectionsMenu) }

      content =
        [ info
        , toggleButton
        ]
        |> topRow

      info =
        let
            summaryString =
              selectedOerCollectionsToSummaryString model
              |> String.toLower
        in
            case searchState.searchResults of
              Nothing ->
                "Searching in " ++ summaryString ++ " ..."
                |> bodyWrap [ whiteText ]

              Just oerIds ->
                (numberOfResultsText <| List.length oerIds) ++ " for \""++ lastSearch ++"\" in " ++ summaryString
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
                  let
                      str =
                        if lastSearch=="" then
                          "Number of resources"
                        else
                          "Results for \""++ lastSearch ++"\""

                      content =
                        str
                        |> bodyNoWrap [ greyText, alignRight, moveLeft 40, moveUp 8 ]
                  in
                      none
                      |> el [ onLeft <| content ]
        in
            [ allCheckbox model
            , "Collection (select at least one)" |> bodyWrap [ greyText, padding 15 ] |> el [ width <| px collectionTitleWidth ]
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


allCheckbox model =
  let
      isChecked =
        model.selectedOerCollections == setOfAllCollectionTitles

      checkbox =
        Input.checkbox []
          { onChange = ToggledAllOerCollections
          , icon = Input.defaultCheckbox
          , checked = isChecked
          , label = Input.labelHidden "Select or unselect all collections"
          }
  in
      checkbox |> el [ paddingLeft 15 ]


viewCollection : Model -> OerCollection -> Element Msg
viewCollection model ({title, description, url} as collection) =
  let
      numberString =
        case getPredictedNumberOfSearchResults model title of
          Nothing ->
            "..."

          Just number ->
            if number<0 then "n/a" else (number |> String.fromInt)

      isChecked =
        Set.member title model.selectedOerCollections

      item =
        [ title |> bodyWrap [ paddingLeft 30, whiteText, width (px collectionTitleWidth) ]
        , description |> bodyWrap [ greyText, width fill ]
        , numberString |> bodyNoWrap [ greyText, alignRight ] |> el [ width <| px 50 ]
        ]
        |> row [ width fill ]

      border =
        [ Border.color grey40, borderTop 1 ]

      checkbox =
        Input.checkbox []
          { onChange = SelectedOerCollection title
          , icon = Input.defaultCheckbox
          , checked = isChecked
          , label = Input.labelHidden title
          }
        |> el [ padding 15 ]
        |> inFront
  in
      [ item |> el ([ padding 15, width fill ] ++ border)
      , image [ width (px 16), alpha 0.5 ] { src = svgPath "white_external_link", description = "external link" } |> newTabLinkTo [] url
      ]
      |> row [ width fill, spacing 15, collectionOverlay model title isChecked, checkbox ]


collectionOverlay : Model -> String -> Bool -> Attribute Msg
collectionOverlay model title isChecked =
  let
      clickHandler =
        onClick (SelectedOerCollection title (not isChecked))
  in
      none
      |> el [ width (model.windowWidth - navigationDrawerWidth - 50 |> px), height fill, clickHandler, htmlClass "CursorPointer OerCollectionListItem", Background.color fullyTransparentColor ]
      |> inFront


collectionTitleWidth =
  400


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
