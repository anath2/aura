{-# LANGUAGE OverloadedStrings #-}

{-

Copyright 2012 - 2018 Colin Woodbury <colin@fosskers.ca>

This file is part of Aura.

Aura is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Aura is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Aura.  If not, see <http://www.gnu.org/licenses/>.

-}

module Settings
    ( getSettings ) where
    -- , debugOutput ) where

import           Aura.Languages
import           Aura.Pacman
import           Aura.Settings.Base
import           Aura.Types
import           BasePrelude hiding (FilePath)
import           Data.Bitraversable
import qualified Data.Map.Strict as M
import qualified Data.Text as T
import qualified Data.Text.IO as T
import           Flags (Program(..))
import           Network.HTTP.Client (newManager)
import           Network.HTTP.Client.TLS (tlsManagerSettings)
import           Shelly
import           System.Environment (getEnvironment)
import           Utilities

---

getSettings :: Program -> IO (Either Failure Settings)
getSettings (Program _ co bc lng) = do
  confFile <- getPacmanConf
  join <$> bitraverse pure f confFile
  where f confFile = do
          environment <- M.fromList . map (bimap T.pack T.pack) <$> getEnvironment
          buildPath'  <- checkBuildPath (buildPathOf bc) (getCachePath confFile)
          manager     <- newManager tlsManagerSettings
          let language   = checkLang lng environment
              buildUser' = buildUserOf bc <|> getTrueUser environment
          pure $ do
            bu <- maybe (failure whoIsBuildUser_1) Right buildUser'
            Right Settings { managerOf      = manager
                           , envOf          = environment
                           , langOf         = language
                           , editorOf       = getEditor environment
                           , commonConfigOf =
                             co { cachePathOf = cachePathOf co <|> Just (getCachePath confFile)
                                , logPathOf   = logPathOf co   <|> Just (getLogFilePath confFile)
                                }
                           , buildConfigOf  =
                             bc { buildPathOf   = Just buildPath'
                                , buildUserOf   = Just bu
                                , ignoredPkgsOf = getIgnoredPkgs confFile <> ignoredPkgsOf bc
                                }
                           }

{-
debugOutput :: Settings -> IO ()
debugOutput ss = do
  let yn a = if a then "Yes!" else "No."
      env  = envOf ss
  traverse_ T.putStrLn [ "User              => " <> fromMaybe "Unknown!" (M.lookup "USER" env)
                       , "True User         => " <> fromMaybe "Unknown!" (getTrueUser env)
                       , "Build User        => " <> _user (buildUserOf ss)
                       , "Using Sudo?       => " <> yn (M.member "SUDO_USER" env)
                       , "Pacman Flags      => " <> T.unwords (pacOptsOf ss)
                       , "Other Flags       => " <> T.unwords (otherOptsOf ss)
                       , "Other Input       => " <> T.unwords (inputOf ss)
                       , "Language          => " <> T.pack (show $ langOf ss)
                       , "Pacman Command    => " <> pacmanCmdOf ss
                       , "Editor            => " <> editorOf ss
                       , "Ignored Pkgs      => " <> T.unwords (ignoredPkgsOf ss)
                       , "Build Path        => " <> toTextIgnore (buildPathOf ss)
                       , "Pkg Cache Path    => " <> toTextIgnore (cachePathOf ss)
                       , "Log File Path     => " <> toTextIgnore (logFilePathOf ss)
                       , "Quiet?            => " <> yn (beQuiet ss)
                       , "Suppress Makepkg? => " <> T.pack (show $ suppressMakepkg ss)
                       , "Must Confirm?     => " <> yn (mustConfirm ss)
                       , "Needed only?      => " <> yn (neededOnly ss)
                       , "PKGBUILD editing? => " <> yn (mayHotEdit ss)
                       , "Diff PKGBUILDs?   => " <> yn (diffPkgbuilds ss)
                       , "Rebuild Devel?    => " <> yn (rebuildDevel ss)
                       , "Use Customizepkg? => " <> yn (useCustomizepkg ss)
                       , "Forego PowerPill? => " <> yn (noPowerPill ss)
                       , "Keep source?      => " <> yn (keepSource ss) ]
-}

checkLang :: Maybe Language -> Environment -> Language
checkLang Nothing env   = langFromLocale $ getLocale env
checkLang (Just lang) _ = lang

checkBuildPath :: MonadIO m => Maybe FilePath -> FilePath -> m FilePath
checkBuildPath Nothing def   = pure def
checkBuildPath (Just bp) def = bool def bp <$> shelly (test_d bp)
