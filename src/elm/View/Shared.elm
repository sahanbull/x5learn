module View.Shared exposing (..)

import Html
import Html.Attributes
import Html.Events

import Time exposing (Posix, millisToPosix, posixToMillis)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Element.Events as Events exposing (onClick, onMouseEnter, onMouseLeave, onFocus)
import Json.Decode
import Json.Encode
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


superLightBackground =
  Background.color <| rgb255 242 242 242


materialDarkAlpha =
  alpha 0.87


whiteText =
  Font.color white


x5color =
  rgb255 82 134 148


x5colorSemiTransparent =
  rgba255 82 134 148 0.3


x5colorDark =
  rgb255 38 63 71


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


paddingTRBL t r b l =
  paddingEach { top = t, right = r, bottom = b, left = l }


bigButtonPadding =
  paddingXY 13 10


borderTop px =
  Border.widthEach { allSidesZero | top = px }


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


wrapText attrs str =
  [ text str ] |> paragraph attrs


captionNowrap attrs str =
  text str |> el ([ Font.size 12 ] ++ attrs)


bodyWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 14 ] ++ attrs)


bodyNoWrap attrs str =
  text str |> el ([ Font.size 14, Font.color materialDark ] ++ attrs)


subSubheaderWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 18 ] ++ attrs)


subheaderWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 21 ] ++ attrs)


headlineWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 24 ] ++ attrs)


italicText =
  bodyWrap [ Font.italic ]


white =
  rgb 1 1 1


yellow =
  rgb255 245 220 0


orange =
  rgb255 255 120 0


recentBlue =
  rgb255 0 190 250


grey80 =
  grey 80


greyMedium =
  grey 160


veryTransparentWhite =
  rgba 1 1 1 0.25


transparentWhite =
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


embedYoutubePlayer youtubeId startTime =
  none
  |> el [ htmlId "player", width (px playerWidth), height (px 410) ]


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
      submit =
        TriggerSearch searchInputTyping

      submitButton =
        let
            icon =
              image [ semiTransparent ] { src = (svgPath "search"), description = "search" }
        in
            button [ moveLeft 45, moveDown 1, width (px 45), height (px 45) ] { onPress = Just submit, label = icon }

      searchField =
        Input.text [ htmlId "SearchField", width fill, Input.focusedOnLoad, onEnter <| submit ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just (placeholder |> text |> Input.placeholder []), label = Input.labelHidden "search" }
        |> el [ width widthAttr, onRight submitButton, centerX, below suggestions ]

      suggestionButton str =
        let
            label =
              str |> bodyNoWrap [ width fill, padding 12, spacing 3, Border.rounded 4 ]

            background =
              if str == model.selectedSuggestion then
                [ superLightBackground ]
              else
                []

            mouseEnterHandler =
              if model.suggestionSelectionOnHoverEnabled then
                [ onMouseEnter <| SelectSuggestion str ]
              else
                []
        in
            button ([ width fill, clipX, onFocus <| SelectSuggestion str ]++background++mouseEnterHandler) { onPress = Just <| TriggerSearch str, label = label }

      suggestions =
        if List.isEmpty model.searchSuggestions || String.length searchInputTyping < 2 then
          none
        else
          model.searchSuggestions
          |> List.map (\suggestion -> suggestionButton suggestion)
          |> menuColumn [ width fill, clipY, height <| px (39*7) ]
          |> el [ width fill, htmlId "SearchSuggestions" ]
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


actionButtonWithoutIcon : List (Attribute Msg) -> String -> Maybe Msg -> Element Msg
actionButtonWithoutIcon attrs str onPress =
  let
      label =
        str |> bodyNoWrap []
  in
      button attrs { onPress = onPress, label = label }


confirmButton : List (Attribute Msg) -> String -> Maybe Msg -> Element Msg
confirmButton attrs str onPress =
  let
      label =
        str |> bodyNoWrap [ Background.color x5color, bigButtonPadding, whiteText ]
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
  image [  materialDarkAlpha, hoverCircleBackground ] { src = svgPath "close", description = "close" }


trashIcon =
  image [  materialDarkAlpha, hoverCircleBackground, width <| px 30 ] { src = svgPath "delete", description = "delete" }


viewCenterNote str =
  str
  |> bodyWrap []
  |> milkyWhiteCenteredContainer


