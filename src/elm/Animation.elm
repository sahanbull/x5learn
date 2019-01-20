module Animation exposing (..)

import Time exposing (Posix)


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


interpolateBoxes : Box -> Box -> Box
interpolateBoxes a b =
  { x = (a.x + b.x) / 2
  , y = (a.y + b.y) / 2
  , sx = (a.sx + b.sx) / 2
  , sy = (a.sy + b.sy) / 2
  }
