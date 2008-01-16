{-# OPTIONS_GHC -fglasgow-exts #-}

-- for now, use -fglasgow-exts for compatibility with ghc 6.6, which chokes
-- on some of the LANGUAGE pragmas below
{- LANGUAGE FlexibleInstances, MultiParamTypeClasses, DeriveDataTypeable, TypeSynonymInstances -}

-----------------------------------------------------------------------------
-- |
-- Module      :  XMonad.Layout.Reflect
-- Copyright   :  (c) Brent Yorgey
-- License     :  BSD-style (see LICENSE)
--
-- Maintainer  :  <byorgey@gmail.com>
-- Stability   :  unstable
-- Portability :  unportable
--
-- Reflect a layout horizontally or vertically.
-----------------------------------------------------------------------------

module XMonad.Layout.Reflect (
                               -- * Usage
                               -- $usage

                               reflectHoriz, reflectVert,
                               REFLECTX(..), REFLECTY(..)

                             ) where

import XMonad.Core
import Graphics.X11 (Rectangle(..), Window)
import Control.Arrow ((***), second)
import Control.Applicative ((<$>))

import XMonad.Layout.MultiToggle

-- $usage
-- You can use this module by importing it into your @~\/.xmonad\/xmonad.hs@ file:
--
-- > import XMonad.Layout.Reflect
--
-- and modifying your layoutHook as follows (for example):
--
-- > layoutHook = reflectHoriz $ Tall 1 (3/100) (1/2)  -- put master pane on the right
--
-- 'reflectHoriz' and 'reflectVert' can be applied to any sort of
-- layout (including Mirrored layouts) and will simply flip the
-- physical layout of the windows vertically or horizontally.
--
-- "XMonad.Layout.MultiToggle" transformers are also provided for
-- toggling layouts between reflected\/non-reflected with a keybinding.
-- To use this feature, you will also need to import the MultiToggle
-- module:
--
-- > import XMonad.Layout.MultiToggle
--
-- Next, add one or more toggles to your layout.  For example, to allow
-- separate toggling of both vertical and horizontal reflection:
--
-- > layoutHook = mkToggle (REFLECTX ?? EOT) $
-- >              mkToggle (REFLECTY ?? EOT) $
-- >                (tiled ||| Mirror tiled ||| ...) -- whatever layouts you use
--
-- Finally, add some keybindings to do the toggling, for example:
--
-- > , ((modMask x .|. controlMask, xK_x), sendMessage $ Toggle REFLECTX)
-- > , ((modMask x .|. controlMask, xK_y), sendMessage $ Toggle REFLECTY)
--

-- | Apply a horizontal reflection (left \<--\> right) to a
--   layout.
reflectHoriz :: (LayoutClass l a) => (l a) -> Reflect l a
reflectHoriz = Reflect Horiz

-- | Apply a vertical reflection (top \<--\> bottom) to a
--   layout.
reflectVert :: (LayoutClass l a) => (l a) -> Reflect l a
reflectVert = Reflect Vert

data ReflectDir = Horiz | Vert
  deriving (Read, Show)

-- | Given an axis of reflection and the enclosing rectangle which
--   contains all the laid out windows, transform a rectangle
--   representing a window into its flipped counterpart.
reflectRect :: ReflectDir -> Rectangle -> Rectangle -> Rectangle
reflectRect Horiz (Rectangle sx _ sw _) (Rectangle rx ry rw rh) =
  Rectangle (2*sx + fi sw - rx - fi rw) ry rw rh
reflectRect Vert (Rectangle _ sy _ sh) (Rectangle rx ry rw rh) =
  Rectangle rx (2*sy + fi sh - ry - fi rh) rw rh

fi :: (Integral a, Num b) => a -> b
fi = fromIntegral


data Reflect l a = Reflect ReflectDir (l a) deriving (Show, Read)

instance LayoutClass l a => LayoutClass (Reflect l) a where

    -- do layout l, then reflect all the generated Rectangles.
    doLayout (Reflect d l) r s = (map (second (reflectRect d r)) *** fmap (Reflect d))
                                 <$> doLayout l r s

    -- pass messages on to the underlying layout
    handleMessage (Reflect d l) = fmap (fmap (Reflect d)) . handleMessage l

    description (Reflect d l) = "Reflect" ++ xy ++ " " ++ description l
      where xy = case d of { Horiz -> "X" ; Vert -> "Y" }


-------- instances for MultiToggle ------------------

data REFLECTX = REFLECTX deriving (Read, Show, Eq, Typeable)
data REFLECTY = REFLECTY deriving (Read, Show, Eq, Typeable)

instance Transformer REFLECTX Window where
    transform REFLECTX x k = k (reflectHoriz x)

instance Transformer REFLECTY Window where
    transform REFLECTY x k = k (reflectVert x)