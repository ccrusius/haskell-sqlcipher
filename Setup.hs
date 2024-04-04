module Main where

import Distribution.Simple
import Distribution.Simple.Setup
import Distribution.Simple.Utils       (rawSystemExit)
import Distribution.PackageDescription
import System.Directory                (doesFileExist, withCurrentDirectory)
import Control.Monad                   (unless)
import qualified Distribution.Verbosity as V


type PreSDistHook = (Args -> SDistFlags -> IO HookedBuildInfo)


updatePreSDistHook :: (PreSDistHook -> PreSDistHook) -> UserHooks -> UserHooks
updatePreSDistHook update hooks = hooks

-- updatePreSDistHook :: (PreSDistHook -> PreSDistHook) -> UserHooks -> UserHooks
-- updatePreSDistHook update hooks@UserHooks{ preSDist = old }  = hooks { preSDist = update old }


configureSQLCipher :: PreSDistHook -> PreSDistHook
configureSQLCipher originalHook args flags@SDistFlags{ sDistVerbosity = verbosity } = do
    withCurrentDirectory "sqlcipher" $
        unlessFileExist "sqlite3.c" $ do
            let verbosity' = fromFlagOrDefault V.normal verbosity
            rawSystemExit verbosity' "./configure" 
                [ "--disable-tcl"
                , "--enable-tempstore"
                , "CFLAGS=-DSQLITE_HAS_CODEC"
                , "LDFLAGS=-lcrypto"]
            rawSystemExit verbosity' "make" []
    originalHook args flags
  where 
    unlessFileExist filePath action = doesFileExist filePath >>= flip unless action


main :: IO ()
main = defaultMainWithHooks $ updatePreSDistHook configureSQLCipher autoconfUserHooks
