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

import Animation exposing (..)


viewInspector : Model -> List (Attribute Msg)
viewInspector model =
  case model.inspectorState of
    Nothing ->
      []

    Just inspectorState ->
      [ inFront <| viewModal model inspectorState ]


viewModal : Model -> InspectorState -> Element Msg
viewModal model inspectorState =
  let
      title =
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
        else
          [ viewInspectorSidebar model inspectorState
          , viewInspectorBody model inspectorState
          ]
          |> row []

      hideWhileOpening =
        alpha <| if model.animationsPending |> Set.member modalId then 0.01 else 1

      header =
        [ title
        , button [] { onPress = Just UninspectSearchResult, label = closeIcon }
        ]
        |> row [ width fill, spacing 4 ]

      sheet =
        [ header
        , bodyAndSidebar
        ]
        |> column [ htmlClass "CloseInspectorOnClickOutside", width (px <| sheetWidth model), Background.color white, centerX, moveRight (navigationDrawerWidth/2),  centerY, padding 16, spacing 16, htmlId modalId, hideWhileOpening, dialogShadow ]

      animatingBox =
        case model.modalAnimation of
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
                |> el [ whiteBackground, width (box.sx |> round |> px), height (box.sy |> round |> px), moveRight box.x, moveDown box.y, htmlClass "ModalAnimation", alpha opacity, Border.rounded 5 ]

      scrim =
        let
            opacity =
              case modalAnimationStatus model of
                Inactive ->
                  materialScrimAlpha

                Prestart ->
                  0

                Started ->
                  materialScrimAlpha
        in
            none
            |> el [ Background.color <| rgba 0 0 0 opacity, width (model.windowWidth - navigationDrawerWidth |> px), height (fill |> maximum (model.windowHeight - pageHeaderHeight)), moveDown (toFloat pageHeaderHeight), moveRight navigationDrawerWidth,  htmlClass "ModalScrim" ]
  in
      sheet
      |> el [ width fill, height fill, behindContent scrim, inFront animatingBox ]


viewInspectorBody : Model -> InspectorState -> Element Msg
viewInspectorBody model {oer, fragmentStart} =
  let
      player =
        case getYoutubeVideoId oer.url of
          Nothing ->
            if isVideoFile oer.url then
              viewHtml5VideoPlayer model oer
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
      , viewContentFlowBarWrapper model oer
      ]
      |> column [ width <| px <| playerWidth model, moveLeft inspectorSidebarWidth ]



viewDescription : Oer -> Element Msg
viewDescription oer =
  case oer.description of
    "" ->
      "No description available" |> italicText |> el [ paddingTop 30 ]

    desc ->
      desc
      |> String.split("\n")
      |> List.filter (\line -> String.length line > 2)
      |> List.map (bodyWrap [])
      |> column [ spacing 7, height fill, scrollbarY, paddingTop 30 ]


viewLinkToFile : Oer -> Element Msg
viewLinkToFile oer =
  newTabLink [] { url = oer.url, label = oer.url |> bodyWrap [] }


sheetWidth model =
  model.windowWidth - navigationDrawerWidth
  |> min (playerWidth model + inspectorSidebarWidth + 35)


viewProviderLinkAndFavoriteButton : Model -> Oer -> Element Msg
viewProviderLinkAndFavoriteButton model oer =
  let
      favoriteButton : Element Msg
      favoriteButton =
        let
            heart =
              viewHeartButton model oer.id
              |> el [ moveRight 12, moveUp 14 ]
        in
            none
            |> el [ alignRight, width <| px 34, inFront heart ]

      providerLink : Element Msg
      providerLink =
        case oer.provider of
          "" ->
            none

          provider ->
            [ "Provider:" |> bodyNoWrap []
            , newTabLink [] { url = oer.url, label = provider |> bodyNoWrap [] }
            ]
            |> row [ spacing 10 ]
  in
      [ providerLink
      , favoriteButton
      ]
      |> row [ width fill ]


