-- Generated by protobuf-simple. DO NOT EDIT!
module Antidote.CRDT_type where

import Prelude ()
import qualified Data.ProtoBufInt as PB

data CRDT_type = Counter | Orset | Lwwreg | Mvreg | Integer | Gmap | Awmap | Rwset | Rrmap | Fatcounter | FlagEw | FlagDw
  deriving (PB.Show, PB.Eq, PB.Ord)

instance PB.Default CRDT_type where
  defaultVal = Counter

instance PB.Mergeable CRDT_type where

instance PB.WireEnum CRDT_type where
  intToEnum 3 = Counter
  intToEnum 4 = Orset
  intToEnum 5 = Lwwreg
  intToEnum 6 = Mvreg
  intToEnum 7 = Integer
  intToEnum 8 = Gmap
  intToEnum 9 = Awmap
  intToEnum 10 = Rwset
  intToEnum 11 = Rrmap
  intToEnum 12 = Fatcounter
  intToEnum 13 = FlagEw
  intToEnum 14 = FlagDw
  intToEnum _ = PB.defaultVal

  enumToInt Counter = 3
  enumToInt Orset = 4
  enumToInt Lwwreg = 5
  enumToInt Mvreg = 6
  enumToInt Integer = 7
  enumToInt Gmap = 8
  enumToInt Awmap = 9
  enumToInt Rwset = 10
  enumToInt Rrmap = 11
  enumToInt Fatcounter = 12
  enumToInt FlagEw = 13
  enumToInt FlagDw = 14


