module View.Noteboard exposing (viewNoteboard, humanReadableRelativeTime)

import Dict
import Time exposing (posixToMillis)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave, onFocus)
import Element.Keyed as Keyed
import Json.Decode

import Model exposing (..)
import Msg exposing (..)

import View.Shared exposing (..)


viewNoteboard : Model -> UserState -> OerUrl -> Element Msg
viewNoteboard model userState oerUrl =
  let
      heading : Element Msg
      heading =
        "Private Notes" |> subheaderWrap []

      quickNotesWidget : Element Msg
      quickNotesWidget =
        let
            quickNotesButton : String -> Element Msg
            quickNotesButton str =
              actionButtonWithoutIcon [ Background.color x5colorSemiTransparent, whiteText, paddingXY 5 3 ] str (Just <| ClickedQuickNoteButton oerUrl str)
        in
            [ "Too hard", "Just right", "Too easy", "Interested", "Not interested", "Poor quality" ]
            |> List.map quickNotesButton
            |> wrappedRow [ spacing 8, width fill, alignRight ]

      headingRow : Element Msg
      headingRow =
        [ heading
        , quickNotesWidget
        ]
        |> column [ spacing 15, width fill ]

      formValue =
        getOerNoteForm model oerUrl

      textField =
        Input.text [ width fill, onEnter <| (SubmittedNewNoteInOerNoteboard oerUrl), Border.color x5color ] { onChange = ChangedTextInNewNoteFormInOerNoteboard oerUrl, text = formValue, placeholder = Just ("Write a note" |> text |> Input.placeholder [ Font.size 16 ]), label = Input.labelHidden "note" }

      newEntry =
        [ textField
        ]
        |> row [ spacing 10, width fill ]

      notes =
        getOerNoteboard userState oerUrl

      noteElements =
        if List.isEmpty notes then
          []
        else
          notes
          |> List.reverse
          |> List.map (viewNote model)
          |> column [ spacing 10, width fill ]
          |> List.singleton

      content : Element Msg
      content =
        ([ headingRow ] ++ noteElements ++ [ newEntry ])
        |> column [ width fill, spacing 15 ]
  in
      [ (notes |> List.length |> String.fromInt, content) ]
      |> Keyed.column [ width fill ]


viewNote : Model -> Note -> Element Msg
viewNote model note =
  let
      date =
        note.time
        |> humanReadableRelativeTime model
        |> captionNowrap [ greyTextDisabled ]

      actions =
        button [] { onPress = Just <| RemoveNote note.time, label = trashIcon }
  in
      [ avatarImage |> el [ alignTop ]
      , note.text |> bodyWrap [ width fill ] |> el [ width fill ]
      , [ date, actions ] |> row [ spacing 5, alignTop, moveUp 4 ]
      ]
      |> row [ spacing 10, width fill ]


humanReadableRelativeTime {currentTime} time =
  let
      minutesAgo =
        ((posixToMillis currentTime) - (posixToMillis time)) // 1000 // 60

      hoursAgo =
        ceiling <| (toFloat minutesAgo) / 60

      daysAgo =
        hoursAgo // 24

      weeksAgo =
        daysAgo // 7

      monthsAgo =
        ceiling <| (toFloat daysAgo) / 30.4

      yearsAgo =
        daysAgo // 365
  in
      if minutesAgo<7 then
        "Just now"
      else if minutesAgo<60 then
        "Last hour"
      else if hoursAgo<24 then
        (String.fromInt <| hoursAgo ) ++ " hours ago"
      else if daysAgo<7 then
        (String.fromInt <| daysAgo ) ++ " days ago"
      else if weeksAgo<4 then
        (String.fromInt <| weeksAgo ) ++ " weeks ago"
      else if monthsAgo<12 then
        (String.fromInt <| monthsAgo ) ++ " months ago"
      else
        (String.fromInt <| yearsAgo ) ++ " years ago"
