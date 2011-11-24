import Control.Monad.State.Lazy
import Control.Applicative
import Data.List (transpose)
import Data.Array
import Data.Monoid
import LEDWall

w = 16
h = 15

data Cell = Alive
          | Dead
          deriving (Eq, Show)

data GameState = GameState (Array (Int, Int) Cell) Color

type GameAction a = StateT [GameState] IO a

tickState (GameState field color)
  = let field = array ((0, 0), (w-1, h-1))
                [((x, y), newState x y)
                | x <- [0..w-1],
                  y <- [0..h-1]]
    in GameState field color
  where newState x y 
          = let oldState = field ! (x, y)
                aliveNeighbours = length $
                                  [()
                                   | x' <- [x-1..x+1],
                                     y' <- [y-1..y+1],
                                     (x' /= x || y' /= y) &&
                                     field ! (x' `mod` w, y' `mod` h) == Alive]
            in case (oldState, aliveNeighbours) of
              (Alive, 2) -> Alive
              (Alive, 3) -> Alive
              (Dead, 3) -> Alive
              _ -> Dead

tick = get >>= put . map tickState

composeImage :: GameAction [[Color]]
composeImage 
  = do states <- get
       return $ 
         do y <- [0..h-1]
            return $
              do x <- [0..w-1]
                 return $ mconcat $
                   map (\(GameState field color) ->
                         if field ! (x, y) == Alive
                         then color
                         else mempty
                       ) states

  
game :: GameAction [[Color]]
game = do tick
          composeImage

main = runAnimation game $ [mkState (glider ++ mv 7 3 glider) $ RGB 192 0 0
                           ,mkState (mv 10 10 blinker ++ mv 2 2 blinker) $ RGB 0 192 0
                           ,mkState (mv 0 11 acorn) $ RGB 0 0 127
                           ,mkState (mv 5 9 swss) $ RGB 127 0 127
                           ,mkState (mv 0 3 fgg) $ RGB 192 192 0
                           ]
  where mkState poss color
          = let field = array ((0, 0), (w-1, h-1))
                        [((x, y), if (x, y) `elem` poss
                                  then Alive
                                  else Dead)
                        | x <- [0..w-1],
                          y <- [0..h-1]]
            in GameState field color

mv dx dy = map (\(x, y) -> (x + dx, y + dy))
                           
glider = [(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)]
blinker = [(x, 0) | x <- [0..2]]
acorn = [(1, 0), 
         (3, 1), 
         (0, 2), (1, 2), (4, 2), (5, 2), (6, 2)]
swss = [(1, 0), (4, 0),        
        (0, 1),
        (0, 2), (4, 2),
        (0, 3), (1, 3), (2, 3), (3, 3)]
fgg = [(2, 0),
       (2, 1),
       (0, 2), (1, 2), (2, 2),
       (6, 4), (7, 4), (8, 4),
       (7, 5),
       (11, 6), (12, 6), (13, 6),
       (12, 7)]
      
