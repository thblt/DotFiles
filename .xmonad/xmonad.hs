{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Main (main) where

import           Data.Int
import qualified Data.Map as M
import           Data.Maybe (isJust)
import           Data.Typeable
import           Language.Haskell.TH
import           System.Posix.Unistd                 (SystemID (nodeName),
                                                      getSystemID)
import           XMonad
import           XMonad.Actions.Navigation2D
import           XMonad.Actions.WindowBringer (bringMenu, gotoMenu)
import           XMonad.Hooks.EwmhDesktops (ewmh)
import           XMonad.Hooks.FadeInactive (fadeInactiveLogHook)
import           XMonad.Hooks.ManageDocks            (ToggleStruts (ToggleStruts),
                                                      avoidStruts,
                                                      docksEventHook,
                                                      manageDocks)
import           XMonad.Hooks.ManageDocks (ToggleStruts (ToggleStruts))
import           XMonad.Hooks.ManageDocks (docksEventHook, manageDocks)
import           XMonad.Hooks.ManageHelpers (isDialog)
import           XMonad.Hooks.Place (placeHook, smart, withGaps)
import           XMonad.Hooks.SetWMName (setWMName)
import           XMonad.Layout.BinarySpacePartition  (ResizeDirectional (..),
                                                      Rotate (Rotate),
                                                      SelectMoveNode (..),
                                                      TreeBalance (..),
                                                      emptyBSP)
import           XMonad.Layout.BorderResize (borderResize)
import           XMonad.Layout.Fullscreen
import           XMonad.Layout.Gaps
import           XMonad.Layout.IfMax
import           XMonad.Layout.MultiToggle
import           XMonad.Layout.MultiToggle.Instances
import           XMonad.Layout.NoBorders (withBorder)
import           XMonad.Layout.NoFrillsDecoration
import           XMonad.Layout.Spacing (smartSpacingWithEdge)
import           XMonad.Util.NamedScratchpad (namedScratchpadManageHook)
--import         XMonad.Actions.CycleWS              (nextWS, prevWS)
--import           XMonad.Actions.MessageFeedback -- READ BELOW.
--Note to self: this is broken.  The messages get correctly sent, but the view doesn't update.  You have to move focus or do something else.
import           XMonad.Hooks.EwmhDesktops (ewmh)
import           XMonad.Hooks.FadeInactive (fadeInactiveLogHook)
import           XMonad.Hooks.ManageHelpers (isDialog)
import           XMonad.Hooks.Place (placeHook, withGaps, smart)
import           XMonad.Hooks.SetWMName (setWMName)

import           XMonad.Layout.Fullscreen (fullscreenSupport)
import           XMonad.Layout.MultiToggle
import           XMonad.Layout.MultiToggle.Instances
import           XMonad.Layout.NoFrillsDecoration
import qualified XMonad.StackSet as XSS

import           XMonad.Util.EZConfig (mkKeymap)
import           XMonad.Util.NamedScratchpad
import           XMonad.Util.NamedWindows (getName)
import           XMonad.Util.Run (spawnPipe)
import           XMonad.Util.WorkspaceCompare (getSortByIndex)

-- Computer-dependent settings.

[d| hostname = $(stringE =<< runIO (fmap nodeName getSystemID) ) |]

workspacesKeys :: [KeySym]
workspacesKeys | hostname == "anna"    = macAzertyKeys
               | hostname == "rudiger" = pcAzertyBeKeys
               | otherwise               = pcAzertyKeys
  where
    pcAzertyKeys = [0x26,0xe9,0x22,0x27,0x28,0x2d,0xe8,0x5f,0xe7,0xe0] -- From AzertyConfig
    pcAzertyBeKeys = [0x26,0xe9,0x22,0x27,0x28,0xa7,0xe8,0x21,0xe7,0xe0] -- From AzertyConfig
    macAzertyKeys = [0x26,0xe9,0x22,0x27,0x28,0xa7,0xe8,0x21,0xe7,0xe0] -- From AzertyConfig

-- XMonad.

myWorkspaces :: [ String ]
myWorkspaces = map show [ 1 .. 9  :: Int ]

myHiddenWorkspaces :: [ String ]
myHiddenWorkspaces = [ "NSP" ]

myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList
    [
      ((modMask, 1), \w -> focus w >> mouseMoveWindow w
                                 >> windows XSS.shiftMaster)
--    , ((0, 10), const $ prevWS) -- Three-finger left swipe
--    , ((0, 11), const $ nextWS) -- Three finger right swipe
    ]

myScratchpads :: [NamedScratchpad]
myScratchpads = [
  NS "term" "alacritty --title urxvt_scratchpad_1545645 -e ~/.xmonad/scripts/tmux-attach-or-new scratch" (title =? "urxvt_scratchpad_1545645")
  (customFloating rect)
  ]
  where ratio = 24
        rect = XSS.RationalRect (1/ratio) (1/ratio) ((ratio-2)/ratio) ((ratio-2)/ratio)

data MySpacing = MySpacing {
  myGaps       :: Int,
  myBorderSize :: Int,
  myDecoHeight :: Int
  }

data MyTransformers = GAPS deriving (Read, Show, Eq, Typeable)
instance Transformer MyTransformers Window where
  transform GAPS x k = k (smartSpacingWithEdge (negate $ myGaps mySpacing) $ x) (const x)

-- The layouts I use
myBSP = emptyBSP
myTall = Mirror $ Tall 1 (3/100) (3/4)

myLayoutHook = avoidStruts $ mkToggle (FULL ?? GAPS ?? EOT) $
               ifMax 1 Full $
               borderResize
               . myDecoration
               . smartSpacingWithEdge (myGaps mySpacing)
               . withBorder (fromIntegral $ myBorderSize mySpacing) $
               myBSP ||| myTall

myDecoration = id
-- myDecoration = noFrillsDeco shrinkText def {
--   decoHeight = (fromIntegral $ myDecoHeight mySpacing)
--   , activeColor = myActiveColor
--   , activeTextColor = "#ffffff"
--   , activeBorderColor = "#000000"
--   , inactiveColor = myInactiveColor
--   , inactiveTextColor = myInactiveColor
--   , inactiveBorderColor = myInactiveColor
--   , fontName = "DejaVuSansMono-24"
--   }

-- mySpacing :: MySpacing
-- mySpacing | hostname == "rudiger" = MySpacing 2 2 0
--           | otherwise = MySpacing 2 2 0

mySpacing :: MySpacing
mySpacing = case hostname of
  "maladict" -> MySpacing 8 2 16
  _ -> MySpacing 4 0 0

myActiveColor = "#0059DD"
myInactiveColor = "#000000"

myKeys :: [KeySym] -> [NamedScratchpad] -> XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys workspaceKeys scratchpads = \conf -> M.union (baseKeys scratchpads conf) (extraKeys workspaceKeys conf)

baseKeys :: [NamedScratchpad] -> XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
baseKeys scratchpads conf@XConfig { XMonad.modMask = modMask } =
  mkKeymap conf $
  [
    ("M-S-c"                     , kill),
    ("M-S-q"                     , spawn "/home/thblt/.xmonad/scripts/stop"),
    ("M-q"                       , restart "xmonad" True),
    ("M-<Esc>"                   , spawn "light-locker-command --lock"),
    ("M-S-<Esc>"                 , spawn "light-locker-command --lock"),

    ("M-<Space>"                 , sendMessage NextLayout),
    ("M-S-<Space>"               , setLayout $ XMonad.layoutHook conf), -- (Reset)

    ("M-h"                       , sendMessage Shrink),
    ("M-l"                       , sendMessage Expand),

    ("M-f f"                     , sendMessage $ Toggle FULL),
    ("M-f x"                     , sendMessage $ Toggle GAPS),
    ("M-f s"                     , sendMessage ToggleStruts),

    ("M-="                       , sendMessage $ IncMasterN 1),
    ("M-:"                       , sendMessage $ IncMasterN (-1)),

    -- Navigation2D
    ("M-<Up>"                    , windowGo U False),
    ("M-<Right>"                 , windowGo R False),
    ("M-<Down>"                  , windowGo D False),
    ("M-<Left>"                  , windowGo L False),

    ("M-S-<Up>"                  , windowSwap U False),
    ("M-S-<Right>"               , windowSwap R False),
    ("M-S-<Down>"                , windowSwap D False),
    ("M-S-<Left>"                , windowSwap L False),

    -- BSP-specific
    ("M-S-h"                     , sendMessage $ ExpandTowards L),
    ("M-S-j"                     , sendMessage $ ExpandTowards D),
    ("M-S-k"                     , sendMessage $ ExpandTowards U),
    ("M-S-l"                     , sendMessage $ ExpandTowards R),

    ("M-C-h"                     , sendMessage $ ShrinkFrom L),
    ("M-C-j"                     , sendMessage $ ShrinkFrom D),
    ("M-C-k"                     , sendMessage $ ShrinkFrom U),
    ("M-C-l"                     , sendMessage $ ShrinkFrom R),

    ("M-w"                       , sendMessage SelectNode),
    ("M-x"                       , sendMessage MoveNode),

    ("M-r"                       , sendMessage Rotate),

    ("M-<Tab>"                   , windows XSS.focusDown),
    ("M-S-<Tab>"                 , windows XSS.focusUp),

    ("M-<Return>"                , windows XSS.swapMaster),
    ("M-t"                       , withFocused $ windows . XSS.sink),

    ("M-p"                       , spawn "~/.local/bin/dmenu-desktop --entry-type=name"),
    ("M-C-S-<Return>"            , spawn $ terminal conf),
    ("M-S-<Return>"              , spawn $ "~/.xmonad/scripts/emacsclient-with-feedback"),
    ("M-s"                       , namedScratchpadAction scratchpads "term"),
    -- Volume
    ("<XF86AudioLowerVolume>"    , spawn $ "amixer -c 0 set Master unmute ; amixer -c 0 set Master 2-; " ++ shNotifyVolume),
    ("<XF86AudioRaiseVolume>"    , spawn $ "amixer -c 0 set Master unmute ; amixer -c 0 set Master 2+; " ++ shNotifyVolume),
    ("<XF86AudioMute>"           , spawn $ "amixer set Master toggle; " ++ shNotifyVolume),

    -- Brightness (monitor)
    ("<XF86MonBrightnessUp>"     , spawn "light -A 5"),
    ("S-<XF86MonBrightnessUp>"   , spawn "light -A 1"),
    ("<XF86MonBrightnessDown>"   , spawn "light -U 5"),
    ("S-<XF86MonBrightnessDown>" , spawn "light -U 1"),

    -- Brightness (keyboard backlight)
    ("<XF86KdbBrightnessUp>"     , spawn "sudo anybrightness keyboard +20%"),
    ("<XF86KdbBrightnessDown>"   , spawn "sudo anybrightness keyboard +20%")]
  where
    shNotifyVolume = "notify-send Volume `amixer get Master | tail -n 1  | awk '{print $6}'` -t 250 -h string:fgcolor:#ffffff -h string:bgcolor:#000000 -h int:value:`amixer get Master | tail -n 1 | awk '{print $4}' | sed 's/[^0-9]//g'`"

  -- workspace switching
extraKeys :: [KeySym] -> XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
extraKeys workspaceKeys conf@XConfig {XMonad.modMask = modMask} =
  M.fromList $
  [((m .|. modMask, k), windows $ f i)
  | (i, k) <- zip (XMonad.workspaces conf) workspaceKeys
  , (f, m) <- [(XSS.greedyView, 0), (XSS.shift, shiftMask)]]
  ++
  -- mod-{a,z,e} %! Switch to physical/Xinerama screens 1, 2, or 3
  -- mod-shift-{a,z,e} %! Move client to screen 1, 2, or 3
  [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
  | (key, sc) <- zip [xK_a, xK_z, xK_e] [0..]
  , (f, m) <- [(XSS.view, 0), (XSS.shift, shiftMask)]]

main :: IO ()
main = do
--dbus <- connectSession
--getWellKnownName dbus

  xmonad
    -- . fullscreenSupport -- Removed until contrib issue #278 is solved
    . withNavigation2DConfig def {
    defaultTiledNavigation = centerNavigation -- default lineNavigation is broken with BSP + smartSpacing
  } $ ewmh def {
      borderWidth = 0 -- Borders are added in the layout hook
    , focusedBorderColor = myActiveColor
    , normalBorderColor = myInactiveColor
    , clickJustFocuses = False
    , focusFollowsMouse = False
    --    , handleEventHook = fullscreenEventHook <+> docksEventHook
    , handleEventHook = docksEventHook
    , keys = myKeys workspacesKeys myScratchpads
    , mouseBindings = myMouseBindings
    , layoutHook = myLayoutHook
    , logHook = do
--        dbusLogger dbus
--        dynamicLogWithPP$ myPP dbus -- logPipe
        fadeInactiveLogHook 0.95
    , manageHook = composeAll
      [
        namedScratchpadManageHook myScratchpads
      , placeHook $ withGaps (16,0,16,0) (smart (0.5,0.5))
      , manageDocks
      , isDialog --> doFloat
      , title =? "Invoking Emacs daemon…" --> doFloat
      , title =? "Helm" --> doFloat
      , className =? "Gloobus-preview"    --> doFloat
      , className =? "Pinentry"           --> doFloat
      , className =? "Xdialog"            --> doFloat
      , className =? "Yad"                --> doFloat
      , className =? "zenity"             --> doFloat
      , className =? "zbar"               --> doFloat
        ]
    , modMask = mod4Mask -- ``Windows'' key.
    , startupHook = spawn "~/.xmonad/scripts/start" <+> setWMName "LG3D"
    , terminal = "alacritty"
    , workspaces = myWorkspaces
    }
