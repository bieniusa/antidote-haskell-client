-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.ApbReadObjectResp where

import Control.Applicative ((<$>))
import Prelude ()
import qualified Data.ProtoBufInt as PB
import qualified Antidote.ApbGetCounterResp
import qualified Antidote.ApbGetSetResp
import qualified Antidote.ApbGetRegResp
import qualified Antidote.ApbGetMVRegResp
import qualified Antidote.ApbGetIntegerResp
--import qualified Antidote.ApbGetMapResp
import qualified Antidote.ApbGetFlagResp

data ApbReadObjectResp = ApbReadObjectResp
  { counter :: !(PB.Maybe Antidote.ApbGetCounterResp.ApbGetCounterResp)
  , set :: !(PB.Maybe Antidote.ApbGetSetResp.ApbGetSetResp)
  , reg :: !(PB.Maybe Antidote.ApbGetRegResp.ApbGetRegResp)
  , mvreg :: !(PB.Maybe Antidote.ApbGetMVRegResp.ApbGetMVRegResp)
  , int :: !(PB.Maybe Antidote.ApbGetIntegerResp.ApbGetIntegerResp)
  , map :: !(PB.Maybe Antidote.ApbGetCounterResp.ApbGetCounterResp)--Antidote.ApbGetMapResp.ApbGetMapResp)
  , flag :: !(PB.Maybe Antidote.ApbGetFlagResp.ApbGetFlagResp)
  } deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default ApbReadObjectResp where
  defaultVal = ApbReadObjectResp
    { counter = PB.defaultVal
    , set = PB.defaultVal
    , reg = PB.defaultVal
    , mvreg = PB.defaultVal
    , int = PB.defaultVal
    , map = PB.defaultVal
    , flag = PB.defaultVal
    }

instance PB.Mergeable ApbReadObjectResp where
  merge a b = ApbReadObjectResp
    { counter = PB.merge (counter a) (counter b)
    , set = PB.merge (set a) (set b)
    , reg = PB.merge (reg a) (reg b)
    , mvreg = PB.merge (mvreg a) (mvreg b)
    , int = PB.merge (int a) (int b)
    , map = PB.merge (map a) (map b)
    , flag = PB.merge (flag a) (flag b)
    }

instance PB.Required ApbReadObjectResp where
  reqTags _ = PB.fromList []

instance PB.WireMessage ApbReadObjectResp where
  fieldToValue (PB.WireTag 1 PB.LenDelim) self = (\v -> self{counter = PB.merge (counter self) v}) <$> PB.getMessageOpt
  fieldToValue (PB.WireTag 2 PB.LenDelim) self = (\v -> self{set = PB.merge (set self) v}) <$> PB.getMessageOpt
  fieldToValue (PB.WireTag 3 PB.LenDelim) self = (\v -> self{reg = PB.merge (reg self) v}) <$> PB.getMessageOpt
  fieldToValue (PB.WireTag 4 PB.LenDelim) self = (\v -> self{mvreg = PB.merge (mvreg self) v}) <$> PB.getMessageOpt
  fieldToValue (PB.WireTag 5 PB.LenDelim) self = (\v -> self{int = PB.merge (int self) v}) <$> PB.getMessageOpt
  fieldToValue (PB.WireTag 6 PB.LenDelim) self = (\v -> self{map = PB.merge (map self) v}) <$> PB.getMessageOpt
  fieldToValue (PB.WireTag 7 PB.LenDelim) self = (\v -> self{flag = PB.merge (flag self) v}) <$> PB.getMessageOpt
  fieldToValue tag self = PB.getUnknown tag self

  messageToFields self = do
    PB.putMessageOpt (PB.WireTag 1 PB.LenDelim) (counter self)
    PB.putMessageOpt (PB.WireTag 2 PB.LenDelim) (set self)
    PB.putMessageOpt (PB.WireTag 3 PB.LenDelim) (reg self)
    PB.putMessageOpt (PB.WireTag 4 PB.LenDelim) (mvreg self)
    PB.putMessageOpt (PB.WireTag 5 PB.LenDelim) (int self)
    PB.putMessageOpt (PB.WireTag 6 PB.LenDelim) (map self)
    PB.putMessageOpt (PB.WireTag 7 PB.LenDelim) (flag self)
