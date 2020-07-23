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
import Model exposing (MLLPState(..))
import Model exposing (InspectorSidebarTab(..))


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
                button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditOerInPlaylist False "title", label = "Save Title" |> captionNowrap [ width fill, whiteText, Font.center ] }
              else
                button [ paddingXY 5 3, buttonRounding, Background.color electricBlue ] { onPress = Just <| EditOerInPlaylist True "title", label = "Edit Title" |> captionNowrap [ width fill, whiteText, Font.center ] }

          in
            if model.editingOerTitleInPlaylist then
              let
                textInput labelText valueText =
                  Input.text [ width fill, Font.size 14, onEnter SubmittedPlaylistItemUpdate ] { onChange = UpdatePlaylistItem "title", text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = Input.labelHidden "Your feedback about this resource" }
              in
                textInput "Title" model.editingOerPlaylistItem.title
            else
              case model.editingOerPlaylistItem.title of
                "" ->
                  [ text "Title unavailable" |> el [ Font.size 21, Font.color midnightBlue, Font.italic ] , editButton ] |> row [ spacing 10, width fill ]

                titleText ->
                  [ text titleText |> el [ Font.size 21, Font.color midnightBlue ] , editButton ] |> row [ spacing 10, width fill ]
        else
          case inspectorState.oer.title of
            "" ->
              "Title unavailable" |> subheaderWrap [ Font.italic ]

            titleText ->
              titleText |> subheaderWrap []

      bodyAndSidebar =
        if isBrowserWindowTooSmall model then
          "Sorry! This content requires a larger screen." |> bodyWrap [ paddingXY 0 40 ]
        else if inspectorState.oer.mediatype=="pdf" && model.windowWidth < 1005 then
          "Sorry! This content requires a wider screen." |> bodyWrap [ paddingXY 0 40 ]
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
      case getYoutubeVideoId oer.url of
        Nothing ->
          if isVideoFile oer.url then
            viewHtml5VideoPlayer model oer
            |> explainify model explanationForHtml5VideoPlayer
          else if isPdfFile oer.url then
            viewPdfViewer oer.url "45vh"
          else
            none

        Just youtubeId ->
          let
              startTime =
                fragmentStart * oer.durationInSeconds |> floor
          in
              embedYoutubePlayer model youtubeId startTime
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
          button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditOerInPlaylist False "description" , label = "Save Description" |> captionNowrap [ width fill, whiteText, Font.center ] }
        else
          button [ paddingXY 5 3, buttonRounding, Background.color electricBlue ] { onPress = Just <| EditOerInPlaylist True "description" , label = "Edit Description" |> captionNowrap [ width fill, whiteText, Font.center ] }

    in
      if model.editingOerDescriptionInPlaylist then
        let
          textMultiline labelText valueText =
            Input.multiline [ width fill, Font.size 14, onEnter SubmittedPlaylistItemUpdate ] { onChange = UpdatePlaylistItem "description", text = valueText, placeholder = Just (labelText|> text |> Input.placeholder []), label = Input.labelHidden "Your feedback about this resource" , spellcheck = False }
        in
          textMultiline "Description" model.editingOerPlaylistItem.description
      else
        case model.editingOerPlaylistItem.description of
          "" ->
            [ "No description available" |> italicText |> el [ paddingTop 30 ], editButton]
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
                    , [ viewReadMoreButton inspectorState, editButton ] |> row [ spacing 10 ]
                  ] 
                  |> column [ spacing 10 ]
  else
    case oer.description of
      "" ->
        "No description available" |> italicText |> el [ paddingTop 30 ]

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
                , viewReadMoreButton inspectorState
              ]
              |> column [ spacing 10 ]


