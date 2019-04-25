module View.Diary exposing (viewDiary)

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


viewDiary model key =
  let
      diary =
        getDiary model key

      heading : Element Msg
      heading =
        "Quick Notes" |> subheaderWrap []

      quickNotesWidget : Element Msg
      quickNotesWidget =
        let
            quickNotesButton : String -> Element Msg
            quickNotesButton str =
              actionButtonWithoutIcon [ Background.color x5colorSemiTransparent, whiteText, paddingXY 5 3 ] str (Just (AddQuickNoteToDiary key str))
        in
            [ "Too hard for me", "Too easy for me", "Just what I need", "Not interested" ]
            |> List.map quickNotesButton
            |> wrappedRow [ spacing 8, width fill, alignRight ]

      headingRow : Element Msg
      headingRow =
        [ heading
        , quickNotesWidget
        ]
        |> column [ spacing 15, width fill ]

      newEntryValue =
        getDiaryNewEntry model key

      saveButton =
        actionButtonWithoutIcon [ bigButtonPadding ] "Save" (if newEntryValue=="" then Nothing else Just <| SaveDiaryEntry key)

      textField =
        Input.text [ width fill, onEnter <| (SaveDiaryEntry key), Border.color x5color ] { onChange = EditDiaryEntry key, text = newEntryValue, placeholder = Just ("Write a note" |> text |> Input.placeholder [ Font.size 16 ]), label = Input.labelHidden "note" }
        -- |> el [ width fill ]

      newEntry =
        [ textField
        -- , saveButton
        ]
        |> row [ spacing 10, width fill ]

      savedEntries =
        if List.isEmpty diary.savedEntries then
          []
        else
          diary.savedEntries
          |> List.reverse
          |> List.map (viewDiarySavedEntry model)
          |> column [ spacing 10, width fill ]
          |> List.singleton

      content : Element Msg
      content =
        ([ headingRow ] ++ savedEntries ++ [ newEntry ])
        |> column [ width fill, spacing 15 ]
  in
      [ (diary.savedEntries |> List.length |> String.fromInt, content) ]
      |> Keyed.column [ width fill ]


viewDiarySavedEntry model entry =
  -- [ el [] (humanReadableRelativeTime model entry.time |> text)
  let
      date =
        entry.time
        |> humanReadableRelativeTime model
        |> captionNowrap [ greyTextDisabled ]

      actions =
        button [] { onPress = Just <| RemoveDiaryEntry entry.time, label = trashIcon }
  in
      [ avatarImage |> el [ alignTop ]
      , entry.body |> bodyWrap [ width fill ] |> el [ width fill ]
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
      if minutesAgo<10 then
        "Just now"
      else if minutesAgo<60 then
        "Less than an hour ago"
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
