{-# LANGUAGE TemplateHaskell, FlexibleInstances, IncoherentInstances#-}
module Ogg where

import Check
import DeriveArbitrary
import Test.QuickCheck

import Data.Binary( Binary(..), encode )

import Codec.Container.Ogg.Page
import Codec.Container.Ogg.Granulepos
import Codec.Container.Ogg.Track
import Codec.Container.Ogg.MessageHeaders
import Codec.Container.Ogg.Granulerate
import Codec.Container.Ogg.ContentType

import qualified Data.ByteString.Lazy as L

import Data.DeriveTH
import Data.Word(Word8, Word16, Word32)
import Data.Int( Int16, Int8 )

--import qualified Data.Vector as V
--import qualified Data.Vector.Unboxed as VU
--import qualified Data.Vector.Storable as VS

--import GHC.Types

import Data.Binary.Put( runPut )

import ByteString

import Data.List.Split

-- $(deriveArbitraryRec ''OggPage)

derive makeArbitrary ''OggPage
derive makeArbitrary ''Granulepos
derive makeArbitrary ''OggTrack
derive makeArbitrary ''Granulerate
--derive makeArbitrary ''ContentType

--instance Arbitrary L.ByteString where
--   arbitrary = do
--     l <- listOf (arbitrary :: Gen Word8)
--     return $ L.pack l

instance Arbitrary ContentType where
   arbitrary = oneof $ map return [theora]--(map return [skeleton, cmml, vorbis, theora, speex, celt, flac])


instance Arbitrary MessageHeaders where
   arbitrary = do
     y <- listOf (arbitrary :: Gen String)
     x <- (arbitrary :: (Gen String))
     return $ mhAppends x y mhEmpty

appendvorbis d = L.append theoraIdent d
appendh (OggPage x track cont incplt bos eos gp seqno s) = OggPage x track cont incplt bos eos gp seqno (map appendvorbis s)

--instance CoArbitrary L.ByteString where
--   coarbitrary x = coarbitrary $ L.unpack x

main filename cmd prop maxSuccess maxSize = let (prog, args) = (head spl, tail spl) in
    (case prop of
        "fuzz" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ fuzzprop filename prog args (pageWrite . appendh))
        "check" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ checkprop filename prog args (pageWrite . appendh))
        "gen" -> quickCheckWith stdArgs { maxSuccess = maxSuccess , maxSize = maxSize } (noShrinking $ genprop filename prog args (pageWrite . appendh))
    ) where spl = splitOn " " cmd
