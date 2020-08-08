module View.Inspector exposing (viewInspector)

import Set

import Html
import Html.Attributes as Attributes exposing (style)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Json.Decode

import Model exposing (..)
import Msg exposing (..)

import View.Utility exposing (..)
import View.ContentFlowBar exposing (..)
import View.Html5VideoPlayer exposing (..)
import View.PdfViewer exposing (..)
import View.Explainer exposing (..)

import Animation exposing (..)

import I18Next exposing ( t, Delims(..) )


viewInspector : Model -> List (Attribute Msg)
viewInspector model =
  case model.inspectorState of
    Nothing ->
      []

    Just inspectorState ->
      [ inFront <| viewTheInspector model inspectorState ]


viewTheInspector : Model -> InspectorState -> Element Msg
viewTheInspector model inspectorState =
  let
      title =
        if model.openedOerFromPlaylist then
          let
            editButton =
              if model.editingOerTitleInPlaylist then
                button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditOerInPlaylist False "title", label = (t model.translations "inspector.btn_save_title") |> captionNowrap [ width fill, whiteText, Font.center ] }
              else
                button [ paddingXY 5 3, buttonRounding, Background.color electricBlue ] { onPress = Just <| EditOerInPlaylist True "title", label = (t model.translations "inspector.btn_edit_title") |> captionNowrap [ width fill, whiteText, Font.center ] }

          in
            if model.editingOerTitleInPlaylist then
              let
                textInput labelText valueText =
                  Input.text [ width fill, Font.size 14, onEnter SubmittedPlaylistItemUpdate ] { onChange = UpdatePlaylistItem "title", text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = Input.labelHidden (t model.translations "inspector.lbl_feedback_about_resource") }
              in
                textInput (t model.translations "inspector.lbl_title") model.editingOerPlaylistItem.title
            else
              case model.editingOerPlaylistItem.title of
                "" ->
                  [ text (t model.translations "inspector.lbl_title_unavailable") |> el [ Font.size 21, Font.color midnightBlue, Font.italic ] , editButton ] |> row [ spacing 10, width fill ]

                titleText ->
                  [ text titleText |> el [ Font.size 21, Font.color midnightBlue ] , editButton ] |> row [ spacing 10, width fill ]
        else
          case inspectorState.oer.title of
            "" ->
              (t model.translations "inspector.lbl_title_unavailable") |> subheaderWrap [ Font.italic ]

            titleText ->
              titleText |> subheaderWrap []

      bodyAndSidebar =
        if isBrowserWindowTooSmall model then
          (t model.translations "inspector.lbl_require_larger_screen") |> bodyWrap [ paddingXY 0 40 ]
        else if inspectorState.oer.mediatype=="pdf" && model.windowWidth < 1005 then
          (t model.translations "inspector.lbl_require_larger_screen") |> bodyWrap [ paddingXY 0 40 ]
        else if isLabStudy1 model then
          viewInspectorBody model inspectorState
        else
          [ viewInspectorSidebar model inspectorState
          , viewInspectorBody model inspectorState
          ]
          |> row []

      hideWhileOpening =
        alpha <| if model.animationsPending |> Set.member inspectorId then 0.01 else 1

      header =
        [ title
        , button [] { onPress = Just PressedCloseButtonInInspector, label = closeIcon }
        ]
        |> row [ width fill, spacing 4 ]

      sheet =
        [ header
        , bodyAndSidebar
        ]
        |> column [ htmlClass "PreventClosingInspectorOnClick", width (px <| sheetWidth model), Background.color white, centerX, moveRight (navigationDrawerWidth/2),  centerY, padding 16, spacing 16, htmlId inspectorId, hideWhileOpening, dialogShadow ]

      animatingBox =
        case model.inspectorAnimation of
          Nothing ->
            none

          Just animation ->
            let
                (box, opacity) =
                  if animation.frameCount > 1 then
                    (animation.end, 5/((toFloat animation.frameCount)+5))
                  else
                    (interpolateBoxes animation.start animation.end, 0)
            in
                none
                |> el [ whiteBackground, width (box.sx |> round |> px), height (box.sy |> round |> px), moveRight box.x, moveDown box.y, htmlClass "InspectorAnimation", alpha opacity, Border.rounded 5 ]

      scrim =
        let
            opacity =
              case inspectorAnimationStatus model of
                Inactive ->
                  materialScrimAlpha

                Prestart ->
                  0

                Started ->
                  materialScrimAlpha
        in
            none
            |> el [ Background.color <| rgba 0 0 0 opacity, width (model.windowWidth - navigationDrawerWidth |> px), height (fill |> maximum (model.windowHeight - pageHeaderHeight)), moveDown (toFloat pageHeaderHeight), moveRight navigationDrawerWidth,  htmlClass "InspectorScrim" ]
  in
      sheet
      |> el [ width fill, height fill, behindContent scrim, inFront animatingBox ]


