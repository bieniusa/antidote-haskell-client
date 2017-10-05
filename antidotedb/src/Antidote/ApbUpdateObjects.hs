-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbUpdateObjects where

import Control.Applicative ((<$>))
import Prelude ()
import qualified Data.ProtoBufInt as PB
import qualified Antidote.ApbUpdateOp

data ApbUpdateObjects = ApbUpdateObjects
  { updates :: !(PB.Seq Antidote.ApbUpdateOp.ApbUpdateOp)
  , transactionDescriptor :: !PB.ByteString
  } deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbUpdateObjects where
  defaultVal = ApbUpdateObjects
    { updates = PB.defaultVal
    , transactionDescriptor = PB.defaultVal
    }

instance PB.Mergeable ApbUpdateObjects where
  merge a b = ApbUpdateObjects
    { updates = PB.merge (updates a) (updates b)
    , transactionDescriptor = PB.merge (transactionDescriptor a) (transactionDescriptor b)
    }

instance PB.Required ApbUpdateObjects where
  reqTags _ = PB.fromList [PB.WireTag 2 PB.LenDelim]

instance PB.WireMessage ApbUpdateObjects where
  fieldToValue (PB.WireTag 1 PB.LenDelim) self = (\v -> self{updates = PB.append (updates self) v}) <$> PB.getMessage
  fieldToValue (PB.WireTag 2 PB.LenDelim) self = (\v -> self{transactionDescriptor = PB.merge (transactionDescriptor self) v}) <$> PB.getBytes
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields self = do
    PB.putMessageList (PB.WireTag 1 PB.LenDelim) (updates self)
    PB.putBytes (PB.WireTag 2 PB.LenDelim) (transactionDescriptor self)

