module Animation exposing (..)

{-| This module is for things flying around on the screen.
    E.g. the subtle zoom effect when opening the inspector modal.
-}


import Time exposing (Posix)


type alias Point =
  { x : Float
  , y : Float
  }


type alias Box =
  { x : Float
  , y : Float
  , sx : Float
  , sy : Float
  }


type alias BoxAnimation =
  { start : Box
  , end : Box
  , frameCount : Int
  }


{-| Calculate the average between two rectangles
-}
interpolateBoxes : Box -> Box -> Box
interpolateBoxes a b =
  { x = (a.x + b.x) / 2
  , y = (a.y + b.y) / 2
  , sx = (a.sx + b.sx) / 2
  , sy = (a.sy + b.sy) / 2
  }
