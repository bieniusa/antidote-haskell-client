-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbBoundObject where

import Control.Applicative ((<$>))
import Prelude ()
import qualified Data.ProtoBufInt as PB
import qualified Antidote.CRDT_type

data ApbBoundObject = ApbBoundObject
  { key :: !PB.ByteString
  , type :: !Antidote.CRDT_type.CRDT_type
  , bucket :: !PB.ByteString
  } deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbBoundObject where
  defaultVal = ApbBoundObject
    { key = PB.defaultVal
    , type = PB.defaultVal
    , bucket = PB.defaultVal
    }

instance PB.Mergeable ApbBoundObject where
  merge a b = ApbBoundObject
    { key = PB.merge (key a) (key b)
    , type = PB.merge (type a) (type b)
    , bucket = PB.merge (bucket a) (bucket b)
    }

instance PB.Required ApbBoundObject where
  reqTags _ = PB.fromList [PB.WireTag 1 PB.LenDelim, PB.WireTag 2 PB.VarInt, PB.WireTag 3 PB.LenDelim]

instance PB.WireMessage ApbBoundObject where
  fieldToValue (PB.WireTag 1 PB.LenDelim) self = (\v -> self{key = PB.merge (key self) v}) <$> PB.getBytes
  fieldToValue (PB.WireTag 2 PB.VarInt) self = (\v -> self{type = PB.merge (type self) v}) <$> PB.getEnum
  fieldToValue (PB.WireTag 3 PB.LenDelim) self = (\v -> self{bucket = PB.merge (bucket self) v}) <$> PB.getBytes
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields self = do
    PB.putBytes (PB.WireTag 1 PB.LenDelim) (key self)
    PB.putEnum (PB.WireTag 2 PB.VarInt) (type self)
    PB.putBytes (PB.WireTag 3 PB.LenDelim) (bucket self)

