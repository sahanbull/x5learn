module View.Shared exposing (..)

import Dict

import Html
import Html.Attributes
import Html.Events

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave)
import Json.Decode

import Model exposing (..)
import Msg exposing (..)


type alias PageWithModal = (Element Msg, List (Attribute Msg))


materialDark =
  rgba 0 0 0 0.87


materialScrimBackground =
  Background.color <| rgba 0 0 0 materialScrimAlpha


superLightBackgorund =
  Background.color <| rgb255 242 242 242


materialDarkAlpha =
  alpha 0.87


primaryWhite =
  Font.color white


x5color =
  Font.color <| rgb255 82 134 148


greyText =
  Font.color <| grey 160


greyTextDisabled =
  Font.color <| grey 180


pageHeaderHeight =
  40


paddingTop px =
  paddingEach { allSidesZero | top = px }


paddingBottom px =
  paddingEach { allSidesZero | bottom = px }


paddingLeft px =
  paddingEach { allSidesZero | left = px }


bigButtonPadding =
  paddingXY 13 10


borderBottom px =
  Border.widthEach { allSidesZero | bottom = px }


borderLeft px =
  Border.widthEach { allSidesZero | left = px }


allSidesZero =
  { top = 0
  , right = 0
  , bottom = 0
  , left = 0
  }


navLink url label =
  link [] { url = url, label = label }


wrapText attrs str =
  [ text str ] |> paragraph attrs


captionNowrap attrs str =
  text str |> el (attrs ++ [ Font.size 12 ])


bodyWrap attrs str =
  [ text str ] |> paragraph (attrs ++ [ Font.size 14 ])


bodyNoWrap attrs str =
  text str |> el ([ Font.size 14, Font.color materialDark ] ++ attrs)


subheaderWrap attrs str =
  [ text str ] |> paragraph (attrs ++ [ Font.size 16 ])


headlineWrap attrs str =
  [ text str ] |> paragraph (attrs ++ [ Font.size 24 ])


white =
  rgb 1 1 1


orange =
  rgb255 255 150 0


lightBlue =
  rgb255 10 220 255


grey80 =
  grey 80


transparentWhite =
  -- rgba 1 1 1 0.32
  rgba 1 1 1 0.4


semiTransparentWhite =
  rgba 1 1 1 0.95


grey value =
  rgb255 value value value


htmlClass name =
  Html.Attributes.class name |> htmlAttribute


htmlId name =
  Html.Attributes.id name |> htmlAttribute


whiteBackground =
  Background.color white


pageBodyBackground =
  Background.image <| imgPath "bg.jpg"


imgPath str =
  "/static/dist/img/" ++ str


svgPath str =
  "/static/dist/img_svg/" ++ str ++ ".svg"


onEnter : Msg -> Attribute Msg
onEnter msg =
  let
      isEnter code =
        if code == 13 then
          Json.Decode.succeed msg
        else
          Json.Decode.fail "not ENTER"
  in
      Html.Events.on "keydown" (Json.Decode.andThen isEnter Html.Events.keyCode)
      |> htmlAttribute


onClickNoBubble : msg -> Attribute msg
onClickNoBubble message =
  Html.Events.custom "click" (Json.Decode.succeed { message = message, stopPropagation = True, preventDefault = True })
  |> htmlAttribute


hoverCircleBackground =
  htmlClass "hoverCircleBackground"


embedYoutubePlayer youtubeId =
  Html.iframe
  [ Html.Attributes.width 720
  , Html.Attributes.height 400
  , Html.Attributes.src ("https://www.youtube.com/embed/" ++ youtubeId)
  , Html.Attributes.attribute "allowfullscreen" "allowfullscreen"
  , Html.Attributes.attribute "frameborder" "0"
  , Html.Attributes.attribute "enablejsapi" "1"
  , Html.Attributes.id "youtube-video"
  ] []
  |> html
  |> el [ paddingTop 5 ]


dialogShadow =
  Border.shadow
    { offset = (0, 20)
    , size = 0
    , blur = 60
    , color = rgba 0 0 0 0.6
    }


linkTo attrs url label =
  link attrs { url = url, label = label }


viewSearchWidget widthAttr placeholder searchInputTyping =
  let
      icon =
        image [ alpha 0.5 ] { src = (svgPath "search"), description = "search icon" }

      submitButton =
        button [ moveLeft 34, moveDown 12 ] { onPress = Just NewSearch, label = icon }
  in
      Input.text [ width fill, Input.focusedOnLoad, onEnter NewSearch ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just (placeholder |> text |> Input.placeholder []), label = Input.labelHidden "search" }
      |> el [ width widthAttr, centerX, onRight submitButton ]


svgIcon stub=
  image [ materialDarkAlpha ] { src = svgPath stub, description = "" }


navigationDrawerWidth =
  230


actionButton svgIconStub str onPress =
  let
      label =
        [ image [ alpha 0.5 ] { src = svgPath svgIconStub, description = "" }
        , str |> bodyNoWrap [ width fill ]
        ]
        |> row [ width fill, padding 12, spacing 3, Border.rounded 4 ]
  in
      button [] { onPress = onPress, label = label }


