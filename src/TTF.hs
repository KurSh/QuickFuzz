{-# LANGUAGE TemplateHaskell, FlexibleInstances, IncoherentInstances#-}

module TTF where

import Args
import Test.QuickCheck
import DeriveArbitrary
import Check

import Control.Exception
import Data.Binary( Binary(..), encode )

import TTFInstructions

import Vector
import ByteString

import qualified Data.ByteString.Lazy as L

import Data.DeriveTH
import Data.List.Split
import Control.Monad.State

$(deriveArbitraryRec ''Op)


tab = [
        Table "cmap" (cmapTable (cmapFormat0 0 (take 262 $ repeat 0))),
        Table "glyf" (glyph 0 0 10 10 [0,1,2] (return ()) [3,3,3] [3,4,5] [6,7,8]),
        Table "hhea" (hhea 0 0 0 1 0 0 0 0 0 1),
        Table "hmtx" (hmtx (hmtxEntry 0 0)),
        Table "loca" (_loca [0]),
        --Table "maxp" (maxp 1 1 1 1 1 1 1 1 1 1 1 1 1 1),
        Table "name" (nameHeaderMS [MSNRecord Copyright "bacon", MSNRecord Fullname "tree", MSNRecord UUID "fish"])
        --Table "post" (post3 0 0 0 True)
    ] 


type MTTFIns = String
type MTTFFont = [(MTTFIns, [Op])]

instance Arbitrary MTTFIns where
   arbitrary = oneof $ (map return ["post", "name", "maxp", "loca", "hmtx", "hhea", "glyf", "cmap", "head", "fpgm"])

mkTable (str,xs) = Table str (ops xs) --where str = [c1,c2,c3,c4]

encodeMTTFFont :: MTTFFont -> L.ByteString
encodeMTTFFont xs = fst $ compile $ compileTables (map mkTable xs) (headTable 1 1 0 0 0 0 1 1 0 0 0 1 0)    

mencode :: MTTFFont -> L.ByteString
mencode = encodeMTTFFont

main (MainArgs _ filename cmd prop maxSuccess maxSize outdir) = let (prog, args) = (Prelude.head spl, tail spl) in
    (case prop of
        "zzuf" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ zzufprop filename prog args mencode outdir)
        "radamsa" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ radamprop filename prog args mencode outdir)
        "check" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ checkprop filename prog args mencode outdir)
        "gen" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ genprop filename prog args mencode outdir)
        "exec" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ execprop filename prog args mencode outdir)
        _     -> error "Invalid action selected"
    ) where spl = splitOn " " cmd
