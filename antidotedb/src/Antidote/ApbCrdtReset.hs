-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbCrdtReset where

import Prelude ()
import qualified Data.ProtoBufInt as PB

data ApbCrdtReset = ApbCrdtReset
  deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbCrdtReset where
  defaultVal = ApbCrdtReset
    { 
    }

instance PB.Mergeable ApbCrdtReset where
  merge _ _ = ApbCrdtReset
    { 
    }

instance PB.Required ApbCrdtReset where
  reqTags _ = PB.fromList []

instance PB.WireMessage ApbCrdtReset where
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields _ = PB.return ()

