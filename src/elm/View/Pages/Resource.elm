module View.Pages.Resource exposing (viewResourcePage)

import Url
import Dict
import Set
import List.Extra

import Html
import Html.Attributes as Attributes exposing (style)

import Element exposing (..)
import Element.Input as Input exposing (button)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font
import Element.Keyed as Keyed

import Model exposing (..)
import View.Shared exposing (..)
import View.FragmentsBar exposing (..)
-- import View.Noteboard exposing (..)
import View.Html5VideoPlayer exposing (..)
import View.HtmlPdfViewer exposing (..)


import Msg exposing (..)

import Json.Decode as Decode


viewResourcePage : Model -> PageWithModal
viewResourcePage model =
  let
      page =
        case model.currentResource of
          Nothing ->
            viewLoadingSpinner

          Just (Loaded oerId) ->
            case model.cachedOers |> Dict.get oerId of
              Nothing ->
                viewCenterNote "The requested resource was not found."

              Just oer ->
                viewResource model oer

          Just Error ->
            viewCenterNote "The requested resource was not found."
  in
      (page, [])


viewResource : Model -> Oer -> Element Msg -- TODO remove some code duplication with Inspector.elm
viewResource model oer =
  let
      header =
        case oer.title of
          "" ->
            "Title unavailable" |> headlineWrap [ Font.italic ]

          title ->
            title |> headlineWrap []

      linkToFile =
        newTabLink [] { url = oer.url, label = oer.url |> bodyWrap [] }

      player =
        case getYoutubeVideoId oer.url of
          Nothing ->
            if isVideoFile oer.url then
              viewHtml5VideoPlayer model oer.url
            else if isPdfFile oer.url then
              viewHtmlPdfPlayer oer.url "60vh"
            else
              none

          Just youtubeId ->
            let
                startTime =
                  0
            in
                embedYoutubePlayer youtubeId startTime

      description =
        case oer.description of
          "" ->
            "No description available" |> italicText |> el [ paddingTop 30 ]

          desc ->
            desc
            |> String.split("\n")
            |> List.filter (\line -> String.length line > 2)
            |> List.map (bodyWrap [])
            |> column [ spacing 7, height fill, scrollbarY, paddingTop 30 ]

      mainSection =
        let
            horizontalPadding =
              if model.windowWidth < 1300 then
                20
              else
                50
        in
            [ header |> el [ paddingBottom 20 ]
            , player
            , fragmentsBarWrapper
            ]
            |> List.indexedMap (\index e -> (oer.url ++ (String.fromInt index), e))
            |> Keyed.column [ width fill, moveLeft (sidebarWidth model |> toFloat), Background.color <| grey 230, height fill, borderLeft 1, borderColorDivider, paddingXY horizontalPadding 30, scrollbarY ]

      sidebar =
        let
            (heading, content) =
              case model.resourceSidebarTab of
                RecommendationsTab ->
                  let
                      sidebarContent =
                        case model.resourceRecommendations of
                          [] ->
                            viewLoadingSpinner
                            |> el [ moveDown 80, width fill ]

                          recommendations ->
                            model.resourceRecommendations
                            |> List.map (viewRecommendationCard model)
                            |> column [ spacing 12 ]
                  in
                      ("Related material"
                      , sidebarContent
                      )

                FeedbackTab ->
                  ("Feedback"
                  , if (millisSince model model.timeOfLastFeedbackRecorded) < 2000 then viewFeedbackConfirmation else viewFeedbackTab model oer
                  )

            renderTab (tab, title) =
              let
                  isCurrent =
                    model.resourceSidebarTab==tab

                  (textColor, borderColor) =
                    if isCurrent then
                      (Font.color white, Border.color white)
                    else
                      (greyTextDisabled, Border.color fullyTransparentColor)
              in
                  simpleButton [ Font.size 16, paddingXY 1 20, borderBottom 4, centerX, borderColor, textColor ] title (Just <| SelectResourceSidebarTab tab oer.id)

            tabsMenu =
              [ (RecommendationsTab, "Recommendations")
              , (FeedbackTab, "Feedback")
              ]
              |> List.map renderTab
              |> row [ width fill, paddingXY 20 0, spacing 25, Background.color x5colorDark ]

            tabContent =
              if isLoggedIn model then
                [ heading |> headlineWrap []
                , content
                ]
                |> column [ width fill, padding 20, spacing 25 ]
              else
                guestCallToSignup "In order to use all the features and save your changes"
                |> el [ width fill, paddingXY 15 12, Background.color <| rgb 1 0.85 0.6 ]
                |> el [ padding 20 ]
        in
            [ tabsMenu |> el [ width fill ]
            , tabContent
            ]
            |> column [ spacing 25, width <| px (sidebarWidth model), height fill, alignTop, borderLeft 1, borderColorDivider, moveRight ((sheetWidth model) - (sidebarWidth model) |> toFloat), Background.color white ]

      body =
        [ sidebar
        , mainSection
        ]
        |> row [ height fill, width fill ]

      footer =
        []

      fragmentsBarWrapper =
        let
            (x, y) =
              -- if isVideoFile oer.url || hasYoutubeVideo oer.url then
              if hasYoutubeVideo oer.url then
                (px playerWidth, px fragmentsBarWrapperHeight)
              else
                (fill, fill)
        in
            [ description
            , [ providerLink, linkToFile ] |> column [ width fill, spacing 15, paddingTop 30 ]
            , fragmentsBar
            ]
            |> column [ width x, height y, moveDown 1 ]

      fragmentsBar =
        if oer.mediatype=="video" then
          case chunksFromOerId model oer.id of
            [] ->
              none

            wikichunks ->
              let
                  content =
                    viewFragmentsBar model oer wikichunks playerWidth "inspector"
                    |> el [ width (px playerWidth), height (px 16) ]
              in
                  none |> el [ inFront content, moveUp (fragmentsBarWrapperHeight - fragmentsBarHeight) ]
        else
          none

      providerLink =
        case oer.provider of
          "" ->
            none

          provider ->
            [ "Provider:" |> bodyNoWrap []
            , newTabLink [] { url = oer.url, label = provider |> trimTailingEllipsisIfNeeded |> bodyNoWrap [] }
            ]
            |> row [ spacing 10 ]
  in
      body