viewInspectorBody : Model -> InspectorState -> Element Msg
viewInspectorBody model ({oer, fragmentStart} as inspectorState) =
  let
      player =
        if isVideoFile oer.url then
          viewHtml5VideoPlayer model oer
          |> explainify model explanationForHtml5VideoPlayer
        else if isPdfFile oer.url then
          viewPdfViewer oer.url "45vh"
        else
          none
  in
      [ player
      , viewContentFlowBarWrapper model inspectorState oer
      ]
      |> column [ width <| px <| playerWidth model, moveLeft (inspectorSidebarWidth model) ]


viewDescription : InspectorState -> Oer -> Model -> Element Msg
viewDescription inspectorState oer model =
  if model.openedOerFromPlaylist then
    let
      editButton =
        if model.editingOerDescriptionInPlaylist then
          button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditOerInPlaylist False "description" , label = (t model.translations "inspector.btn_save_description") |> captionNowrap [ width fill, whiteText, Font.center ] }
        else
          button [ paddingXY 5 3, buttonRounding, Background.color electricBlue ] { onPress = Just <| EditOerInPlaylist True "description" , label = (t model.translations "inspector.btn_edit_description") |> captionNowrap [ width fill, whiteText, Font.center ] }

    in
      if model.editingOerDescriptionInPlaylist then
        let
          textMultiline labelText valueText =
            Input.multiline [ width fill, Font.size 14, onEnter SubmittedPlaylistItemUpdate ] { onChange = UpdatePlaylistItem "description", text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = Input.labelHidden (t model.translations "inspector.lbl_feedback_about_resource"), spellcheck = False }
        in
          textMultiline "Description" model.editingOerPlaylistItem.description
      else
        case model.editingOerPlaylistItem.description of
          "" ->
            [ (t model.translations "inspector.lbl_description_unavailable") |> italicText |> el [ paddingTop 30 ], editButton]
            |> row []

          str ->
            let
                characterLimit =
                  300
            in
                if String.length str < characterLimit then
                  [ str
                    |> viewString False
                    , editButton
                  ]
                  |> column [ spacing 10 ]
                else if inspectorState.userPressedReadMore then
                  [ str
                    |> viewString True
                    , editButton
                  ]
                  |> column [ spacing 10 ]
                else
                  [ str
                    |> truncateSentence characterLimit
                    |> viewString False
                    , [ viewReadMoreButton model inspectorState, editButton ] |> row [ spacing 10 ]
                  ] 
                  |> column [ spacing 10 ]
  else
    case oer.description of
      "" ->
        (t model.translations "inspector.lbl_description_unavailable") |> italicText |> el [ paddingTop 30 ]

      str ->
        let
            characterLimit =
              300
        in
            if String.length str < characterLimit then
              str
              |> viewString False
            else if inspectorState.userPressedReadMore then
              str
              |> viewString True
            else
              [ str
                |> truncateSentence characterLimit
                |> viewString False
                , viewReadMoreButton model inspectorState
              ]
              |> column [ spacing 10 ]


viewReadMoreButton : Model -> InspectorState -> Element Msg
viewReadMoreButton model inspectorState =
  button
    []
    { onPress = Just <| PressedReadMore inspectorState
    , label = (t model.translations "inspector.btn_read_more") |> bodyNoWrap [ Font.color electricBlue ]
    }


viewString : Bool -> String -> Element Msg
viewString isScrollbarEnabled str =
  let
      scrollbar =
        if isScrollbarEnabled then
          [ scrollbarY ]
        else
          []

      attrs =
        [ spacing 7, height fill, paddingTop 30 ] ++ scrollbar
  in
      str
      |> String.split("\n")
      |> List.filter (\line -> String.length line > 2)
      |> List.map (bodyWrap [])
      |> column attrs


viewLinkToFile : Model -> Oer -> Element Msg
viewLinkToFile model oer =
  newTabLink [ htmlClass "CursorPointer", alignRight ] { url = oer.url, label = (t model.translations "inspector.lbl_expand_document") |> bodyWrap [ width fill, Font.color electricBlue ] }
  |> el [ width fill ]


sheetWidth model =
  model.windowWidth - navigationDrawerWidth
  |> min (playerWidth model + (inspectorSidebarWidth model) + 35)


