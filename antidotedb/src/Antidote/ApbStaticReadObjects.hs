-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbStaticReadObjects where

import Control.Applicative ((<$>))
import Prelude ()
import qualified Data.ProtoBufInt as PB
import qualified Antidote.ApbStartTransaction
import qualified Antidote.ApbBoundObject

data ApbStaticReadObjects = ApbStaticReadObjects
  { transaction :: !Antidote.ApbStartTransaction.ApbStartTransaction
  , objects :: !(PB.Seq Antidote.ApbBoundObject.ApbBoundObject)
  } deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbStaticReadObjects where
  defaultVal = ApbStaticReadObjects
    { transaction = PB.defaultVal
    , objects = PB.defaultVal
    }

instance PB.Mergeable ApbStaticReadObjects where
  merge a b = ApbStaticReadObjects
    { transaction = PB.merge (transaction a) (transaction b)
    , objects = PB.merge (objects a) (objects b)
    }

instance PB.Required ApbStaticReadObjects where
  reqTags _ = PB.fromList [PB.WireTag 1 PB.LenDelim]

instance PB.WireMessage ApbStaticReadObjects where
  fieldToValue (PB.WireTag 1 PB.LenDelim) self = (\v -> self{transaction = PB.merge (transaction self) v}) <$> PB.getMessage
  fieldToValue (PB.WireTag 2 PB.LenDelim) self = (\v -> self{objects = PB.append (objects self) v}) <$> PB.getMessage
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields self = do
    PB.putMessage (PB.WireTag 1 PB.LenDelim) (transaction self)
    PB.putMessageList (PB.WireTag 2 PB.LenDelim) (objects self)


