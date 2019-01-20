module View.Shared exposing (..)

import Html
import Html.Attributes
import Html.Events

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import Json.Decode

import Model exposing (..)
import Msg exposing (..)


type alias PageWithModal = (Element Msg, List (Attribute Msg))


materialDark =
  rgba 0 0 0 0.87


materialDarkAlpha =
  alpha 0.87


primaryWhite =
  Font.color white


x5color =
  Font.color <| rgb255 82 134 148


pageHeaderHeight =
  40


paddingTop px =
  paddingEach { allSidesZero | top = px }


paddingBottom px =
  paddingEach { allSidesZero | bottom = px }


bigButtonPadding =
  paddingXY 13 10


borderBottom px =
  Border.widthEach { allSidesZero | bottom = px }


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


semiTransparentWhite =
  rgba 1 1 1 0.5


orange =
  rgb255 255 150 0


grey80 =
  grey 80


lightGrey =
  grey 238


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
        button [ moveLeft 34, moveDown 12 ] { onPress = Just NewUserFromSearch, label = icon }
  in
      Input.text [ width fill, Input.focusedOnLoad, onEnter NewUserFromSearch ] { onChange = ChangeSearchText, text = searchInputTyping, placeholder = Just (placeholder |> text |> Input.placeholder []), label = Input.labelHidden "search" }
      |> el [ width widthAttr, centerX, onRight submitButton ]


svgIcon stub=
  image [ materialDarkAlpha ] { src = svgPath stub, description = "" }


navigationDrawerWidth =
  260
