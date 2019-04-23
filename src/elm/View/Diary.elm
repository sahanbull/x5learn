module View.Diary exposing (viewDiary)

import Dict
import Time exposing (Posix)

import Html
import Html.Attributes
import Html.Events

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

      heading =
        "Your notes" |> subheaderWrap []

      newEntryValue =
        getDiaryNewEntry model key

      saveClickAction =
        if newEntryValue=="" then
          []
        else
          [ onClick (SaveDiaryEntry key) ]

      saveButton =
        actionButtonWithoutIcon [ bigButtonPadding ] "Save" (Just saveClickAction)

      textField =
        Input.text [ width fill, onEnter <| (SaveDiaryEntry key), Border.color x5color ] { onChange = EditDiaryEntry key, text = newEntryValue, placeholder = Just ("Add a note" |> text |> Input.placeholder [ Font.size 14 ]), label = Input.labelHidden "note" }
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
          |> column [ spacing 10 ]
          |> List.singleton

      content =
        ([ heading ] ++ savedEntries ++ [ newEntry ])
        |> column [ width fill, spacing 8 ]
  in
      [ (diary.savedEntries |> List.length |> String.fromInt, content) ]
      |> Keyed.column []


viewDiarySavedEntry model entry =
  -- [ el [] (humanReadableRelativeTime model entry.time |> text)
  [ avatarImage
  , entry.body |> bodyWrap []
  ]
  |> row [ spacing 10 ]


-- humanReadableRelativeTime {currentTime} time =
--   if currentTime - time < 10 * Time.minute then
--     "Just now"
--   else
--     let
--         diffDays =
--           Duration.diffDays (Date.fromTime currentTime) (Date.fromTime time)
--     in
--         case diffDays of
--           0 ->
--             "Today"

--           1 ->
--             "Yesterday"

--           _ ->
--             (toString diffDays) ++ " days ago"
