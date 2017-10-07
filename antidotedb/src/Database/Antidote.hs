{-# LANGUAGE OverloadedStrings, KindSignatures, DataKinds, TypeFamilies #-}
{-# LANGUAGE BangPatterns, GeneralizedNewtypeDeriving, RecordWildCards #-}
module Database.Antidote where

import Antidote.ApbCounterUpdate
import Antidote.ApbStartTransaction
import Antidote.ApbStartTransactionResp
import Antidote.ApbTxnProperties
import Antidote.ApbCommitResp
import Antidote.ApbCommitTransaction
import Antidote.ApbBoundObject
import Antidote.CRDT_type
import Antidote.ApbReadObjects
import Antidote.ApbUpdateOperation
import Antidote.ApbUpdateOp
import Antidote.ApbUpdateObjects
import Antidote.ApbReadObjectsResp
import Antidote.ApbReadObjectResp
import Antidote.ApbOperationResp
import Antidote.ApbGetCounterResp
import Antidote.ApbGetRegResp
import Antidote.ApbRegUpdate


import Data.Proxy
import qualified Data.Sequence as S
import Data.ProtoBuf as P
import Data.ProtoBufInt as P
import Network.Simple.TCP
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as L
import Data.Binary as B
import Data.Binary.Put as B
import Data.Binary.Get as B
import Control.Exception
import Control.Monad
import Control.Monad.Reader
import Data.Pool
import System.IO.Streams
import Data.Kind


newtype Adb a = Adb { unAdb :: ReaderT AdbState IO a }
  deriving (Functor, Applicative, Monad)

data AdbState = AdbState !AdbConn !TxnDescriptor
type TxnDescriptor = L.ByteString
newtype AdbCtx = AdbCtx (Pool AdbConn)
data AdbConn = AdbConn !Socket !(InputStream B.ByteString) (OutputStream B.ByteString)


data AdbConfig = AdbConfig { adbHostName :: !String, adbPort :: !Int, adbConnectionLimit :: !Int }
  deriving (Eq, Show)

withAdb :: AdbConfig -> (AdbCtx -> IO a) -> IO a
withAdb (AdbConfig {..}) f
  = bracket (createPool createConn destroyConn 1 120.0 adbConnectionLimit)
            destroyAllResources
            (f . AdbCtx)
  where
    createConn
      = bracketOnError (connectSock adbHostName (show adbPort)) (closeSock . fst) $ \(sock, _) ->
          do (inp, out) <- socketToStreams sock
             return $ AdbConn sock inp out

    destroyConn (AdbConn s _ _) = closeSock s

runAdbTxn :: AdbCtx -> Adb a -> IO a
runAdbTxn (AdbCtx pool) (Adb m)
  = withResource pool $ \conn ->
      do descr <- createTxn conn
         let state = AdbState conn descr
         a <- runReaderT m state
         commitTxn conn descr
         pure a

headerDecoder :: Word8 -> Get Int
headerDecoder code
  = do sizeB    <- B.getInt32be
       codeRecv <- getWord8
       if codeRecv /= code
       then fail $ "bad code: " ++ show codeRecv ++ " length: " ++ show sizeB
       else return $ fromIntegral sizeB

decodeHeader :: B.ByteString -> Word8 -> IO Int
decodeHeader bs code
  = case runGetOrFail (headerDecoder code) (L.fromStrict bs) of
      Left (_, offset, msg) -> fail ("at " ++ show offset ++ ": " ++ msg)
      Right (_, _, l)       -> return l

class HasMessageCode a where
  messageCode :: a -> Word8

readResponse :: (Default a, Required a, WireMessage a, HasMessageCode a) =>
  InputStream B.ByteString -> IO a
readResponse = readResponse' defaultVal

readResponse' :: (Default a, Required a, WireMessage a, HasMessageCode a) =>
  a -> InputStream B.ByteString -> IO a
readResponse' dflt inStream = do
  hs  <- readExactly 5 inStream
  putStrLn (show hs)
  len <- decodeHeader hs $ messageCode dflt
  putStrLn ("Read response header with len " ++ show len)
  bs  <- readExactly (len - 1) inStream
  putStrLn ("Read response content")
  case P.decode $ L.fromStrict bs of
    Left msg -> fail msg
    Right a  -> return a

writeRequest :: (WireMessage a, HasMessageCode a) =>
  a -> OutputStream B.ByteString -> IO ()
writeRequest a outStream = writeLazyByteString msg outStream where
  msg = buildMsg (messageCode a) (P.encode a)

  buildMsg :: Word8 -> L.ByteString ->  L.ByteString
  buildMsg code bytes=
    let header = runPut $ do
        B.putInt32be $ fromIntegral $ L.length bytes + 1
        B.putWord8 code
    in L.append header bytes

-- TODO: Add optional dependecy information
createTxn :: AdbConn -> IO TxnDescriptor
createTxn (AdbConn _ inStream outStream) = do
  let props    = ApbTxnProperties Nothing Nothing
      startTxn = ApbStartTransaction Nothing (Just props)
  writeRequest startTxn outStream
  resp <- readResponse inStream
  case Antidote.ApbStartTransactionResp.transactionDescriptor resp of
    Nothing -> fail "no txn descriptor provided"
    Just d  -> return d

commitTxn :: AdbConn -> TxnDescriptor -> IO TxnDescriptor
commitTxn (AdbConn _ inStream outStream) d = do
  writeRequest (ApbCommitTransaction d) outStream
  resp <- readResponse inStream
  case commitTime resp of
    Nothing -> fail "no txn descriptor provided"
    Just d -> return d

data CrdtType = CrdtCounter | CrdtLwwReg Type

class SingCrdtType (t :: CrdtType) where
  singCrdtType :: sing t -> CRDT_type

instance SingCrdtType 'CrdtCounter where
  singCrdtType _ = Counter

instance SingCrdtType ('CrdtLwwReg a) where
  singCrdtType _ = Lwwreg

data CRDT (t :: CrdtType) = CRDT !L.ByteString !L.ByteString

counterCrdt :: L.ByteString -> L.ByteString -> CRDT 'CrdtCounter
counterCrdt = CRDT

regCrdt :: Binary a => L.ByteString -> L.ByteString -> CRDT ('CrdtLwwReg a)
regCrdt = CRDT

class SingCrdtType t => IsCrdt (t :: CrdtType) where
  type CrdtRep t
  data CrdtUpdate t
  decodeState  :: sing t -> ApbReadObjectResp -> Either String (CrdtRep t)
  encodeUpdate :: CrdtUpdate t -> ApbUpdateOperation

instance IsCrdt 'CrdtCounter where
  type CrdtRep    'CrdtCounter = Int
  data CrdtUpdate 'CrdtCounter = CounterInc !Int
  decodeState _ resp =
    case counter resp of
      Nothing -> fail "no counter"
      Just c -> return $ fromIntegral $ Antidote.ApbGetCounterResp.value c
  encodeUpdate (CounterInc x) =
    defaultVal{counterop = Just $ ApbCounterUpdate $ Just $ fromIntegral x}

instance Binary a => IsCrdt ('CrdtLwwReg a) where
  type CrdtRep  ('CrdtLwwReg a) = a
  data CrdtUpdate ('CrdtLwwReg a) = RegSet !a
  decodeState _ resp =
    case reg resp of
      Nothing -> fail "no lwwreg"
      Just c ->
        case decodeOrFail (Antidote.ApbGetRegResp.value c) of
          Left (_, offset, msg) -> fail ("at " ++ show offset ++ ": " ++ msg)
          Right (_, _, a)       -> return a
  encodeUpdate (RegSet x) =
    defaultVal{regop = Just $ ApbRegUpdate $ B.encode x}

incCounter :: Int -> CrdtUpdate 'CrdtCounter
incCounter = CounterInc

setReg :: a -> CrdtUpdate ('CrdtLwwReg a)
setReg = RegSet


-- TODO: Supports currently only one obj per read request
readCrdt :: IsCrdt t => CRDT t -> Adb (CrdtRep t)
readCrdt obj@(CRDT key bucket) = Adb $ do
  AdbState (AdbConn _ inStream outStream) d <- ask
  liftIO $ do
    let typ = singCrdtType obj
    let bo = ApbBoundObject key typ bucket
    writeRequest (ApbReadObjects (S.singleton bo) d) outStream
    resp <- readResponse inStream
    case S.viewl (objects resp) of
      (v S.:< _) -> case decodeState obj v of
        Left msg -> fail msg
        Right i -> return i
      _ -> fail "no object in read response"

updateCrdt :: IsCrdt t => CRDT t -> CrdtUpdate t -> Adb ()
updateCrdt obj@(CRDT key bucket) upd = Adb $ do
  AdbState (AdbConn _ inStream outStream) d <- ask
  liftIO $ do
    let typ = singCrdtType obj
        bo = ApbBoundObject key typ bucket
        op = ApbUpdateOp bo (encodeUpdate upd)
    writeRequest (ApbUpdateObjects (S.singleton op) d) outStream
    (ApbOperationResp _ _) <- readResponse inStream
    return ()

instance HasMessageCode ApbStartTransaction where
  messageCode _ = 119
instance HasMessageCode ApbStartTransactionResp where
  messageCode _ = 124

instance HasMessageCode ApbCommitTransaction where
  messageCode _ = 121
instance HasMessageCode ApbCommitResp where
  messageCode _ = 127

instance HasMessageCode ApbReadObjects where
  messageCode _ = 116
instance HasMessageCode ApbReadObjectsResp where
  messageCode _ = 126

instance HasMessageCode ApbUpdateObjects where
  messageCode _ = 118
instance HasMessageCode ApbOperationResp where
  messageCode _ = 111

test :: IO ()
test
  = withAdb cfg $ \ctx ->
      do c <- runAdbTxn ctx $ do
                updateCrdt obj (incCounter 1)
                x <- readCrdt obj
                updateCrdt robj (setReg x)
                readCrdt robj
         putStrLn (show c)
  where
    cfg = AdbConfig "127.0.0.1" 8087 3
    obj = counterCrdt "bucket" "x"
    robj = regCrdt "bucket" "y"
