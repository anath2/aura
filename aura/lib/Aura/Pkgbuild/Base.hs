{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module    : Aura.Pkgbuild.Base
-- Copyright : (c) Colin Woodbury, 2012 - 2018
-- License   : GPL3
-- Maintainer: Colin Woodbury <colin@fosskers.ca>

module Aura.Pkgbuild.Base
  ( -- * Paths
    pkgbuildCache
  , pkgbuildPath
  ) where

import           Aura.Types
import qualified Data.Text as T
import           System.Path (Path, Absolute, FileExt(..), fromAbsoluteFilePath, fromUnrootedFilePath, (</>), (<.>))

---

-- | The default location: \/var\/cache\/aura\/pkgbuilds\/
pkgbuildCache :: Path Absolute
pkgbuildCache = fromAbsoluteFilePath "/var/cache/aura/pkgbuilds/"

-- | The expected path to a stored PKGBUILD, given some package name.
pkgbuildPath :: PkgName -> Path Absolute
pkgbuildPath (PkgName p) = pkgbuildCache </> fromUnrootedFilePath (T.unpack p) <.> FileExt "pb"