viewLoadingSpinner =
  none
  |> el [ htmlClass "loader", centerX, centerY ]
  |> el [ centerX, centerY ]


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


viewFragmentsBar model userState oer chunks recommendedFragments barWidth barId darkBackground =
  let
      markers =
        -- [ fragmentMarkers (userState.fragmentAccesses |> Dict.values) recentBlue
        [ fragmentMarkers recommendedFragments yellow
        ]
        |> List.concat

      fragmentMarkers fragments color =
        fragments
        |> List.filter (\fragment -> fragment.oerUrl == oer.url)
        |> List.map (\{start,length} -> none |> el [ width (length |> pxFromFraction |> round |> px), height fill, Background.color color, moveRight (start |> pxFromFraction) ] |> inFront)

      pxFromFraction fraction =
        (barWidth |> toFloat) * fraction

      chunkTrigger chunkIndex chunk =
        let
            chunkPopup =
              let
                  entityPopup =
                    case model.popup of
                      Just (ChunkOnBar p) ->
                        p.entityPopup

                      _ ->
                        Nothing
              in
                  { barId = barId, oer = oer, chunk = chunk, entityPopup = entityPopup }

            isPopupOpen =
              case model.popup of
                Just (ChunkOnBar p) ->
                  barId == p.barId && chunk == p.chunk

                _ ->
                  False

            -- bump =
            --   case model.hoveringBubbleEntityId of
            --     Nothing ->
            --       []

            --     Just entityId ->
            --       if isPopupOpen || (anyMentionsOfEntityInThisChunk entityId) then
            --         []
            --       else if chunk.entities |> List.map .id |> List.member entityId then
            --         image [ alpha 0.9, centerX, height <| px 12, moveDown 2 ] { src = svgPath "white_semicircle", description = "" }
            --         |> el [ width fill ]
            --         |> inFront
            --         |> List.singleton
            --       else
            --         []

            -- anyMentionsOfEntityInThisChunk entityId =
            --   entityId
            --   |> mentionsInThisChunk
            --   |> List.any (\mention -> mention.chunkIndex==chunkIndex)

            chunkBackground =
              if isPopupOpen then
                [ Background.color orange ]
              else
                []

            popup =
              if isPopupOpen then
                 [ viewChunkPopup model chunkPopup |> inFront ]
              else
                []

            clickHandler =
              case model.inspectorState of
                Nothing ->
                  [ onClickNoBubble <| InspectOer oer chunk.start chunk.length True ]

                _ ->
                  if hasYoutubeVideo oer.url then
                    [ onClickNoBubble <| YoutubeSeekTo chunk.start ]
                  else
                    []

            chunkWidth =
              floor <| chunk.length * (toFloat barWidth) + 1
        in
            none
            -- |> el ([ htmlClass "ChunkTrigger", width <| px <| chunkWidth, height fill, moveRight <| chunk.start * (toFloat barWidth), borderLeft 1, Border.color <| rgba 0 0 0 0.2, popupOnMouseEnter (ChunkOnBar chunkPopup), closePopupOnMouseLeave ] ++ background ++ popup ++ clickHandler)
            |> el ([ htmlClass "ChunkTrigger", width <| px <| chunkWidth, height fill, moveRight <| chunk.start * (toFloat barWidth), popupOnMouseEnter (ChunkOnBar chunkPopup), closePopupOnMouseLeave ] ++ chunkBackground ++ popup ++ clickHandler)
            |> inFront

      chunkTriggers =
        chunks
        |> List.indexedMap chunkTrigger

      border =
        [ none |> el [ width fill , Background.color veryTransparentWhite, height <| px 1 ] |> above ]

      background =
        if darkBackground then
          [ materialScrimBackground ]
        else
          []
  in
    none
    |> el ([ width fill, height <| px <| fragmentsBarHeight,  moveUp fragmentsBarHeight ] ++ markers ++ chunkTriggers ++ border ++ background)


viewChunkPopup model chunkPopup =
  let
      entitiesSection =
        if chunkPopup.chunk.entities |> List.isEmpty then
          [ "No data available" |> text ]
        else
          chunkPopup.chunk.entities
          |> List.map (viewEntityButton model chunkPopup)
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
              superLightBackground :: (viewEntityPopup model chunkPopup entityPopup entity)
            else
              []
    in
        button ([ padding 5, width fill, popupOnMouseEnter (ChunkOnBar { chunkPopup | entityPopup = Just { entityId = entity.id, hoveringAction = Nothing } }) ] ++ backgroundAndSubmenu) { onPress = Nothing, label = label }


viewEntityPopup model chunkPopup entityPopup entity =
  let
      actionButtons =
        [ ("Search", TriggerSearch entity.title)
        ]
        |> List.map (\item -> entityActionButton chunkPopup entityPopup item |> el [ padding 10 ])

      items =
        actionButtons
  in
      items
      |> menuColumn []
      |> (if isHoverMenuNearRightEdge model 300 then onLeft else onRight)
      |> List.singleton


entityActionButton chunkPopup entityPopup (title, clickAction) =
  let
      hoverAction =
        popupOnMouseEnter <| ChunkOnBar { chunkPopup | entityPopup = Just { entityPopup | hoveringAction = Just title } }

      background =
        if entityPopup.hoveringAction == Just title then
          [ superLightBackground, width fill ]
        else
          []

      attrs =
        hoverAction :: ([ width fill ] ++ background)
  in
      actionButtonWithoutIcon attrs title (Just clickAction)


-- viewDefinition model {title} =
--   let
--       definition =
--         title ++ " definition goes here"
--       -- blurb =
--       --   if definition=="" || definition=="(Definition unavailable)" then
--       --     "(Definition unavailable)"
--       --     |> captionNowrap []
--       --   else
--       --     ("“" ++ definition ++ "” (Wikidata)")
--         |> bodyWrap [ Font.italic ]
--   in
--       [ definition ]
--       |> column [ padding 10, spacing 16, width (px 240) ]


fragmentsBarHeight = 16


isHoverMenuNearRightEdge model margin =
  model.mousePositionXwhenOnChunkTrigger > (toFloat model.windowWidth)-margin


truncateSentence characterLimit sentence =
  if (String.length sentence) <= characterLimit then
    sentence
  else
    let
        firstWords words =
          let
              joined =
                words |> String.join " "
          in
              if (words |> List.length) < 2 || (joined |> String.length) < characterLimit then
                joined
              else
                firstWords (words |> List.reverse |> List.drop 1 |> List.reverse)
    in
        (firstWords (sentence |> String.split " ")) ++ "…"


-- shortUrl characterLimit url =
--   let
--       cutBeforeFirst substr input =
--         case input |> String.indexes substr |> List.head of
--           Nothing ->
--             input

--           Just pos ->
--             input |> String.dropLeft (pos + (String.length substr))

--       cutAfterFirst substr input =
--         case input |> String.indexes substr |> List.head of
--           Nothing ->
--             input

--           Just pos ->
--             input |> String.left pos

--       cutBeforeLast substr input =
--         case input |> String.indexes substr |> List.reverse |> List.head of
--           Nothing ->
--             input

--           Just pos ->
--             input |> String.dropLeft pos

--       leftPart =
--         url
--         |> cutBeforeFirst "//"
--         |> cutBeforeFirst "www."
--         |> cutAfterFirst "/"

--       rightPartRaw =
--         url
--         |> cutBeforeLast "/"

--       rightPart =
--         rightPartRaw
--         |> String.dropLeft ((String.length <| leftPart++rightPartRaw) - characterLimit)
--   in
--       leftPart ++ "/..." ++ rightPart


avatarImage =
  image [ alpha 0.5 ] { src = svgPath "user_default_avatar", description = "user menu" }


openInspectorOnPress model oer =
  let
      fragmentLength =
        case chunksFromUrl model oer.url |> List.head of
          Nothing ->
            1

          Just chunk ->
            chunk.length
  in
      case model.inspectorState of
        Nothing ->
          Just (InspectOer oer 0 fragmentLength False)

        _ ->
          Nothing


imageHeight =
  175


cardWidth =
  332


cardHeight =
  280


horizontalSpacingBetweenCards =
  70


verticalSpacingBetweenCards =
  90


pointerEventsNone =
  htmlClass "PointerEventsNone"


isAnyChunkPopupOpen model =
  case model.popup of
    Just (ChunkOnBar _) ->
      True

    _ ->
      False


