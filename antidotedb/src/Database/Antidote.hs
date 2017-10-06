{-# LANGUAGE OverloadedStrings #-}
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

import qualified Data.Sequence as S
import Data.ProtoBuf as P
import Data.ProtoBufInt as P
import Network.Simple.TCP
import qualified Data.ByteString.Lazy as L
import Data.Binary as B
import Data.Binary.Put as B
import Data.Binary.Get as B



getHeader :: L.ByteString -> Word8 -> L.ByteString
getHeader bytes code = runPut $ do
     B.putInt32be $ fromIntegral $ L.length bytes + 1
     B.putWord8 code

test :: IO ()
test = do
  connect "127.0.0.1" "8087" $ \(s,_) -> do
    -- start txn
    let props = ApbTxnProperties Nothing Nothing
    let bytes = P.encode $ ApbStartTransaction Nothing (Just props)
    let header = getHeader bytes 119
    sendLazy s $ L.append header bytes
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
            let headerU = getHeader bytesU 118
            sendLazy s $ L.append headerU bytesU
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
                let headerR = getHeader bytesR 116
                sendLazy s $ L.append headerR bytesR
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
                          let bytesC = P.encode $ ApbCommitTransaction d
                          let headerC = getHeader bytesC 121
                          sendLazy s $ L.append headerC bytesC
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