sidebarWidth model =
  460
  |> min (model.windowWidth - navigationDrawerWidth - playerWidth - 100)


fragmentsBarWrapperHeight =
  200


sheetWidth model =
  model.windowWidth - navigationDrawerWidth


viewRecommendationCard : Model -> Oer -> Element Msg
viewRecommendationCard model oer =
  let
      title =
        -- |> subSubheaderNoWrap [ paddingXY 16 10, htmlClass "ClipEllipsis", width <| px (recommendationCardWidth - 52) ]
        [ oer.title |> Html.text ]
        |> Html.div [ style "width" (((recommendationCardWidth model) - 32 |> String.fromInt)++"px"), style "font-size" "16px", Attributes.class "ClipEllipsis" ]
        |> html
        |> el []

      -- modalityIcon =
      --   if hasYoutubeVideo oer.url then
      --     image [ moveRight 280, moveUp 50, width (px 30) ] { src = svgPath "playIcon", description = "play icon" }
      --   else
      --     none

      bottomInfo =
        let
            dateStr =
              if oer.date |> String.startsWith "Published on " then oer.date |> String.dropLeft ("Published on " |> String.length) else oer.date

            date =
              dateStr |> captionNowrap [ alignLeft ]

            provider =
              oer.provider |> domainOnly |> truncateSentence 24 |> captionNowrap [ if dateStr=="" then alignLeft else centerX ]

            duration =
              oer.duration |> captionNowrap [ alignRight ]

            content =
              [ date, provider, duration ]
        in
            content
            |> row [ width fill, height fill, alignBottom ]

      widthOfCard =
        width (px (recommendationCardWidth model))

      heightOfCard =
        height (px recommendationCardHeight)
  in
      [ title, bottomInfo ]
      |> column [ widthOfCard, heightOfCard, paddingXY 15 12, spacing 15, htmlClass "materialCard" ]
      |> linkTo [] (resourceUrlPath oer.id)


recommendationCardHeight =
  80


recommendationCardWidth model =
  sidebarWidth model - 50


viewFeedbackTab model oer =
  let
      formValue =
        getResourceFeedbackFormValue model oer.id

      quickOptions =
        ([ "Inspiring"
        , "Boring"
        , "Up-to-date"
        , "Outdated"
        , "Well explained"
        , "Incomprehensible"
        , "Factually inaccurate"
        , "Inappropriate"
        , "Poor text quality"
        , "Poor visual quality"
        ] ++ (if isVideoFile oer.url || hasYoutubeVideo oer.url then [ "Poor audio quality" ] else []))
        |> List.map (\option -> simpleButton [ paddingXY 9 5, Background.color feedbackOptionButtonColor, Font.size 14, whiteText ] option (Just <| SubmittedResourceFeedback oer.id (">>>"++option)))
        |> column [ spacing 10 ]

      textField =
        Input.text [ width fill, htmlId "textInputFieldForNotesOrFeedback", onEnter <| (SubmittedResourceFeedback oer.id formValue), Border.color x5color ] { onChange = ChangedTextInResourceFeedbackForm oer.id, text = formValue, placeholder = Just ("Let us know" |> text |> Input.placeholder [ Font.size 16 ]), label = Input.labelHidden "Your feedback about this resource" }
  in
      [ "Any comments about this material?" |> bodyWrap []
      , quickOptions
      , "Other" |> bodyWrap []
      , textField
      -- , "[ submit button goes here ]" |> bodyWrap [ greyTextDisabled ]
      ]
      |> column [ width fill, spacing 20 ]


viewFeedbackConfirmation =
  [ "Thanks 😊" |> headlineWrap [ Font.size 24 ]
  , "✔ Your feedback has been recorded." |> bodyWrap []
  ]
  |> column [ spacing 30, paddingTop 200 ]
