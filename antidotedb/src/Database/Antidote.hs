{-# LANGUAGE OverloadedStrings, KindSignatures, DataKinds, TypeFamilies #-}
{-# LANGUAGE BangPatterns, GeneralizedNewtypeDeriving #-}
module Database.Antidote where

import Antidote.ApbCounterUpdate
import Antidote.ApbStartTransaction
import Antidote.ApbStartTransactionResp
import Antidote.ApbTxnProperties
import Antidote.ApbCommitResp
import Antidote.ApbCommitTransaction
import Antidote.ApbBoundObject
import qualified Antidote.CRDT_type as A
import Antidote.ApbReadObjects
import Antidote.ApbUpdateOperation
import Antidote.ApbUpdateOp
import Antidote.ApbUpdateObjects
import Antidote.ApbReadObjectsResp
import Antidote.ApbReadObjectResp

import qualified Data.Sequence as S
import Data.ProtoBuf as P
import Data.ProtoBufInt as P
import Network.Simple.TCP
import qualified Data.ByteString.Lazy as L
import Data.Binary as B
import Data.Binary.Put as B
import Data.Binary.Get as B
import Control.Monad.Reader


newtype Adb a = Adb { unAdb :: ReaderT AdbCtx IO a }
  deriving (Functor, Applicative, Monad)

data AdbCtx = AdbCtx !AdbConn !TxnDescriptor
type TxnDescriptor = L.ByteString
data AdbConn = AdbConn !Socket

data AdbConfig = AdbConfig { adbHostName :: !String, adbPort :: !Int }
  deriving (Eq, Show)

withAdb :: AdbConfig -> (AdbConn -> IO a) -> IO a
withAdb cfg f
  = error "todo"

runAdbTxn :: AdbConn -> Adb a -> IO a
runAdbTxn conn m
  = error "todo"

data CrdtType = CrdtCounter

class SingCrdtType (t :: CrdtType) where
  singCrdtType :: sing t -> CrdtType

instance SingCrdtType 'CrdtCounter where
  singCrdtType _ = CrdtCounter

data CRDT (t :: CrdtType) = CRDT !L.ByteString !L.ByteString

counterCrdt :: L.ByteString -> L.ByteString -> CRDT 'CrdtCounter
counterCrdt = CRDT

class SingCrdtType t => IsCrdt (t :: CrdtType) where
  type CrdtRep t
  data CrdtUpdate t
  decodeState  :: sing t -> ApbReadObjectResp -> Either String (CrdtRep t)
  encodeUpdate :: CrdtUpdate t -> ApbUpdateOperation

instance IsCrdt 'CrdtCounter where
  type CrdtRep    'CrdtCounter = Int
  data CrdtUpdate 'CrdtCounter = CounterInc !Int
  decodeState  = error "todo"
  encodeUpdate = error "todo"

incCounter :: Int -> CrdtUpdate 'CrdtCounter
incCounter = CounterInc

readCrdt :: IsCrdt t => CRDT t -> Adb (CrdtRep t)
readCrdt = error "todo"

updateCrdt :: IsCrdt t => CRDT t -> CrdtUpdate t -> Adb ()
updateCrdt = error "todo"


test2 :: IO ()
test2
  = withAdb cfg $ \conn ->
      do c <- runAdbTxn conn $ do
                updateCrdt obj (incCounter 1)
                readCrdt obj
         putStrLn (show c)
  where
    cfg = AdbConfig "127.0.0.1" 8087
    obj = counterCrdt "bucket" "x"

-- TODO: Add optional dependecy information
startTxnMsg :: L.ByteString
startTxnMsg =
  let props = ApbTxnProperties Nothing Nothing
      bytes = P.encode $ ApbStartTransaction Nothing (Just props)
  in buildMsg 119 bytes

commitTxnMsg :: TxnDescriptor -> L.ByteString
commitTxnMsg d = buildMsg 121 $ P.encode $ ApbCommitTransaction d

-- FIXME: CRDT type!!
readMsg :: CRDT t -> TxnDescriptor -> L.ByteString
readMsg (CRDT bucket key) d =
  let bo = ApbBoundObject key A.Counter bucket
  in buildMsg 116 $ P.encode $ ApbReadObjects (S.singleton bo) $ d


buildMsg :: Word8 -> L.ByteString ->  L.ByteString
buildMsg code bytes=
  let header = runPut $ do
      B.putInt32be $ fromIntegral $ L.length bytes + 1
      B.putWord8 code
  in L.append header bytes

test :: IO ()
test = do
  connect "127.0.0.1" "8087" $ \(s,_) -> do
    -- start txn
    sendLazy s $ startTxnMsg
    resp <- recv s 5
    case resp of
      Just bs -> do
        let g = do
            laenge <- B.getInt32be
            code   <- getWord8 -- 124
            if code /= 124 then fail $ "bad code: " ++ show code ++ " length: " ++ show laenge else return laenge
        let laenge = runGet g $ L.fromStrict bs
        content <- recv s $ fromIntegral laenge
        case content of
          Just c -> do -- ToDo: Error handling
            let (Right answer) = P.decode $ L.fromStrict c
            let (Just d) = Antidote.ApbStartTransactionResp.transactionDescriptor answer

            -- inc counter
            let bo = ApbBoundObject "key" A.Counter "bucket"
            let inc = ApbCounterUpdate (Just 1)
            let oper = defaultVal{counterop = Just inc}
            let op = ApbUpdateOp bo oper
            let bytesU = P.encode $ ApbUpdateObjects (S.singleton op) $ d
            sendLazy s $ buildMsg 118 bytesU
            respU <- recv s 5
            case respU of
              Just bs -> do
                let g = do
                    laenge <- B.getInt32be
                    code   <- getWord8
                    if code /= 111 then fail $ "bad code: " ++ show code ++ " length: " ++ show laenge else return laenge
                let laenge = runGet g $ L.fromStrict bs
                content <- recv s $ fromIntegral laenge

            -- read counter
                let bytesR = P.encode $ ApbReadObjects (S.singleton bo) $ d
                sendLazy s $ buildMsg 116 bytesR 
                respR <- recv s 5
                case respR of
                    Just bs -> do
                      let g = do
                          laenge <- B.getInt32be
                          code   <- getWord8
                          if code /= 126 then fail $ "bad code: " ++ show code ++ " length: " ++ show laenge else return laenge
                      let laenge = runGet g $ L.fromStrict bs
                      content <- recv s $ fromIntegral laenge
                      case content of
                        Just c -> do -- ToDo: Error handling
                          let (Right answer) = P.decode $ L.fromStrict c
                          let val = objects answer
                          let (v S.:< _) = S.viewl val
                          putStrLn $ show v

                          -- commit txn
                          sendLazy s $ commitTxnMsg d
                          respC <- recv s 5   -- response code 127
                          case respC of
                            Just bs -> do
                              let g = do
                                  laenge <- B.getInt32be
                                  code   <- getWord8 -- 124
                                  if code /= 127 then fail $ "bad code: " ++ show code ++ " length: " ++ show laenge else return laenge
                              let laenge = runGet g $ L.fromStrict bs
                              content <- recv s $ fromIntegral laenge
                              return ()
