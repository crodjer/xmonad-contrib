{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
module XMonad.Config.Sjanssen (sjanssenConfig, sjanssenConfigXmobar) where

import XMonad hiding (Tall(..))
import qualified XMonad.StackSet as W
import XMonad.Actions.CopyWindow
import XMonad.Layout.Tabbed
import XMonad.Layout.HintedTile
import XMonad.Config (defaultConfig)
import XMonad.Layout.NoBorders
import XMonad.Hooks.DynamicLog hiding (xmobar)
import XMonad.Hooks.ManageDocks
import XMonad.Prompt
import XMonad.Prompt.Shell

import qualified Data.Map as M

sjanssenConfigXmobar = statusBar "xmobar" sjanssenPP strutkey sjanssenConfig
 where
    strutkey (XConfig {modMask = modm}) = (modm, xK_b)

sjanssenConfig = 
    defaultConfig
        { terminal = "urxvtc"
        , workspaces = ["irc", "web"] ++ map show [3 .. 9 :: Int]
        , mouseBindings = \(XConfig {modMask = modm}) -> M.fromList $
                [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w))
                , ((modm, button2), (\w -> focus w >> windows W.swapMaster))
                , ((modm.|. shiftMask, button1), (\w -> focus w >> mouseResizeWindow w)) ]
        , keys = \c -> mykeys c `M.union` keys defaultConfig c
        , layoutHook = modifiers layouts
        , manageHook = composeAll [className =? x --> doF (W.shift w)
                                    | (x, w) <- [ ("Firefox", "web")
                                                , ("Ktorrent", "7")]]
                       <+> manageHook defaultConfig <+> manageDocks
        }
 where
    tiled     = HintedTile 1 0.03 0.5 TopLeft
    layouts   = (tiled Tall ||| (tiled Wide ||| Full)) ||| tabbed shrinkText myTheme
    modifiers = smartBorders

    mykeys (XConfig {modMask = modm, workspaces = ws}) = M.fromList $
        [((modm,               xK_p     ), shellPrompt myPromptConfig)
        ,((modm .|. shiftMask, xK_c     ), kill1)
        ,((modm .|. shiftMask .|. controlMask, xK_c     ), kill)
        ,((modm .|. shiftMask, xK_0     ), windows $ \w -> foldr copy w ws)
        ]

    myFont = "xft:Bitstream Vera Sans Mono:pixelsize=10"
    myTheme = defaultTheme { fontName = myFont }
    myPromptConfig = defaultXPConfig
                        { position = Top
                        , font = myFont
                        , showCompletionOnTab = True
                        , promptBorderWidth = 0 }
