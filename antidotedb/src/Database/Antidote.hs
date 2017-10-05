module Database.Antidote where

import Antidote.ApbCounterUpdate
import Antidote.ApbStartTransaction
import Antidote.ApbStartTransactionResp


import Data.ProtoBuf as P
import Network.Simple.TCP
import qualified Data.ByteString.Lazy as L
import Data.Binary as B
import Data.Binary.Put as B
import Data.Binary.Get as B


test :: IO ()
test = do
  connect "127.0.0.1" "8087" $ \(s,_) -> do
    let bytes = L.empty -- P.encode $ ApbStartTransaction Nothing Nothing
    sendLazy s $ B.runPut $ do
      B.putInt32be $ fromIntegral $ 1 -- L.length bytes + 1
      B.putWord8 119
      -- B.put bytes
    mbs <- recv s 5
    case mbs of
      Just bs -> do
        let g = do
            laenge <- B.getInt32be
            code   <- getWord8 -- 124
            if code /= 124 then fail $ "bad code: " ++ show code ++ " length: " ++ show laenge else return laenge
        let laenge = runGet g $ L.fromStrict bs
        content <- recv s $ fromIntegral laenge
        case content of
          Just c -> putStrLn $ show $ ((P.decode $ L.fromStrict c) :: Either String ApbStartTransactionResp)
