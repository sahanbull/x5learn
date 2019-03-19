module View.Shared exposing (..)

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
import Dict

import Model exposing (..)
import Msg exposing (..)
import Animation exposing (..)

type alias PageWithModal = (Element Msg, List (Attribute Msg))

type IconPosition
  = IconLeft
  | IconRight


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


yellow =
  rgb255 245 220 0


orange =
  rgb255 255 120 0


historyBlue =
  rgb255 0 190 250


grey80 =
  grey 80


transparentWhite =
  -- rgba 1 1 1 0.32
  rgba 1 1 1 0.4


semiTransparentWhite =
  rgba 1 1 1 0.95


semiTransparent =
  alpha 0.5


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


-- NB: stopPropagation should be avoided, see https://css-tricks.com/dangers-stopping-event-propagation/
onClickNoBubble : msg -> Attribute msg
onClickNoBubble message =
  Html.Events.custom "click" (Json.Decode.succeed { message = message, stopPropagation = True, preventDefault = True })
  |> htmlAttribute


hoverCircleBackground =
  htmlClass "hoverCircleBackground"


embedYoutubePlayer youtubeId =
  Html.iframe
  [ Html.Attributes.width playerWidth
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


viewSearchWidget model widthAttr placeholder searchInputTyping =
  let
      icon =
        image [ semiTransparent ] { src = (svgPath "search"), description = "search icon" }
        |> el [ moveLeft 34, moveDown 12 ]

      searchField =
        Input.text [ htmlId "SearchField", width fill, Input.focusedOnLoad, onEnter <| TriggerSearch searchInputTyping ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just (placeholder |> text |> Input.placeholder []), label = Input.labelHidden "search" }
        |> el [ width widthAttr, onRight icon, centerX, below suggestions ]

      suggestions =
        if List.isEmpty model.searchSuggestions || String.length searchInputTyping < 2 then
          none
        else
          model.searchSuggestions
          |> List.map (\suggestion -> actionButtonWithoutIcon [ width fill, clipX ] suggestion (Just <| TriggerSearch suggestion))
          |> menuColumn [ width fill, scrollbarY ]
          |> el [ width fill, height <| px 196 ]
  in
      searchField


svgIcon stub=
  image [ materialDarkAlpha ] { src = svgPath stub, description = "" }


navigationDrawerWidth =
  230


actionButtonWithIcon iconPosition svgIconStub str onPress =
  let
      icon =
        image [ alpha 0.5 ] { src = svgPath svgIconStub, description = "" }

      title =
        str |> bodyNoWrap [ width fill ]

      label =
        case iconPosition of
          IconLeft ->
            [ icon, title ]

          IconRight ->
            [ title, icon ]
  in
      button [] { onPress = onPress, label = label |> row [ width fill, padding 12, spacing 3, Border.rounded 4 ]}


actionButtonWithoutIcon attrs str onPress =
  let
      label =
        str |> bodyNoWrap [ width fill, padding 12, spacing 3, Border.rounded 4 ]
  in
      button attrs { onPress = onPress, label = label }


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


playerWidth =
  720


milkyWhiteCenteredContainer =
  el [ centerX, centerY, padding 20, Background.color semiTransparentWhite, Border.rounded 2 ]


closeIcon =
  image [  materialDarkAlpha, hoverCircleBackground] { src = svgPath "close", description = "close" }


viewCenterNote str =
  str
  |> bodyWrap []
  |> milkyWhiteCenteredContainer


viewLoadingSpinner =
  "loading..." |> viewCenterNote


menuButtonDisabled str =
  let
      label =
        -- [ str |> bodyNoWrap [ width fill, greyTextDisabled ]
        [ str |> bodyNoWrap [ width fill ]
        ]
        |> row [ width fill, paddingXY 10 5, spacing 3 ]
  in
      button [ width fill, padding 5 ] { onPress = Nothing, label = label }


popupOnMouseEnter popup =
  onMouseEnter (SetPopup popup)


closePopupOnMouseLeave =
  onMouseLeave ClosePopup


menuColumn attrs =
  column ([ Background.color white, Border.rounded 4, Border.color <| grey80, dialogShadow ] ++ attrs)


viewFragmentsBar model oer recommendedFragments barWidth barId =
  let
      markers =
        [ fragmentMarkers (model.viewedFragments |> Maybe.withDefault []) historyBlue
        , fragmentMarkers recommendedFragments yellow
        ]
        |> List.concat

      fragmentMarkers fragments color =
        fragments
        |> List.filter (\fragment -> fragment.oer == oer)
        |> List.map (\{start,length} -> none |> el [ width (length |> pxFromFraction |> round |> px), height fill, Background.color color, moveRight (start |> pxFromFraction) ] |> inFront)

      pxFromFraction fraction =
        (barWidth |> toFloat) * fraction

      chunkTrigger chunk =
        let
            chunkPopup =
              let
                  entityPopup =
                    case model.popup of
                      Nothing ->
                        Nothing

                      Just (ChunkOnBar p) ->
                        p.entityPopup
              in
                  { barId = barId, oer = oer, chunk = chunk, entityPopup = entityPopup }

            isPopupOpen =
              case model.popup of
                Nothing ->
                  False

                Just (ChunkOnBar p) ->
                  barId == p.barId && chunk == p.chunk

            containsSearchString =
              case model.searchState of
                Nothing ->
                  False

                Just searchState ->
                  let
                      searchStringLowercase =
                        searchState.lastSearch |> String.toLower
                  in
                      chunk.entities
                      |> List.map .title
                      |> List.any (\title -> String.contains searchStringLowercase (title |> String.toLower))

            background =
              if isPopupOpen then
                [ Background.color <| orange ]
              else if containsSearchString then
                [ Background.color <| yellow ]
              else
                []

            popup =
              if isPopupOpen then
                 [ viewChunkPopup model chunkPopup |> inFront ]
              else
                []
        in
            none
            |> el ([ width <| px <| floor <| chunk.length * (toFloat barWidth) + 1, height fill, moveRight <| chunk.start * (toFloat barWidth), borderLeft 1, Border.color <| rgba 0 0 0 0.2, popupOnMouseEnter (ChunkOnBar chunkPopup), closePopupOnMouseLeave ] ++ background ++ popup )
            |> inFront

      chunkTriggers =
        oer.wikichunks
        |> List.map chunkTrigger

      underlay =
        none
        |> el ([ width fill, height (px fragmentsBarHeight), materialScrimBackground, moveUp fragmentsBarHeight ] ++ markers ++ chunkTriggers)
  in
      underlay


viewChunkPopup model popup =
  let
      entitiesSection =
        if popup.chunk.entities |> List.isEmpty then
          [ "No data available" |> text ]
        else
          popup.chunk.entities
          |> List.map (viewEntityButton model popup)
          |> column [ width fill ]
          |> List.singleton
  in
      entitiesSection
      |> menuColumn []
      |> el [ moveLeft 30, moveDown fragmentsBarHeight ]


viewEntityButton : Model -> ChunkPopup -> Entity -> Element Msg
viewEntityButton model chunkPopup entity =
    let
        label =
          [ entity.title |> bodyNoWrap [ width fill ]
          , image [ alpha 0.5, alignRight ] { src = svgPath "arrow_right", description = "" }
          ]
          |> row [ width fill, paddingXY 10 5, spacing 10 ]

        backgroundAndSubmenu =
          case chunkPopup.entityPopup of
            Nothing ->
              []

            Just entityPopup ->
              -- if chunkPopup.chunk == chunk && entityPopup.entityId == entityId then
              if entityPopup.entityId == entity.id then
                superLightBackgorund :: (viewEntityPopup model chunkPopup entityPopup entity.title)
              else
                []

        floatingDefinition =
          case model.floatingDefinition of
            Nothing ->
              []

            Just id ->
              if id == entity.id then
                [ viewFloatingDefinition model entity ]
              else
                []
    in
        button ([ onClickNoBubble NoOp, padding 5, width fill, popupOnMouseEnter (ChunkOnBar { chunkPopup | entityPopup = Just { entityId = entity.id, hoveringAction = Nothing } }) ] ++ backgroundAndSubmenu ++ floatingDefinition) { onPress = Nothing, label = label }


viewEntityPopup model chunkPopup entityPopup entityTitle =
  [ ("Define", ShowFloatingDefinition (entityPopup.entityId))
  , ("Search", TriggerSearch entityTitle)
  , ("Share", ClosePopup)
  , ("Bookmark", ClosePopup)
  , ("Add to interests", ClosePopup)
  , ("Mark as known", ClosePopup)
  ]
  |> List.map (entityActionButton chunkPopup entityPopup)
  |> menuColumn []
  |> onRight
  |> List.singleton


entityActionButton chunkPopup entityPopup (title, clickAction) =
  let
      hoverAction =
        popupOnMouseEnter <| ChunkOnBar { chunkPopup | entityPopup = Just { entityPopup | hoveringAction = Just title } }

      background =
        if entityPopup.hoveringAction == Just title then
          [ superLightBackgorund, width fill ]
        else
          []

      attrs =
        hoverAction :: ([ width fill ] ++ background)
  in
      actionButtonWithoutIcon attrs title (Just clickAction)
  -- let
      -- onHover =
      --   popupOnMouseEnter <| ChunkOnBar { chunkPopup | entityPopup = Just { entityPopup | hoveringAction = True } }

      -- popup =
      --   if entityPopup.hoveringAction then
      --     [ [ menuButtonDisabled "(Definition goes here)" ] |> menuColumn |> el [ moveUp 0, moveRight 0 ] |> onRight ]
      --   else
      --     []
  -- in
  --     onHover :: popup


viewFloatingDefinition model entity =
  let
      blurb =
        case model.entityDescriptions |> Dict.get entity.id of
          Nothing ->
            "(Description unavailable)"
            |> captionNowrap []

          Just description ->
            ("“" ++ description ++ "”")
            |> bodyWrap [ Font.italic ]

      link =
        newTabLink [] { url = entity.url, label = "Find on Wikipedia" |> bodyNoWrap [] }
        -- "(Wikidata)"
        -- |> bodyWrap [ alignRight ]
        -- |> el [ width fill, alignRight ]
  in
      [ blurb, link ]
      |> menuColumn [ width (px 240), padding 10, spacing 16 ]
      |> el [ width (fill |> maximum 200), moveDown 10, moveRight 80 ]
      |> onRight


fragmentsBarHeight = 16
