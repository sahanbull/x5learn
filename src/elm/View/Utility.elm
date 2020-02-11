module View.Utility exposing (..)

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

type alias PageWithInspector = (Element Msg, List (Attribute Msg))

type IconPosition
  = IconLeft
  | IconRight


-- X5GON color palette

midnightBlue : Color
midnightBlue =
  rgb255 0 13 50


x5grey : Color
x5grey =
  rgb255 74 84 114


electricBlue : Color
electricBlue =
  rgb255 0 156 204


blueberryBlue : Color
blueberryBlue =
  rgb255 72 119 255


primaryGreen : Color
primaryGreen =
  rgb255 0 173 87


oxfordBlue : Color
oxfordBlue =
  rgb255 0 19 77


superlightGrey : Color
superlightGrey =
  rgb255 242 243 244


superLightBackground : Attribute Msg
superLightBackground =
  Background.color superlightGrey


-- additional UI colors

white : Color
white =
  rgb 1 1 1


yellow : Color
yellow =
  rgba255 255 235 0 0.97


red : Color
red =
  rgba255 240 30 0 1


magenta : Color
magenta =
  rgb255 250 0 230


grey80 : Color
grey80 =
  grey 80


greyMedium : Color
greyMedium =
  grey 160


veryTransparentWhite : Color
veryTransparentWhite =
  rgba 1 1 1 0.25


semiTransparentWhite : Color
semiTransparentWhite =
  rgba 1 1 1 0.95


semiTransparent : Attribute Msg
semiTransparent =
  alpha 0.5


fullyTransparentColor : Color
fullyTransparentColor =
  rgba 0 0 0 0


grey : Int -> Color
grey value =
  rgb255 value value value


slightlyTransparentBlack : Color
slightlyTransparentBlack =
  rgba 0 0 0 0.7


greyDivider : Color
greyDivider =
  rgb 0.8 0.8 0.8


materialDarkAlpha : Attribute Msg
materialDarkAlpha =
  alpha 0.87


whiteText : Attribute Msg
whiteText =
  Font.color white


greyText : Attribute Msg
greyText =
  Font.color <| x5grey


pageHeaderHeight : Int
pageHeaderHeight =
  40


paddingTop : Int -> Attribute Msg
paddingTop px =
  paddingEach { allSidesZero | top = px }


paddingBottom : Int -> Attribute Msg
paddingBottom px =
  paddingEach { allSidesZero | bottom = px }


paddingLeft : Int -> Attribute Msg
paddingLeft px =
  paddingEach { allSidesZero | left = px }


paddingRight : Int -> Attribute Msg
paddingRight px =
  paddingEach { allSidesZero | right = px }


buttonRounding : Attribute Msg
buttonRounding =
  Border.rounded 4


bigButtonPadding : Attribute Msg
bigButtonPadding =
  paddingXY 13 10


borderTop : Int -> Attribute Msg
borderTop px =
  Border.widthEach { allSidesZero | top = px }


borderBottom : Int -> Attribute Msg
borderBottom px =
  Border.widthEach { allSidesZero | bottom = px }


borderLeft : Int -> Attribute Msg
borderLeft px =
  Border.widthEach { allSidesZero | left = px }


borderColorDivider : Attribute Msg
borderColorDivider =
  Border.color greyDivider


allSidesZero : { bottom : number, left : number1, right : number2, top : number3 }
allSidesZero =
  { top = 0
  , right = 0
  , bottom = 0
  , left = 0
  }


smallShadow : Attribute Msg
smallShadow =
  Border.shadow { offset = ( 0, 2 ) , size = 1 , blur = 3 , color = superlightGrey }


captionTextAttrs : List (Attribute Msg)
captionTextAttrs =
  [ Font.size 12, Font.color midnightBlue ]


bodyTextAttrs : List (Attribute Msg)
bodyTextAttrs =
  [ Font.size 14, Font.color midnightBlue ]


bigHeadingTextAttrs =
  [ Font.family [ Font.typeface "IBM Plex Serif" , Font.serif ] ]


captionNowrap : List (Attribute Msg) -> String -> Element Msg
captionNowrap attrs str =
  text str |> el (captionTextAttrs ++ attrs)


captionWrap : List (Attribute Msg) -> String -> Element Msg
captionWrap attrs str =
  [ text str ] |> paragraph (captionTextAttrs ++ attrs)


bodyWrap : List (Attribute Msg) -> String -> Element Msg
bodyWrap attrs str =
  [ text str ] |> paragraph (bodyTextAttrs ++ attrs)


bodyNoWrap : List (Attribute Msg) -> String -> Element Msg
bodyNoWrap attrs str =
  text str |> el (bodyTextAttrs ++ attrs)


