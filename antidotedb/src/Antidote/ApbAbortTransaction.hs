-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbAbortTransaction where

import Control.Applicative ((<$>))
import Prelude ()
import qualified Data.ProtoBufInt as PB

newtype ApbAbortTransaction = ApbAbortTransaction
  { transactionDescriptor :: PB.ByteString
  } deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbAbortTransaction where
  defaultVal = ApbAbortTransaction
    { transactionDescriptor = PB.defaultVal
    }

instance PB.Mergeable ApbAbortTransaction where
  merge a b = ApbAbortTransaction
    { transactionDescriptor = PB.merge (transactionDescriptor a) (transactionDescriptor b)
    }

instance PB.Required ApbAbortTransaction where
  reqTags _ = PB.fromList [PB.WireTag 1 PB.LenDelim]

instance PB.WireMessage ApbAbortTransaction where
  fieldToValue (PB.WireTag 1 PB.LenDelim) self = (\v -> self{transactionDescriptor = PB.merge (transactionDescriptor self) v}) <$> PB.getBytes
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields self = do
    PB.putBytes (PB.WireTag 1 PB.LenDelim) (transactionDescriptor self)