selectByIndex : Int -> a -> List a -> a
selectByIndex index fallback elements =
  elements
  |> List.drop (index |> modBy (List.length elements))
  |> List.head
  |> Maybe.withDefault fallback


domainOnly : String -> String
domainOnly url =
  url |> String.split "//" |> List.drop 1 |> List.head |> Maybe.withDefault url |> String.split "/" |> List.head |> Maybe.withDefault url


materialScrimAlpha =
  0.32


viewOerCard model oer =
  let
      hovering =
        model.hoveringOerUrl == Just oer.url

      upperImage attrs url =
        none
        |> el ([ width fill, height (px 175), Background.image <| url, htmlClass (if isFromVideoLecturesNet oer then "materialHoverZoomThumb-videolectures" else "materialHoverZoomThumb") ] ++ attrs)

      imageCounter txt =
        txt
        |> text
        |> el [ paddingXY 5 3, Font.size 12, primaryWhite, Background.color <| rgba 0 0 0 0.5, moveDown 157 ]
        |> inFront

      thumbnail =
        let
            attrs =
              case oer.imageUrls of
                first :: (second :: _) ->
                  [ preloadImage second ]

                _ ->
                  if hovering then [] else []
        in
            oer.imageUrls |> List.head |> Maybe.withDefault (imgPath "thumbnail_unavailable.jpg")
            |> upperImage attrs

      fragmentsBar =
        let
            fragments =
              model.viewedFragments
              |> Maybe.withDefault []
              |> List.filter (\fragment -> fragment.oer == oer)

            pxFromFraction fraction =
              (cardWidth |> toFloat) * fraction

            markers =
              fragments
              |> List.map (\{start,length} -> none |> el [ width (length |> pxFromFraction |> round |> px), height fill, Background.color <| rgb255 0 190 250, moveRight (start |> pxFromFraction) ] |> inFront)

            chunkTrigger chunk =
              let
                  chunkMenu =
                    ChunkOnCard oer chunk

                  popmenu =
                    if model.menuPath |> isHeadEqual chunkMenu then
                      let
                          actionsForTopic =
                            [ "What is this?" |> menuButtonDisabled
                            , "I know this well" |> menuButtonDisabled
                            -- , "Test me later" |> menuButtonDisabled
                            -- , "Test me now" |> menuButtonDisabled
                            ]

                          topicsSection =
                            if chunk.topics |> List.isEmpty |> not then
                              chunk.topics
                              |> List.map (\topic -> menuButtonWithSubmenu model [ chunkMenu ] [ chunkMenu, TopicInChunkOnCard topic ] actionsForTopic topic)
                              |> column [ width fill ]
                              |> List.singleton
                            else
                              []
                      in
                          [ "→ Jump here" |> menuButtonDisabled
                          ] ++ topicsSection
                          |> menuColumn
                          |> inFront
                          |> List.singleton
                    else
                      []

                  background =
                    if popmenu == [] then
                      []
                    else
                      [ Background.color <| lightBlue ]
              in
                  none
                  |> el ([ width <| fillPortion (chunk.length * 100 |> round), height fill, borderLeft 1, Border.color <| rgba 0 0 0 0.2, setMenuPathOnMouseEnter [ chunkMenu ] ] ++ background ++ popmenu)

            chunkTriggers =
              model.oerChunks
              |> Dict.get oer.url
              |> Maybe.withDefault []
              |> List.map chunkTrigger
              |> row [ width fill, height fill ]
              |> inFront

            underlay =
              none
              |> el ([ width fill, height (px 16), materialScrimBackground, moveUp 16, setMenuPathOnMouseLeave [] ] ++ markers ++ [chunkTriggers])
        in
            underlay


      preloadImage url =
        url
        |> upperImage [ width (px 1), alpha 0.01 ]
        |> behindContent

      carousel =
        case oer.imageUrls of
          [] ->
            thumbnail

          [ _ ] ->
            thumbnail

          head :: rest ->
            let
                imageIndex =
                  (millisSince model model.timeOfLastMouseEnterOnCard) // 1500 + 1
                  |> modBy (List.length oer.imageUrls)

                currentImageUrl =
                  oer.imageUrls
                  |> selectByIndex imageIndex head

                nextImageUrl =
                  oer.imageUrls
                  |> selectByIndex (imageIndex+1) head

                -- dot url =
                --   none
                --   |> el [ width (px 6), height (px 6), Border.rounded 3, Background.color <| if url==currentImageUrl then white else semiTransparentWhite ]

                -- dotRow =
                --   oer.imageUrls
                --   |> List.map dot
                --   |> row [ spacing 5, moveDown 160, moveRight 16 ]
                --   |> inFront

            in
                currentImageUrl
                |> upperImage [ preloadImage nextImageUrl, imageCounter <| (imageIndex+1 |> String.fromInt) ++ " / " ++ (oer.imageUrls |> List.length |> String.fromInt) ]

      title =
        oer.title |> subheaderWrap [ height (fill |> maximum 64), clipY ]

      modalityIcon =
        if hasVideo oer then
          image [ moveRight 280, moveUp 50, width (px 30) ] { src = svgPath "playIcon", description = "play icon" }
        else
          none
        -- let
        --     stub =
        --       if hasVideo oer then
        --         "playIcon"
        --       else
        --         "textIcon"
        -- in
        --     image [ moveRight 280, moveDown 160, width (px 30) ] { src = svgPath stub, description = "play icon" }

      bottomRow =
        let
            content =
              if oer.duration=="" then
                [ oer.provider |> domainOnly |> captionNowrap []
                , oer.date |> captionNowrap [ alignRight ]
                ]
              else
                [ oer.date |> captionNowrap []
                , oer.provider |> domainOnly |> captionNowrap [ centerX ]
                , oer.duration |> captionNowrap [ alignRight ]
                ]
        in
            content
            |> row [ width fill ]

      info =
        [ title
        , bottomRow
        ]
        |> column [ padding 16, width fill, height fill, inFront modalityIcon, inFront fragmentsBar ]

      closeButton =
        if hovering then
          button [ alignRight ] { onPress = Nothing, label = closeIcon }
        else
          none

      widthOfCard =
        width (px cardWidth)

      heightOfCard =
        height (px 280)

      card =
        [ (if hovering then carousel else thumbnail)
        , info
        ]
        |> column [ widthOfCard, heightOfCard, htmlClass "materialCard", onMouseEnter (SetHover (Just oer.url)), onMouseLeave (SetHover Nothing) ]

      onPress =
        case model.inspectorState of
          Nothing ->
            Just (InspectSearchResult oer)

          _ ->
            Nothing
  in
      none
      |> el [ widthOfCard, heightOfCard, inFront <| button [] { onPress = onPress, label = card }, inFront closeButton ]