subSubheaderNoWrap : List (Attribute Msg) -> String -> Element Msg
subSubheaderNoWrap attrs str =
  text str |> el ([ Font.size 16, Font.color midnightBlue ] ++ attrs)


subSubheaderWrap : List (Attribute Msg) -> String -> Element Msg
subSubheaderWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 16, Font.color midnightBlue ] ++ attrs)


subheaderWrap : List (Attribute Msg) -> String -> Element Msg
subheaderWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 21, Font.color midnightBlue ] ++ attrs)


headlineWrap : List (Attribute Msg) -> String -> Element Msg
headlineWrap attrs str =
  [ text str ] |> paragraph ([ Font.size 24, Font.color midnightBlue ] ++ attrs)


italicText : String -> Element Msg
italicText =
  bodyWrap [ Font.italic ]


htmlClass : String -> Attribute Msg
htmlClass name =
  Html.Attributes.class name |> htmlAttribute


htmlId : String -> Attribute Msg
htmlId name =
  Html.Attributes.id name |> htmlAttribute


htmlStyle : String -> String -> Attribute Msg
htmlStyle name value =
  Html.Attributes.style name value |> htmlAttribute


htmlDataAttribute : String -> Attribute Msg
htmlDataAttribute str =
  Html.Attributes.attribute "data-oerid" str |> htmlAttribute


whiteBackground : Attribute Msg
whiteBackground =
  Background.color white


pageBodyBackground : Model -> Attribute Msg
pageBodyBackground model =
  if isLabStudy1 model then
    Background.color <| grey 224
  else
    Background.color <| grey 224


imgPath : String -> String
imgPath str =
  "/static/dist/img/" ++ str


svgPath : String -> String
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
onClickStopPropagation : msg -> Attribute msg
onClickStopPropagation message =
  Html.Events.custom "click" (Json.Decode.succeed { message = message, stopPropagation = True, preventDefault = True })
  |> htmlAttribute


hoverCircleBackground : Attribute Msg
hoverCircleBackground =
  htmlClass "HoverCircleBackground"


dialogShadow : Attribute Msg
dialogShadow =
  Border.shadow
    { offset = (0, 20)
    , size = 0
    , blur = 60
    , color = rgba 0 0 0 0.6
    }


linkTo : List (Attribute Msg) -> String -> Element Msg -> Element Msg
linkTo attrs url label =
  link attrs { url = url, label = label }


newTabLinkTo : List (Attribute Msg) -> String -> Element Msg -> Element Msg
newTabLinkTo attrs url label =
  newTabLink attrs { url = url, label = label }


svgIcon : String -> Element Msg
svgIcon stub=
  image [ materialDarkAlpha ] { src = svgPath stub, description = "" }


navigationDrawerWidth =
  230


dropdownTriangle =
  "▾" |> captionNowrap [ Font.color grey80 ]


actionButtonWithIcon : List (Attribute Msg) -> List (Attribute Msg) -> IconPosition -> Float -> String -> String -> Maybe Msg -> Element Msg
actionButtonWithIcon textAttrs buttonAttrs iconPosition iconAlpha svgIconStub str onPress =
  let
      icon =
        image [ alpha iconAlpha ] { src = svgPath svgIconStub, description = "" }

      title =
        str |> bodyNoWrap (textAttrs ++ [ width fill ])

      label =
        case iconPosition of
          IconLeft ->
            [ icon, title ]

          IconRight ->
            [ title, icon ]
  in
      button ([ htmlClass "PreventClosingInspectorOnClick", buttonRounding ] ++ buttonAttrs) { onPress = onPress, label = label |> row [ width fill, spacing 3, buttonRounding ]}


actionButtonWithoutIcon : List (Attribute Msg) -> List (Attribute Msg) -> String -> Maybe Msg -> Element Msg
actionButtonWithoutIcon labelAttrs buttonAttrs str onPress =
  let
      label =
        str |> bodyNoWrap labelAttrs
  in
      button buttonAttrs { onPress = onPress, label = label }


actionButtonWithoutIconStopPropagation : List (Attribute Msg) -> String -> Msg -> Element Msg
actionButtonWithoutIconStopPropagation attrs str onPress =
  str
  |> bodyNoWrap []
  |> el (attrs ++ [ onClickStopPropagation onPress ])


simpleButton : List (Attribute Msg) -> String -> Maybe Msg -> Element Msg
simpleButton attrs str onPress =
  let
      label =
        str |> text
  in
      button attrs { onPress = onPress, label = label }


confirmButton : List (Attribute Msg) -> String -> Maybe Msg -> Element Msg
confirmButton attrs str onPress =
  let
      label =
        str |> bodyNoWrap [ Background.color primaryGreen, bigButtonPadding, whiteText ]
  in
      button attrs { onPress = onPress, label = label }


