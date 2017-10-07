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

instance HasMessageCode ApbStartTransaction where
  messageCode _ = 119
instance HasMessageCode ApbStartTransactionResp where
  messageCode _ = 124

instance HasMessageCode ApbCommitTransaction where
  messageCode _ = 121
instance HasMessageCode ApbCommitResp where
  messageCode _ = 127



test2 :: IO ()
test2
  = withAdb cfg $ \ctx ->
      do c <- runAdbTxn ctx $ do
                return ()
                --updateCrdt obj (incCounter 1)
                --readCrdt obj
         putStrLn (show c)
  where
    cfg = AdbConfig "127.0.0.1" 8087 3
    obj = counterCrdt "bucket" "x"

-- TODO: Add optional dependecy information
startTxnMsg =
  let props = ApbTxnProperties Nothing Nothing
  in ApbStartTransaction Nothing (Just props)

commitTxnMsg :: TxnDescriptor -> L.ByteString
commitTxnMsg d = buildMsg 121 $ P.encode $ ApbCommitTransaction d

-- FIXME: CRDT type!!
readMsg :: CRDT t -> TxnDescriptor -> L.ByteString
readMsg (CRDT bucket key) d =
  let bo = ApbBoundObject key Counter bucket
  in buildMsg 116 $ P.encode $ ApbReadObjects (S.singleton bo) $ d


buildMsg :: Word8 -> L.ByteString ->  L.ByteString
buildMsg code bytes=
  let header = runPut $ do
      B.putInt32be $ fromIntegral $ L.length bytes + 1
      B.putWord8 code
  in L.append header bytes

test :: IO ()
test = do
  Network.Simple.TCP.connect "127.0.0.1" "8087" $ \(s,_) -> do
    -- start txn
    sendLazy s $ P.encode startTxnMsg
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
            let bo = ApbBoundObject "key" Counter "bucket"
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