viewCourseSettings : Model -> Oer -> CourseItem -> List (Element Msg)
viewCourseSettings model oer {range, comment} =
  let
      topRow =
        -- let
        --     rangeText =
        --       if (range |> Debug.log "range") == Range 0 1 then
        --         ""
        --       else
        --         [ "(Range "
        --         , range.start |> floor |> secondsToString
        --         , " - "
        --         , range.start + range.length |> floor |> secondsToString
        --         , ")"
        --         ]
        --         |> String.join ""
        -- in
            -- [ "This video has been added to your workspace." ++ rangeText |> bodyWrap [ width fill ]
            [ "This video has been added to your workspace." |> bodyWrap [ width fill ]
            , actionButtonWithIcon [] IconLeft "delete" "Remove" <| Just <| RemovedOerFromCourse oer.id
            ]
            |> row [ width fill, borderTop 1, Border.color greyDivider, paddingTop 10 ]

      commentField =
        Input.text [ width fill, htmlId "TextInputFieldForCommentOnCourseItem", onEnter <| SubmittedCourseItemComment, Border.color x5color, Font.size 14, padding 3, moveDown 5 ] { onChange = ChangedCommentTextInCourseItem oer.id, text = comment, placeholder = Just ("Enter any notes or comments about this item" |> text |> Input.placeholder [ Font.size 14, moveDown 6 ]), label = Input.labelHidden "Comment on course item" }

      changesSaved =
        if model.courseChangesSaved then
          "✓ Your changes have been saved" |> captionNowrap [ alignRight, greyText ]
        else
          none
  in
      [ topRow
      , [ changesSaved ] |> row [ width fill ]
      , commentField
      ]


viewContentFlowBarWrapper : Model -> Oer -> Element Msg
viewContentFlowBarWrapper model oer =
  let
      courseSettings =
        if isLoggedIn model then -- this feature is only available for registered users
          case getCourseItem model oer of
            Nothing ->
              [ none |> el [ width fill ]
              , actionButtonWithIcon [] IconLeft "bookmarklist_add" "Add to workspace" <| Just <| AddedOerToCourse oer.id (Range 0 oer.durationInSeconds)
              ]

            Just item ->
              viewCourseSettings model oer item
        else
          []

      components =
        if isLabStudy1 model then
          courseSettings
        else
          [ viewDescription oer ] ++ courseSettings
          -- , [ viewLinkToFile oer, viewProviderLinkAndFavoriteButton model oer ] |> column [ width fill, spacing 15, paddingTop 30 ]

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
                    viewContentFlowBar model oer wikichunks (playerWidth model) "inspector"
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
      |> column ([ width <| px <| playerWidth model, height <| px <| containerHeight, moveDown 1, paddingTop 25, spacing 4 ] ++ contentFlowBar)


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
            in
                ("Related materials"
                , sidebarContent
                )

          FeedbackTab ->
            ("Feedback"
            , if (millisSince model model.timeOfLastFeedbackRecorded) < 2000 then viewFeedbackConfirmation else viewFeedbackTab model oer
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
        [ (FeedbackTab, "Feedback")
        , (RecommendationsTab, "Related")
        ]
        |> List.map renderTab
        |> row [ width fill, paddingXY 20 0, spacing 25, Background.color x5colorDark ]

      tabContent =
        if isLoggedIn model then
          -- [ heading |> headlineWrap []
          -- , content
          [ content
          ]
          |> column [ width fill, paddingXY 20 0, spacing 25 ]
        else
          guestCallToSignup "In order to use all the features and save your changes"
          |> el [ width fill, paddingXY 15 12, Background.color <| rgb 1 0.85 0.6 ]
          |> el [ padding 20 ]
  in
      [ tabsMenu |> el [ width fill ]
      , tabContent |> el [ scrollbarY, height (fill |> maximum 510), width fill ]
      ]
      |> column [ spacing 25, width <| px inspectorSidebarWidth, height fill, alignTop, borderLeft 1, borderColorDivider, moveRight ((sheetWidth model) - inspectorSidebarWidth - 35 |> toFloat), Background.color white ]


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
  inspectorSidebarWidth - 23


viewFeedbackTab : Model -> Oer -> Element Msg
viewFeedbackTab model oer =
  let
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
        |> List.map (\option -> simpleButton [ paddingXY 9 5, Background.color feedbackOptionButtonColor, Font.size 14, whiteText ] option (Just <| SubmittedResourceFeedback oer.id (">>>"++option)))
        |> column [ spacing 10 ]

      textField =
        Input.text [ width fill, htmlId "textInputFieldForNotesOrFeedback", onEnter <| (SubmittedResourceFeedback oer.id formValue), Border.color x5color ] { onChange = ChangedTextInResourceFeedbackForm oer.id, text = formValue, placeholder = Just ("Enter your comments" |> text |> Input.placeholder [ Font.size 16 ]), label = Input.labelHidden "Your feedback about this resource" }
  in
      [ "How would you describe this material?" |> bodyWrap []
      , quickOptions
      , "Comments (optional)" |> bodyWrap []
      , textField
      ]
      |> column [ width fill, spacing 20 ]


viewFeedbackConfirmation : Element Msg
viewFeedbackConfirmation =
  [ "Thanks 😊" |> headlineWrap [ Font.size 24 ]
  , "✔ Your feedback has been recorded." |> bodyWrap []
  ]
  |> column [ spacing 30, paddingTop 200 ]