viewReadMoreButton : InspectorState -> Element Msg
viewReadMoreButton inspectorState =
  button
    []
    { onPress = Just <| PressedReadMore inspectorState
    , label = "Read more" |> bodyNoWrap [ Font.color electricBlue ]
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


viewLinkToFile : Oer -> Element Msg
viewLinkToFile oer =
  newTabLink [ htmlClass "CursorPointer", alignRight ] { url = oer.url, label = "Expand Document" |> bodyWrap [ width fill, Font.color electricBlue ] }
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
        [ "This video has been added to your workspace." |> bodyWrap [ width fill ]
        , changesSaved
        , actionButtonWithIcon [] [] IconLeft 0.7 "delete" "Remove" <| Just <| RemovedOerFromCourse oer.id
        ]
        |> row topRowAttrs

      commentField =
        Input.text [ width fill, htmlId "TextInputFieldForCommentOnCourseItem", onEnter <| SubmittedCourseItemComment, Border.color primaryGreen, Font.size 14, padding 3, moveDown 5 ] { onChange = ChangedCommentTextInCourseItem oer.id, text = comment, placeholder = Just ("Enter any comments about this item" |> text |> Input.placeholder [ Font.size 14, moveDown 6 ]), label = Input.labelHidden "Comment on course item" }

      changesSaved =
        if model.courseChangesSaved then
          "✓ Saved" |> captionNowrap [ alignRight, greyText, paddingRight 10 ]
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
                      "You can add this video to your workspace by dragging a range on the timeline." |> captionNowrap [ paddingTop 8 ]
                    else
                      actionButtonWithIcon [] [] IconLeft 0.7 "bookmarklist_add" "Add to workspace" <| Just <| AddedOerToCourse oer
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
            case model.userPlaylists of
              Nothing ->
                actionButtonWithIcon [Font.color red] [] IconLeft 0.7 "bookmarklist_add" "You need to create a playlist first"  (Just OpenedAddToPlaylistMenu)
                |> el attrs
              Just playlist ->
                if List.length playlist == 0 then
                  actionButtonWithIcon [Font.color red] [] IconLeft 0.7 "bookmarklist_add" "You need to create a playlist first"  (Just OpenedAddToPlaylistMenu)
                  |> el attrs
                else
                  actionButtonWithIcon [] [] IconLeft 0.7 "bookmarklist_add" "Add To Playlist ▾"  (Just OpenedAddToPlaylistMenu)
                  |> el attrs

      components =
        if isLabStudy1 model then
          courseSettings
        else
          if isPdfFile oer.url then
            [ viewLinkToFile oer ] ++ [ viewDescription inspectorState oer model ] ++ [ addToPlaylistButton ]
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

          NotesTab ->
            ("Notes"
            , if (millisSince model model.timeOfLastFeedbackRecorded) < 2000 then viewFeedbackConfirmation inspectorSidebarTab else viewFeedbackTab model oer inspectorSidebarTab
            )

          FeedbackTab ->
            ("Reviews"
            , if (millisSince model model.timeOfLastFeedbackRecorded) < 2000 then viewFeedbackConfirmation inspectorSidebarTab else viewFeedbackTab model oer inspectorSidebarTab
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
            simpleButton [ Font.size 14, paddingXY 1 20, borderBottom 4, centerX, borderColor, textColor ] title (Just <| SelectInspectorSidebarTab tab oer.id)

      tabsMenu =
        [ (NotesTab, "Notes")
        , (FeedbackTab, "Review")
        , (RecommendationsTab, "Related")
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
          guestCallToSignup "In order to benefit from the full feature set, including personalised recommendations of learning materials"
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


viewFeedbackTab : Model -> Oer -> InspectorSidebarTab -> Element Msg
viewFeedbackTab model oer tab =
  let        
    notes = 
      List.map (\x -> viewNoteForOer model x tab) model.userNotesForOer
      |> column [ spacing 5, width fill ]

    reviews = 
      List.map (\x -> viewNoteForOer model x tab) model.userReviewsForOer
      |> column [ spacing 5, width fill ]

    formValue =
      getResourceFeedbackFormValue model oer.id

    quickOptions =
      ([ "Inspiring"
      , "Outstanding"
      , "Outdated"
      , "Language errors"
      , "Poor content"
      , "Poor image"
      ] ++ (if isVideoFile oer.url || hasYoutubeVideo oer.url then [ "Poor audio" ] else []))
      |> List.map (\option -> simpleButton [ paddingXY 4 4, Background.color primaryGreen, buttonRounding, Font.size 12, whiteText ] option (Just <| SubmittedResourceFeedback oer.id (">>>"++option)))
      |> column [ width fill, htmlClass "flexWrap" ]

    textField =
      case model.mllpState of
        StopRecognition ->
          if formValue == "" then
            "Start speaking. Your text will appear here" |> bodyWrap [ Font.color greyMedium, Font.size 12, Border.width 1, Border.color x5grey, width fill, height (fill |> minimum 70 ),  Border.rounded 4, paddingXY 8 8 ]
          else
            formValue |> bodyWrap [ Font.size 12, Border.width 1, Border.color x5grey, width fill, height (fill |> minimum 70 ), Border.rounded 4, paddingXY 10 10 ]


        _ ->
          if tab == NotesTab then
            Input.multiline [ width fill, htmlId "feedbackTextInputField", onEnter <| (SubmittedNote oer.id formValue), Font.size 12, Border.color x5grey, onClick <| SetVideoCurrentPlayTime ] { onChange = ChangedTextInResourceFeedbackForm oer.id, text = formValue, placeholder = Just ("Enter your notes" |> text |> Input.placeholder [ Font.size 12 ]), spellcheck = False, label = Input.labelHidden "Your feedback about this resource" }
          else
            Input.multiline [ width fill, htmlId "feedbackTextInputField", onEnter <| (SubmittedResourceFeedback oer.id formValue), Font.size 12, Border.color x5grey, onClick <| SetVideoCurrentPlayTime ] { onChange = ChangedTextInResourceFeedbackForm oer.id, text = formValue, placeholder = Just ("Enter your review" |> text |> Input.placeholder [ Font.size 12 ]), spellcheck = False, label = Input.labelHidden "Your feedback about this resource" }

    recognitionButton =
      case model.mllpState of
        EnableMicrophone ->
          simpleButton [ Font.size 12, Font.color electricBlue ] "Enable Microphone" (Just <| InitMLLP )
        StartRecognition ->
          simpleButton [ Font.size 12, Font.color red ] "Start Recording" (Just <| StartSpeechRegonition )
        StopRecognition ->
          simpleButton [ Font.size 12, Font.color electricBlue ] "Stop Recording" (Just <| StopSpeechRegonition oer.id formValue tab)
        TextInput ->
          simpleButton [ Font.size 12, Font.color electricBlue ] "Cancel" (Just <| ResetMLLPState)

    mllpSystemButton = 
      let
        buttonText = 
          case model.selectedMLLPSystem of
            Nothing ->
              "English ▾"
        
            Just system ->
              system.name ++ " ▾"
        
        option system =
          actionButtonWithoutIcon [ Font.size 12 ] [ width fill, paddingXY 5 8, htmlClass "HoverGreyBackground" ] system.name (Just <| SelectedMLLPSystem system)

        options : List (Attribute Msg)
        options =
          case model.popup of
            Just MLLPSystemPopup ->
              List.map  (\x -> option x) model.mllpSystems
              |> menuColumn [ width fill]
              |> above
              |> List.singleton

            _ ->
              []

        attrs =
          [ width fill, alignLeft, htmlClass "PreventClosingThePopupOnClick", buttonRounding ] ++ options
      in
        actionButtonWithoutIcon [ Font.size 12, width fill, centerX, paddingXY 5 8] [ width fill, buttonRounding, Border.width 1, Border.color x5grey ] buttonText (Just OpenedMLLPSystemMenu)
        |> el attrs

    mllpRow =
      if List.length model.mllpSystems == 0 then
        recognitionButton |> el [ alignRight ]
      else
        [ mllpSystemButton, recognitionButton ] |> row [ width (fillPortion 2), spacing 10 ]
    
  in
    if tab == NotesTab then
      [ "Notes" |> bodyWrap []
      , notes |> el [ width fill ]
      , textField
      , mllpRow
      ]
      |> column [ width fill, spacing 20 ]
    else
      [ "Rating" |> bodyWrap []
      --, "How would you describe this material?" |> bodyWrap []
      , quickOptions
      , "Comments" |> bodyWrap []
      , reviews |> el [ width fill ]
      , textField
      , mllpRow
      ]
      |> column [ width fill, spacing 20 ]


viewFeedbackConfirmation : InspectorSidebarTab -> Element Msg
viewFeedbackConfirmation tab =
  if tab == NotesTab then
    [ "Note Saved" |> headlineWrap [ Font.size 24 ]
    , "✔ Your note has been recorded." |> bodyWrap []
    ]
    |> column [ spacing 30, paddingTop 200 ]
  else 
    [ "Review Saved" |> headlineWrap [ Font.size 24 ]
    , "✔ Your review has been recorded." |> bodyWrap []
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


viewNoteForOer : Model -> Note -> InspectorSidebarTab -> Element Msg
viewNoteForOer model note tab = 
  if tab == NotesTab then
    case model.editUserNoteForOerInPlace of
      Nothing ->
        let
          topRow =
            let
              explodedNote =
                String.split "]" note.text

              timestamp = 
                if List.length explodedNote == 3 then
                  case List.head explodedNote of
                    Nothing ->
                      ""

                    Just timestampText ->
                      case List.head (Maybe.withDefault [] (List.tail explodedNote)) of
                        Nothing ->
                          ""

                        Just timestampEndText ->
                          timestampText ++ "]" ++ timestampEndText ++ "]"
                else
                  ""

              noteText = 
                 if List.length explodedNote == 3 then
                    case List.head ( List.reverse explodedNote) of
                      Nothing ->
                        ""
                      Just tempNoteText ->
                        tempNoteText
                else
                  note.text

            in
              [ timestamp |> bodyWrap []
              , noteText |> bodyWrap [ paddingXY 0 10 ]
              ]
              |> column []

          editButton =
              button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditNoteForOer note, label = "Edit" |> captionNowrap [ width fill, whiteText, Font.center ] }

          removeButton =
              button [ paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| RemoveNoteForOer note.id, label = "Remove" |> captionNowrap [ width fill, whiteText, Font.center ] }
        
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
              button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditNoteForOer note, label = "Edit" |> captionNowrap [ width fill, whiteText, Font.center ] }

            removeButton =
                button [ paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| RemoveNoteForOer note.id, label = "Remove" |> captionNowrap [ width fill, whiteText, Font.center ] }
          
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
  else
    case model.editUserReviewForOerInPlace of
      Nothing ->
        let
          topRow =
              note.text |> bodyWrap []

          editButton =
              button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditReviewForOer note, label = "Edit" |> captionNowrap [ width fill, whiteText, Font.center ] }

          removeButton =
              button [ paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| RemoveReviewForOer note.id, label = "Remove" |> captionNowrap [ width fill, whiteText, Font.center ] }
        
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
                Input.text [  Font.size 14, width fill, onEnter <| SubmittedReviewEdit, Border.color x5grey ] { onChange = ChangedTextInReview, placeholder = Nothing,  text = editingNote.text, label = Input.labelHidden "Your feedback about this resource" }
          in
            [ topRow
            ]
            |> column [ width fill, spacing 10, padding 10, buttonRounding, Border.width 1, Border.color greyDivider, smallShadow ]

        else 
          let
            topRow =
                note.text |> bodyWrap []

            editButton =
              button [ paddingXY 5 3, buttonRounding, Background.color primaryGreen ] { onPress = Just <| EditReviewForOer note, label = "Edit" |> captionNowrap [ width fill, whiteText, Font.center ] }

            removeButton =
                button [ paddingXY 5 3, buttonRounding, Background.color red ] { onPress = Just <| RemoveReviewForOer note.id, label = "Remove" |> captionNowrap [ width fill, whiteText, Font.center ] }
          
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