viewCourseSettings : Model -> Oer -> CourseItem -> List (Element Msg)
viewCourseSettings model oer {comment} =
  let
      topRowAttrs =
        [ width fill, paddingTop 10 ] ++ (if isLabStudy1 model then [] else [ borderTop 1, Border.color greyDivider ])

      topRow =
        [ (t model.translations "inspector.lbl_video_added_to_workspace") |> bodyWrap [ width fill ]
        , changesSaved
        , actionButtonWithIcon [] [] IconLeft 0.7 "delete" "Remove" <| Just <| RemovedOerFromCourse oer.id
        ]
        |> row topRowAttrs

      commentField =
        Input.text [ width fill, htmlId "TextInputFieldForCommentOnCourseItem", onEnter <| SubmittedCourseItemComment, Border.color primaryGreen, Font.size 14, padding 3, moveDown 5 ] { onChange = ChangedCommentTextInCourseItem oer.id, text = comment, placeholder = Just ((t model.translations "inspector.lbl_enter_comments") |> text |> Input.placeholder [ Font.size 14, moveDown 6 ]), label = Input.labelHidden "Comment on course item" }

      changesSaved =
        if model.courseChangesSaved then
          "✓ " ++ (t model.translations "profile.lbl_saved") |> captionNowrap [ alignRight, greyText, paddingRight 10 ]
        else
          none
  in
      [ topRow
      , commentField
      ]