stopButton : List (Attribute Msg) -> String -> Maybe Msg -> Element Msg
stopButton attrs str onPress =
  let
      label =
        str |> bodyNoWrap [ Background.color red, bigButtonPadding, whiteText ]
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


inspectorSidebarWidth model =
  if isLabStudy1 model then
    0
  else
    230


playerWidth : Model -> Int
playerWidth model =
  let
      default =
        520
  in
      case model.inspectorState of
        Nothing ->
          default

        Just inspectorState ->
          case inspectorState.videoPlayer of
            Nothing ->
              default

            Just videoPlayer ->
              (model.windowHeight - pageHeaderHeight - 380 |> toFloat) * videoPlayer.aspectRatio
              |> min (model.windowWidth - navigationDrawerWidth - (inspectorSidebarWidth model) - 40 |> toFloat)
              |> min 720
              |> floor


milkyWhiteCenteredContainer : Element Msg -> Element Msg
milkyWhiteCenteredContainer =
  el [ centerX, centerY, padding 20, Background.color semiTransparentWhite, Border.rounded 2 ]


viewCenterMessage : String -> Element Msg
viewCenterMessage str =
  str
  |> bodyWrap []
  |> milkyWhiteCenteredContainer


viewLoadingSpinner : Element Msg
viewLoadingSpinner =
  none
  |> el [ htmlClass "loader", centerX, centerY ]
  |> el [ centerX, centerY ]


menuButtonDisabled : String -> Element Msg
menuButtonDisabled str =
  let
      label =
        [ str |> bodyNoWrap [ width fill ]
        ]
        |> row [ width fill, paddingXY 10 5, spacing 3 ]
  in
      button [ width fill, padding 5 ] { onPress = Nothing, label = label }


popupOnMouseEnter : Popup -> Attribute Msg
popupOnMouseEnter popup =
  onMouseEnter (SetPopup popup)


closePopupOnMouseLeave : Attribute Msg
closePopupOnMouseLeave =
  onMouseLeave ClosePopup


menuColumn : List (Attribute Msg) -> List (Element Msg) -> Element Msg
menuColumn attrs =
  column ([ Background.color white, Border.rounded 4, Border.color <| grey80, dialogShadow ] ++ attrs)


truncateSentence : Int -> String -> String
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


openInspectorOnPress : Model -> Oer -> Maybe Msg
openInspectorOnPress model oer =
  case model.inspectorState of
    Nothing ->
      Just (InspectOer oer 0 False)

    _ ->
      Nothing


imageHeight : Int
imageHeight =
  175


cardWidth : Int
cardWidth =
  332


cardHeight : Int
cardHeight =
  280


horizontalSpacingBetweenCards : Int
horizontalSpacingBetweenCards =
  70


verticalSpacingBetweenCards : Int
verticalSpacingBetweenCards =
  90


pointerEventsNone : Attribute Msg
pointerEventsNone =
  htmlClass "PointerEventsNone"


inlineLinkAttrs : List (Attribute Msg)
inlineLinkAttrs =
  [ paddingXY 5 0, Font.color blueberryBlue ]


guestCallToSignup : String -> Element Msg
guestCallToSignup incentive =
  [ "You are not logged in. "++incentive++", make sure to" |> text
  , "log in" |> text |> linkTo inlineLinkAttrs loginPath
  , "or" |> text
  , "sign up" |> text |> linkTo inlineLinkAttrs signupPath
  ]
  |> paragraph [ width fill, Font.size 14, Font.color midnightBlue ]


closeIcon : Element Msg
closeIcon =
  image [  materialDarkAlpha, hoverCircleBackground ] { src = svgPath "close", description = "close" }


trashIcon : Element Msg
trashIcon =
  image [  materialDarkAlpha, hoverCircleBackground, width <| px 30 ] { src = svgPath "delete", description = "delete" }


avatarImage : Element Msg
avatarImage =
  image [ alpha 0.5 ] { src = svgPath "user_default_avatar", description = "user menu" }


explanationLinkForWikification : WebLink
explanationLinkForWikification =
  { label = "Wikification"
  , url = "http://wikifier.org" -- TODO improve
  }


explanationLinkForSearch : WebLink
explanationLinkForSearch =
  { label = "AI-based Search"
  , url = "https://platform.x5gon.org/search" -- TODO improve
  }


explanationLinkForTrueLearn : WebLink
explanationLinkForTrueLearn =
  { label = "Personalised Recommendation"
  , url = "https://platform.x5gon.org"
  }


explanationLinkForItemRecommender : WebLink
explanationLinkForItemRecommender =
  { label = "Item-based Recommendation"
  , url = "https://platform.x5gon.org/products/recommend"
  }


explanationLinkForTranslation : WebLink
explanationLinkForTranslation =
  { label = "Translation / Transcription"
  , url = "https://platform.x5gon.org/products/translate"
  }
