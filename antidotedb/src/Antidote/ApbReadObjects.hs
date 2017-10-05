-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbReadObjects where

import Control.Applicative ((<$>))
import Prelude ()
import qualified Data.ProtoBufInt as PB
import qualified Antidote.ApbBoundObject

data ApbReadObjects = ApbReadObjects
  { boundobjects :: !(PB.Seq Antidote.ApbBoundObject.ApbBoundObject)
  , transactionDescriptor :: !PB.ByteString
  } deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbReadObjects where
  defaultVal = ApbReadObjects
    { boundobjects = PB.defaultVal
    , transactionDescriptor = PB.defaultVal
    }

instance PB.Mergeable ApbReadObjects where
  merge a b = ApbReadObjects
    { boundobjects = PB.merge (boundobjects a) (boundobjects b)
    , transactionDescriptor = PB.merge (transactionDescriptor a) (transactionDescriptor b)
    }

instance PB.Required ApbReadObjects where
  reqTags _ = PB.fromList [PB.WireTag 2 PB.LenDelim]

instance PB.WireMessage ApbReadObjects where
  fieldToValue (PB.WireTag 1 PB.LenDelim) self = (\v -> self{boundobjects = PB.append (boundobjects self) v}) <$> PB.getMessage
  fieldToValue (PB.WireTag 2 PB.LenDelim) self = (\v -> self{transactionDescriptor = PB.merge (transactionDescriptor self) v}) <$> PB.getBytes
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields self = do
    PB.putMessageList (PB.WireTag 1 PB.LenDelim) (boundobjects self)
    PB.putBytes (PB.WireTag 2 PB.LenDelim) (transactionDescriptor self)

