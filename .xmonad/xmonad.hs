--------------------------------------------
-- ~/.xmonad/xmonad.hs
--
-- Jack Holborn (https://github.com/JackH79)
--
-- This Version: Apr 2012
--------------------------------------------

-- IMPORTS
import XMonad

import XMonad.Layout.Spacing              -- spaces around windows
import XMonad.Layout.NoBorders            -- no border for fullscreen layout
import XMonad.Layout.Named                -- custom layout names
import XMonad.Layout.Grid                 -- grid layout
import XMonad.Layout.MagicFocus           -- automagically switch focused window to master area
import XMonad.Layout.Minimize             -- minimise windows
import XMonad.Layout.ToggleLayouts        -- toggle layouts keybind

import XMonad.Actions.FindEmptyWorkspace  -- find next empty workspace
import XMonad.Actions.RotSlaves           -- rotates Windows anti-/clockwise
import XMonad.Actions.GridSelect          -- select windows via popup

import XMonad.Hooks.SetWMName             -- set WM name for java
import XMonad.Hooks.DynamicLog            -- output to dzen
import XMonad.Hooks.ManageDocks           -- don't touch the dock
import XMonad.Hooks.ManageHelpers         (isDialog, isFullscreen, doFullFloat, doCenterFloat)

import XMonad.Util.Run (spawnPipe)        -- spawnPipe for dzen

import Data.Monoid
import System.Exit
import System.IO (hPutStrLn)              -- hPutStrLn
import Control.Monad (liftM2)             -- for viewShift
import qualified XMonad.StackSet as W
import qualified Data.Map        as M

-- DEFAULTS
main = do
    status <- spawnPipe jackDzenStatus
    conky  <- spawnPipe jackDzenConky
    conky  <- spawnPipe jackDzenTime
    xmonad $ defaultConfig
        { terminal           = "urxvtc"
        , modMask            = mod4Mask
--      , borderWidth        = 2
        , normalBorderColor  = "#1a1a1a"
        , focusedBorderColor = "#329bcd"
        , focusFollowsMouse  = jackFocusFollowsMouse
        , workspaces         = jackWorkspaces
        , startupHook        = setWMName "LG3D"
        , layoutHook         = jackLayoutHook
        , manageHook         = jackManageHook
        , logHook            = jackLogHook status
        , handleEventHook    = docksEventHook
        , keys               = jackKeys
        }

-- RODENT RULES
jackFocusFollowsMouse :: Bool
jackFocusFollowsMouse = False

-- WORKSPACES
jackWorkspaces = [ "1-term" , "2-net" , "3-off", "4-vid" , "5-pic" , "6-music", "7-gimp" ] ++ map show [ 8..9 :: Int ]

-- LAYOUTS
jackLayoutHook = smartBorders $ toggleLayouts Full $ ( tile ||| focus ||| grid ||| full )
    where   tile  = named "tile"  $ avoidStruts $ spacing 5 $ minimize              $ Tall 1 (3/100) (1/2)
            focus = named "focus" $ avoidStruts $ spacing 5 $ minimize $ magicFocus $ Tall 1 (3/100) (3/4)
            grid  = named "grid"  $ avoidStruts $ spacing 5 $ minimize $ Grid
            full  = named "full"  $ noBorders   $ Full

-- HOOKS AND WINDOW RULES
jackManageHook :: ManageHook
jackManageHook = composeAll $ concat
    [ [ manageDocks                                      ]
    , [ jackRules                                        ]
    , [ manageHook defaultConfig                         ]
    , [ isDialog     --> doCenterFloat                   ]
    , [ isFullscreen --> doF W.focusDown <+> doFullFloat ]
    ]

jackRules = composeAll
    [ className =? "MPlayer"       --> (doFloat <+> viewShift "4-vid")
    , className =? "mplayer2"      --> (doFloat <+> viewShift "4-vid")
    , className =? "Galculator"    --> doFloat
    , className =? "Convertall.py" --> doFloat
    , className =? "LibreOffice"   --> viewShift "3-off"
    , className =? "Zathura"       --> viewShift "3-off"
    , className =? "Vlc"           --> viewShift "4-vid"
    , className =? "sxiv"          --> viewShift "5-pic"
    , className =? "Geeqie"        --> viewShift "5-pic"
    , className =? "Firefox"       --> viewShift "2-net"
    , className =? "Opera"         --> viewShift "2-net"
    , className =? "dwb"           --> viewShift "2-net"
    , title     =? "ncmpcpp"       --> viewShift "6-music"
    , title     =? "wicd-curses"   --> viewShift "9"
    , className =? "Gimp"          --> (doFloat <+> viewShift "7-gimp")
    , className =? "Xfce4-notifyd" --> doIgnore
    , className =? "dzen"          --> doIgnore
    ]
    where viewShift = doF . liftM2 (.) W.greedyView W.shift

-- DZEN2
jackLogHook h  = dynamicLogWithPP $ jackDzenPP { ppOutput = hPutStrLn h }
jackDzenStyle  = " -fg '#b2b2b2' -bg '#1a1a1a' -fn '-*-terminus-*-*-*-*-10-*-*-*-*-*-*-*'"
jackDzenStatus = "dzen2 -w '700' -ta 'l'" ++ jackDzenStyle
jackDzenConky  = "conky -c /home/jack/.xmonad/conkyrc | dzen2 -y '788' -w '1280' -ta 'r'" ++ jackDzenStyle
jackDzenTime   = "conky -c /home/jack/.xmonad/conkytime | dzen2 -x '700' -w '580' -ta 'r'" ++ jackDzenStyle
jackDzenPP     :: PP
jackDzenPP     = dzenPP
    { ppCurrent         = dzenColor "#1a1a1a" "#329bcd" . pad
    , ppHidden          = dzenColor "#b2b2b2" ""        . pad
    , ppHiddenNoWindows = dzenColor "#1a1a1a" ""        . pad
    , ppUrgent          = dzenColor "#ffffff" "#ee0000" . pad
    , ppLayout          = dzenColor "#9bcd32" ""        . pad
    , ppSep             = "^fg(#9bcd32)::^fg()"
    , ppTitle           = dzenColor "#329bcd" ""        . pad
    }

-- BINDINGS
jackKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
--  [ ((modm,                 xK_Return       ), spawn "urxvtc -e tmux")
    [ ((modm,                 xK_Return       ), spawn $ XMonad.terminal conf)
    , ((modm,                 xK_r            ), spawn "urxvtc -e ranger")
    , ((modm,                 xK_m            ), spawn "urxvtc -e ncmpcpp")
    , ((modm,                 xK_w            ), spawn "urxvtc -e wicd-curses")
    , ((modm,                 xK_i            ), spawn "urxvtc -e irssi")
    , ((modm,                 xK_grave        ), spawn "urxvtc -e htop")
    , ((modm,                 xK_c            ), spawn "urxvtc -e calc")
    , ((modm,                 xK_t            ), spawn "remind_call")
    , ((modm,                 xK_o            ), spawn "opera")
    , ((modm,                 xK_f            ), spawn "firefox")
    , ((modm,                 xK_d            ), spawn "dwb")
    , ((modm,                 xK_l            ), spawn "libreoffice")
    , ((modm .|. shiftMask,   xK_z            ), spawn "slock")
    , ((modm,                 xK_p            ), spawn "exe=`dmenu_run -fn -*-terminus-*-*-*-*-12-*-*-*-*-*-*-* -nb '#1a1a1a' -nf '#b2b2b2' -sb '#329bcd' -sf '#1a1a1a'` && eval \"exec $exe\"")
    -- Volume / MPD control
    , ((modm,                 xK_F7           ), spawn "mpc prev")
    , ((modm,                 xK_F8           ), spawn "mpc toggle")
    , ((modm,                 xK_F9           ), spawn "mpc next")
    , ((modm,                 xK_F10          ), spawn "amixer -q sset Master toggle")
    , ((modm,                 xK_F11          ), spawn "amixer -q sset Master 2dB-")
    , ((modm,                 xK_F12           ), spawn "amixer -q sset Master 2dB+")
    -- Windows
    , ((modm,                 xK_Left         ), windows W.focusDown)
    , ((modm,                 xK_Right        ), windows W.focusUp)
    , ((modm .|. shiftMask,   xK_Left         ), windows W.swapDown)
    , ((modm .|. shiftMask,   xK_Right        ), windows W.swapUp)
    , ((modm,                 xK_equal        ), viewEmptyWorkspace)
    , ((modm .|. shiftMask,   xK_equal        ), tagToEmptyWorkspace)
    , ((modm,                 xK_g            ), goToSelected defaultGSConfig)
    , ((modm .|. controlMask, xK_Left         ), sendMessage Shrink)
    , ((modm .|. controlMask, xK_Right        ), sendMessage Expand)
    , ((modm .|. shiftMask,   xK_r            ), refresh)
    -- rotate Windows anti-/clockwise
    , ((modm .|. shiftMask,   xK_bracketleft  ), rotAllUp)
    , ((modm .|. shiftMask,   xK_bracketright ), rotAllDown)
    -- maximise
    , ((modm .|. shiftMask,   xK_f            ), sendMessage ToggleLayout)
    -- minimise
    , ((modm,                 xK_n            ), withFocused minimizeWindow)
    , ((modm .|. shiftMask,   xK_n            ), sendMessage RestoreNextMinimizedWin)

    , ((modm .|. shiftMask,   xK_c            ), kill)
    -- swap focused window to master area
    , ((modm .|. shiftMask,   xK_Return       ), windows W.swapMaster)

    -- push window back into tiling
    , ((modm .|. shiftMask,   xK_t            ), withFocused $ windows . W.sink)
    -- change the number of windows in the master area
    , ((modm,                 xK_comma        ), sendMessage (IncMasterN 1))
    , ((modm,                 xK_period       ), sendMessage (IncMasterN (-1)))
    
    -- Layouts
    , ((modm,                 xK_space        ), sendMessage NextLayout)
    , ((modm .|. shiftMask,   xK_space        ), setLayout $ XMonad.layoutHook conf)
    
    -- XMonad
    , ((modm .|. shiftMask,   xK_r            ), spawn "killall conky dzen2; xmonad --recompile; xmonad --restart")
    , ((modm .|. shiftMask,   xK_q            ), io (exitWith ExitSuccess))
    ]
    ++
    -- Workspaces
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
    ]

-- vim:sw=4 sts=4 ts=4 tw=0 et ai