viewContentFlowBarWrapper : Model -> InspectorState -> Oer -> Element Msg
viewContentFlowBarWrapper model inspectorState oer =
  let
      courseSettings =
        if isLoggedIn model then -- this feature is only available for registered users
          case getCourseItem model oer of
            Nothing ->
              let
                  content =
                    if isLabStudy1 model then
                      (t model.translations "inspector.lbl_drag_range_instruction") |> captionNowrap [ paddingTop 8 ]
                    else
                      actionButtonWithIcon [] [] IconLeft 0.7 "bookmarklist_add" (t model.translations "inspector.btn_add_to_workspace") <| Just <| AddedOerToCourse oer
              in
                  [ none |> el [ width fill ]
                  , content
                  ]

            Just item ->
              viewCourseSettings model oer item
        else
          []

      addToPlaylistButton = 
          let

            filteredPlaylists = 
              case model.userPlaylists of
                Nothing ->
                  []

                Just playlists ->
                  List.filter (\x -> checkIfOerDoesNotExistsInPlaylist x.oerIds oer.id) playlists

            option playlist =
              actionButtonWithoutIcon [] [ width fill, bigButtonPadding, htmlClass "HoverGreyBackground" ] playlist.title (Just <| SelectedAddToPlaylist playlist oer)

            options : List (Attribute Msg)
            options =
              case model.popup of
                Just AddToPlaylistPopup ->
                  List.map  (\x -> option x) filteredPlaylists
                  |> menuColumn [ width fill ]
                  |> above
                  |> List.singleton

                _ ->
                  []

            attrs =
              [ alignLeft, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
          in
            actionButtonWithIcon [] [] IconLeft 0.7 "bookmarklist_add" ((t model.translations "inspector.btn_add_to_playlist") ++ " ▾")  (Just OpenedAddToPlaylistMenu)
            |> el attrs

      components =
        if isLabStudy1 model then
          courseSettings
        else
          if isPdfFile oer.url then
            [ viewLinkToFile model oer ] ++ [ viewDescription inspectorState oer model ] ++ [ addToPlaylistButton ]
          else
            [ viewDescription inspectorState oer model ] ++ [ addToPlaylistButton ]

      containerHeight =
        if isLabStudy1 model then
          100
        else
          200

      contentFlowBar =
        if oer.mediatype == "video" then
          case chunksFromOerId model oer.id of
            [] ->
              []

            wikichunks ->
              let
                  barWrapper =
                    viewContentFlowBar model oer wikichunks (playerWidth model) barIdInInspector
                    |> el [ width <| px <| playerWidth model, height (px 16) ]
              in
                  none
                  |> el [ inFront barWrapper, moveUp (0 - contentFlowBarHeight), height <| px containerHeight ]
                  |> inFront
                  |> List.singleton
        else
          []
  in
      components
      |> column ([ width <| px <| playerWidth model, height <| px <| containerHeight, moveDown 1, spacing 4 ] ++ contentFlowBar)


viewInspectorSidebar : Model -> InspectorState -> Element Msg
viewInspectorSidebar model {oer, inspectorSidebarTab, resourceRecommendations} =
  let
      (heading, content) =
        case inspectorSidebarTab of
          RecommendationsTab ->
            let
                sidebarContent =
                  case resourceRecommendations of
                    [] ->
                      viewLoadingSpinner
                      |> el [ moveDown 160, width fill, centerX ]

                    recommendations ->
                      recommendations
                      |> List.map (viewRecommendationCard model)
                      |> column [ spacing 12, paddingBottom 9 ]
                      |> explainify model explanationForRelatedTab
            in
                ("Related materials"
                , sidebarContent
                )

          FeedbackTab ->
            ("Notes"
            , if (millisSince model model.timeOfLastFeedbackRecorded) < 2000 then viewFeedbackConfirmation model else viewFeedbackTab model oer
            )

      renderTab (tab, title) =
        let
            isCurrent =
              inspectorSidebarTab==tab

            (textColor, borderColor) =
              if isCurrent then
                (Font.color white, Border.color white)
              else
                (greyText, Border.color fullyTransparentColor)
        in
            simpleButton [ Font.size 16, paddingXY 1 20, borderBottom 4, centerX, borderColor, textColor ] title (Just <| SelectInspectorSidebarTab tab oer.id)

      tabsMenu =
        [ (FeedbackTab, (t model.translations "inspector.lbl_notes"))
        , (RecommendationsTab, (t model.translations "inspector.btn_related"))
        ]
        |> List.map renderTab
        |> row [ width fill, spacing 25, Background.color midnightBlue ]

      tabContent =
        if isLoggedIn model then
          -- [ heading |> headlineWrap []
          -- , content
          [ content
          ]
          |> column [ width fill, paddingXY 20 0, spacing 25 ]
        else
          guestCallToSignup model (t model.translations "alerts.lbl_guest_call_to_signup_get_recommendations")
          |> el [ width fill, paddingXY 15 12, Background.color <| rgb 1 0.85 0.6 ]
          |> el [ padding 20 ]
  in
      [ tabsMenu |> el [ width fill ]
      , tabContent |> el [ scrollbarY, height (fill |> maximum 510), width fill ]
      ]
      |> column [ spacing 25, width <| px (inspectorSidebarWidth model), height fill, alignTop, borderLeft 1, borderColorDivider, moveRight ((sheetWidth model) - (inspectorSidebarWidth model) - 35 |> toFloat), Background.color white ]


viewRecommendationCard : Model -> Oer -> Element Msg
viewRecommendationCard model oer =
  let
      title =
        -- |> subSubheaderNoWrap [ paddingXY 16 10, htmlClass "ClipEllipsis", width <| px (recommendationCardWidth - 52) ]
        [ oer.title |> Html.text ]
        |> Html.div [ style "width" (((recommendationCardWidth model) - 32 |> String.fromInt)++"px"), style "font-size" "16px", Attributes.class "ClipEllipsis" ]
        |> html
        |> el []

      bottomInfo =
        let
            dateStr =
              if oer.date |> String.startsWith "Published on " then oer.date |> String.dropLeft ("Published on " |> String.length) else oer.date

            date =
              dateStr |> captionNowrap [ alignLeft ]

            provider =
              (if oer.mediatype=="pdf" then "PDF from " else "") ++ (oer.provider |> domainOnly |> truncateSentence 24)
              |> captionNowrap [ if dateStr=="" then alignLeft else centerX ]

            duration =
              oer.duration |> captionNowrap [ alignRight ]

            content =
              [ date, provider, duration ]
        in
            content
            |> row [ width fill, height fill, alignBottom ]

      widthOfCard =
        width <| px <| recommendationCardWidth model

      heightOfCard =
        height <| px <| recommendationCardHeight
  in
      [ title, bottomInfo ]
      |> column [ widthOfCard, heightOfCard, paddingXY 15 12, spacing 15, htmlClass "MaterialCard" ]
      |> linkTo [] (resourceUrlPath oer.id)


recommendationCardHeight : Int
recommendationCardHeight =
  80


recommendationCardWidth : Model -> Int
recommendationCardWidth model =
  (inspectorSidebarWidth model) - 23


viewFeedbackTab : Model -> Oer -> Element Msg
viewFeedbackTab model oer =
  let        
    notes = 
      List.map (\x -> viewNoteForOer model x) model.userNotesForOer
      |> column [ spacing 5, width fill ]

    formValue =
      getResourceFeedbackFormValue model oer.id

    quickOptions =
      ([ (t model.translations "inspector.btn_material_rating_inspiring")
      , (t model.translations "inspector.btn_material_rating_outstanding")
      , (t model.translations "inspector.btn_material_rating_outdated")
      , (t model.translations "inspector.btn_material_rating_language_errors")
      , (t model.translations "inspector.btn_material_rating_poor_content")
      , (t model.translations "inspector.btn_material_rating_poor_image")
      ] ++ (if isVideoFile oer.url then [ (t model.translations "inspector.btn_material_rating_poor_audio") ] else []))
      |> List.map (\option -> simpleButton [ paddingXY 4 4, Background.color primaryGreen, buttonRounding, Font.size 14, whiteText ] option (Just <| SubmittedResourceFeedback oer.id (">>>"++option)))
      |> column [ width fill, htmlClass "flexWrap" ]

    textField =
      Input.text [ width fill, htmlId "feedbackTextInputField", onEnter <| (SubmittedResourceFeedback oer.id formValue), Border.color x5grey ] { onChange = ChangedTextInResourceFeedbackForm oer.id, text = formValue, placeholder = Just ("Enter your notes" |> text |> Input.placeholder [ Font.size 16 ]), label = Input.labelHidden "Your feedback about this resource" }
  in
      [ (t model.translations "inspector.lbl_material_rating_question") |> bodyWrap []
      , quickOptions
      , (t model.translations "inspector.lbl_notes") |> bodyWrap []
      , notes |> el [ width fill ]
      , textField
      ]
      |> column [ width fill, spacing 20 ]


viewFeedbackConfirmation : Model -> Element Msg
viewFeedbackConfirmation model =
  [ (t model.translations "alerts.lbl_add_note_success_title") |> headlineWrap [ Font.size 24 ]
  , "✔ " ++ (t model.translations "alerts.lbl_add_note_success_message") |> bodyWrap []
  ]
  |> column [ spacing 30, paddingTop 200 ]


explanationForHtml5VideoPlayer : Explanation
explanationForHtml5VideoPlayer =
  { componentId = "html5VideoPlayer"
  , flyoutDirection = Left
  , links = [ explanationLinkForTranslation, explanationLinkForWikification ]
  }


explanationForRelatedTab : Explanation
explanationForRelatedTab =
  { componentId = "relatedTab"
  , flyoutDirection = Left
  , links = [ explanationLinkForItemRecommender ]
  }

checkIfOerDoesNotExistsInPlaylist : List OerId -> Int -> Bool
checkIfOerDoesNotExistsInPlaylist oers oerId =
    case List.head (List.filter (\x -> x == oerId) oers) of
      Nothing ->
        True

      Just _ ->
        False


viewNoteForOer : Model -> Note -> Element Msg
viewNoteForOer model note = 
  case model.editUserNoteForOerInPlace of
    Nothing ->
      let
        topRow =
            note.text |> bodyWrap []

        editButton =
          button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditNoteForOer note, label = (t model.translations "inspector.btn_note_edit") |> captionNowrap [ width fill, whiteText, Font.center ] }

        removeButton =
            button [ paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| RemoveNoteForOer note.id, label = (t model.translations "inspector.btn_note_remove") |> captionNowrap [ width fill, whiteText, Font.center ] }
      
        buttonRow =
          [ editButton
          , removeButton
          ]
          |> row [ width (fillPortion 2), spacing 10 ]

      in
        [ topRow
        , buttonRow
        ]
        |> column [ width fill, spacing 10, padding 10, buttonRounding, Border.width 1, Border.color greyDivider, smallShadow ]

    Just editingNote ->
      if editingNote.id == note.id then
        let
          topRow =
              Input.text [  Font.size 14, width fill, onEnter <| SubmittedNoteEdit, Border.color x5grey ] { onChange = ChangedTextInNote, placeholder = Nothing,  text = editingNote.text, label = Input.labelHidden "Your feedback about this resource" }
        in
          [ topRow
          ]
          |> column [ width fill, spacing 10, padding 10, buttonRounding, Border.width 1, Border.color greyDivider, smallShadow ]

      else 
        let
          topRow =
              note.text |> bodyWrap []

          editButton =
            button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditNoteForOer note, label = (t model.translations "inspector.btn_note_remove") |> captionNowrap [ width fill, whiteText, Font.center ] }

          removeButton =
              button [ paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| RemoveNoteForOer note.id, label = (t model.translations "inspector.btn_note_remove") |> captionNowrap [ width fill, whiteText, Font.center ] }
        
          buttonRow =
            [ editButton
            , removeButton
            ]
            |> row [ width (fillPortion 2), spacing 10 ]
          in
            [ topRow
            , buttonRow
            ]
            |> column [ width fill, spacing 10, padding 10, buttonRounding, Border.width 1, Border.color greyDivider, smallShadow ]


