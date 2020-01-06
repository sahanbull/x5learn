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

import View.Utility exposing (..)


{-| Render a list of user notes to a given OER
-}
viewNoteboard : Model -> Bool -> OerId -> Element Msg
viewNoteboard model includeHeading oerId =
  let
      heading =
        if includeHeading then
          [ "Your notes" |> subheaderWrap [] ]
        else
          []

      quickNotesWidget : Element Msg
      quickNotesWidget =
        let
            quickNotesButton : String -> Element Msg
            quickNotesButton str =
              actionButtonWithoutIcon [] [ Background.color x5colorSemiTransparent, whiteText, paddingXY 5 3 ] str (Just <| ClickedQuickNoteButton oerId str)
        in
            [ "Too hard", "Just right", "Too easy", "Interested", "Not interested" ]
            |> List.map quickNotesButton
            |> wrappedRow [ spacing 8, width fill, alignRight ]

      headingRow : Element Msg
      headingRow =
        heading ++ [ quickNotesWidget ]
        |> column [ spacing 15, width fill ]

      formValue =
        getOerNoteForm model oerId

      textField =
        Input.text [ width fill, htmlId "textInputFieldForNotesOrFeedback", onEnter <| SubmittedNewNoteInOerNoteboard, Border.color x5color ] { onChange = ChangedTextInNewNoteFormInOerNoteboard oerId, text = formValue, placeholder = Just ("Write a note" |> text |> Input.placeholder [ Font.size 16 ]), label = Input.labelHidden "note" }

      newEntry =
        [ textField
        ]
        |> row [ spacing 10, width fill ]

      notes =
        getOerNoteboard model oerId

      noteElements =
        if List.isEmpty notes then
          []
        else
          notes
          |> List.map (viewNote model)
          |> column [ spacing 10, width fill ]
          |> List.singleton

      content : Element Msg
      content =
        if isLoggedIn model then
          [ headingRow ] ++ noteElements ++ [ newEntry ]
          |> column [ width fill, spacing 15 ]
        else
          guestCallToSignup "In order to use all the features and save your changes"
          |> el [ width fill, paddingXY 15 12, Background.color <| rgb 1 0.85 0.6 ]
  in
      [ (notes |> List.length |> String.fromInt, content) ]
      |> Keyed.column [ width fill ]


{-| Render a single Note
-}
viewNote : Model -> Note -> Element Msg
viewNote model note =
  if note.id==0 then -- hide new notes until they are persisted on the db
    viewLoadingSpinner
  else
    let
        date =
          note.time
          |> humanReadableRelativeTime model
          |> captionNowrap [ greyTextDisabled ]

        actions =
          button [] { onPress = Just <| RemoveNote note, label = trashIcon }
    in
        [ avatarImage |> el [ alignTop ]
        , note.text |> bodyWrap [ width fill ] |> el [ width fill ]
        , [ date, actions ] |> row [ spacing 5, alignTop, moveUp 4 ]
        ]
        |> row [ spacing 10, width fill ]


{-| Display a given time (e.g. the creation time of a Note) in a form like: 3 days ago
-}
humanReadableRelativeTime : Model -> Posix -> String
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
        "Now"
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
