module LEDWall where

import Text.Printf
import Control.Monad.State.Lazy
import Data.Word (Word8)
import Data.Monoid

type Word = Word8

data Color = RGB Word Word Word
           | RGBDouble Double Double Double
           deriving (Show, Eq)
             
instance Monoid Color where
  mempty = RGB 0 0 0
  mappend (RGB r g b) (RGB r' g' b') = RGB (r + r') (g + g') (b + b')
             
type Position = (Word, Word)

data Instruction = Blank Color
                 | Pixel Position Color
                 | Frame [Color]

generateOutput :: [[Color]] -> [Instruction]
generateOutput pixels = 
  concatMap (\(y, row) ->
              map (\(x, color) ->
                    Pixel (x, y) color
                  ) (zip [1..] row)
            ) (zip [1..] pixels)

command2 :: Position -> Color -> String
command2 (x, y) (RGB r g b) = 
  printf "02%02x%02x%02x%02x%02x\r\n" x y r g b

command3 colors = "03" ++ concatMap colorToHex colors ++ "\r\n"

colorToHex :: Color -> String
colorToHex (RGB r g b) = printf "%02x%02x%02x" (clamp r) (clamp g) (clamp b)
    where clamp = min 255 . max 0
colorToHex (RGBDouble r g b) = colorToHex $
                               RGB (c r) (c g) (c b)
    where c :: Double -> Word
          c = truncate .
              (* 255.0) .
              min 1.0 .
              max 0.0

instructionToCommand :: Instruction -> String
instructionToCommand (Blank color) = command2 (0, 0) color
instructionToCommand (Pixel (x, y) color) = command2 (x, y) color
instructionToCommand (Frame colors) = command3 colors

runAnimation :: StateT s IO [[Color]] -> s -> IO ()
runAnimation gen st = do (colors, st') <- runStateT gen st
                         putStr $ instructionToCommand $ Frame $ concat colors
                         runAnimation gen st'