cardWidth =
  332


viewPlaylist model playlist =
  if playlist.oers |> List.isEmpty then
    none
  else
    [ playlist.title |> headlineWrap []
    , playlist.oers |> List.map (viewOerCard model) |> row [ spacing 20 ]
    ]
    |> column [ spacing 20, padding 20, width fill, Background.color transparentWhite, Border.rounded 2 ]


milkyWhiteCenteredContainer =
  el [ centerX, padding 20, Background.color semiTransparentWhite, Border.rounded 2 ]


closeIcon =
  image [  materialDarkAlpha, hoverCircleBackground] { src = svgPath "close", description = "close" }


viewCenterNote str =
  str
  |> bodyWrap []
  |> milkyWhiteCenteredContainer


viewLoadingSpinner =
  "loading..." |> wrapText [ primaryWhite, centerX, centerY ]
  |> el [ centerX, height fill ]
  |> el [ width fill, height fill ]


menuButtonDisabled str =
  let
      label =
        -- [ str |> bodyNoWrap [ width fill, greyTextDisabled ]
        [ str |> bodyNoWrap [ width fill ]
        ]
        |> row [ width fill, paddingXY 10 5, spacing 3 ]
  in
      button [ padding 5 ] { onPress = Nothing, label = label }


menuButtonWithSubmenu model parentMenuPath submenuPath submenuContents title =
  let
      label =
        [ title |> bodyNoWrap [ width fill ]
        , image [ alpha 0.5, alignRight ] { src = svgPath "arrow_right", description = "" }
        ]
        |> row [ width fill, paddingXY 10 5, spacing 10 ]

      submenu =
        if model.menuPath |> containsList submenuPath then
          submenuContents
          |> menuColumn
          |> el [ moveUp 20, moveRight 30, elevate 4 ]
          |> onRight
          |> List.singleton
        else
          []

      background =
        if submenu == [] then
          []
        else
          [ superLightBackgorund ]
  in
      button ([ padding 5, width fill, setMenuPathOnMouseEnter submenuPath, setMenuPathOnMouseLeave parentMenuPath ]++submenu++background) { onPress = Nothing, label = label }


isHeadEqual : a -> List a -> Bool
isHeadEqual element xs =
  case List.head xs of
    Nothing ->
      False

    Just x ->
      x == element


setMenuPathOnMouseEnter path =
  onMouseEnter (SetPopMenuPath path)


setMenuPathOnMouseLeave path =
  onMouseLeave (SetPopMenuPath path)


menuColumn =
  column [ Background.color white, moveDown 16, moveLeft 30, Border.rounded 4, Border.color <| grey80, dialogShadow ]


ensureTail : a -> List a -> List a
ensureTail element xs =
  xs
  |> cutBefore element
  |> addToEnd element


cutBefore : a -> List a -> List a
cutBefore element xs =
  if xs |> List.member element then
    xs
    |> List.reverse
    |> List.drop 1
    |> List.reverse
    |> cutBefore element
  else
    xs


addToEnd : a -> List a -> List a
addToEnd element xs =
    element :: (List.reverse xs) |> List.reverse


containsList : List a -> List a -> Bool
containsList xs ostensiblyLongerList =
  xs
  |> List.all (\x -> ostensiblyLongerList |> List.member x)


elevate zIndex =
  htmlAttribute <| Html.Attributes.attribute "z-index" (String.fromInt zIndex)
