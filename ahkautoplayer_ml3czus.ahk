; Auto-player for Roblox
; Created by @ml3czus_
Version := "0.3.5"

; --- Global variables ---
CurrentLoop := 0
LoopLimit := 1
Paused := false
StopPlay := false
isPlaying := false
Songs := []
url := "https://mleczus-autoplayer.vercel.app/songs.json"
LatestScriptURL := "https://mleczus-autoplayer.vercel.app/auto-player.ahk"

; --- JSON parser (simple embedded) ---
; coz autohotkey didn't have one so i needed to use chatgpt to import one here
JSON_Parse(str) {
    pos := 1
    return JSON_ParseValue(str, pos)
}
JSON_ParseValue(str, ByRef pos) {
    SkipWhitespace(str, pos)
    if (SubStr(str, pos, 1) = "{")
        return JSON_ParseObject(str, pos)
    else if (SubStr(str, pos, 1) = "[")
        return JSON_ParseArray(str, pos)
    else if (SubStr(str, pos, 1) = """")
        return JSON_ParseString(str, pos)
    else if (RegExMatch(SubStr(str, pos), "^\d", m))
        return JSON_ParseNumber(str, pos)
    else if (SubStr(str, pos, 4) = "true") {
        pos += 4
        return true
    } else if (SubStr(str, pos, 5) = "false") {
        pos += 5
        return false
    } else if (SubStr(str, pos, 4) = "null") {
        pos += 4
        return ""
    }
    return ""
}
SkipWhitespace(str, ByRef pos) {
    while (pos <= StrLen(str) && InStr(" `t`n`r", SubStr(str, pos, 1)))
        pos++
}
JSON_ParseObject(str, ByRef pos) {
    obj := {}
    pos++
    SkipWhitespace(str, pos)
    while (pos <= StrLen(str) && SubStr(str, pos, 1) != "}") {
        key := JSON_ParseString(str, pos)
        SkipWhitespace(str, pos)
        pos++
        SkipWhitespace(str, pos)
        val := JSON_ParseValue(str, pos)
        obj[key] := val
        SkipWhitespace(str, pos)
        if (SubStr(str, pos, 1) = ",")
            pos++
        SkipWhitespace(str, pos)
    }
    pos++
    return obj
}

JSON_ParseArray(str, ByRef pos) {
    arr := []
    pos++
    SkipWhitespace(str, pos)
    while (pos <= StrLen(str) && SubStr(str, pos, 1) != "]") {
        val := JSON_ParseValue(str, pos)
        arr.Push(val)
        SkipWhitespace(str, pos)
        if (SubStr(str, pos, 1) = ",")
            pos++
        SkipWhitespace(str, pos)
    }
    pos++
    return arr
}
JSON_ParseString(str, ByRef pos) {
    pos++
    result := ""
    while (pos <= StrLen(str)) {
        ch := SubStr(str, pos, 1)
        if (ch = "\") {
            pos++
            nextChar := SubStr(str, pos, 1)
            if (nextChar = "n")
                result .= "`n"
            else if (nextChar = "r")
                result .= "`r"
            else if (nextChar = "t")
                result .= "`t"
            else if (nextChar = """")
                result .= """"
            else if (nextChar = "/")
                result .= "/"
            else if (nextChar = "b")
                result .= Chr(8)
            else if (nextChar = "f")
                result .= Chr(12)
            else
                result .= nextChar
            pos++
            continue
        }
        if (ch = """") {
            pos++
            return result
        }
        result .= ch
        pos++
    }
    return ""
}
JSON_ParseNumber(str, ByRef pos) {
    re := "^\-?\d+(\.\d+)?([eE][+\-]?\d+)?"
    if RegExMatch(SubStr(str, pos), re, m)
    {
        val := m.Value
        pos += StrLen(val)
        return val + 0
    }
    return 0
}

; --- Menu Bar ---
Menu, FileMenu, Add, Load from File`tCtrl+O, LoadFromFile
Menu, FileMenu, Add, Reload Online Sheets, ReloadOnlineSheets
Menu, FileMenu, Add, Open Trello Board, OpenTrelloBoard
Menu, FileMenu, Add
Menu, FileMenu, Add, Exit`tAlt+F4, GuiClose

Menu, HelpMenu, Add, Check for Updates, CheckForUpdates
Menu, HelpMenu, Add, About, AboutPage

Menu, MenuBar, Add, File, :FileMenu
Menu, MenuBar, Add, Help, :HelpMenu
Gui, Menu, MenuBar

; --- Sheet ---
Gui, Add, GroupBox, x10 y5 w320 h170 Center, Piano/Guitar Sheet
Gui, Add, Edit, R10 x20 y25 w300 h130 vSheet, Insert your Piano/Guitar sheet here :3

; --- Settings ---
Gui, Add, GroupBox, x10 y175 w320 h150 Center, Settings
Gui, Add, Checkbox, x20 y195 w130 vEnableToolboxOption Checked, Enable Toolbox
Gui, Add, Checkbox, x20 y215 w120 vUsePauseDelay gTogglePauseDelay, Manual Pause Delay
Gui, Add, Checkbox, x20 y235 w120 vUseKeyDelay gToggleKeyDelay, Manual Key Delay
Gui, Add, Edit, x140 y212 w180 vPauseDelay Disabled, Set value here (0-500 | Default: 100)
Gui, Add, Edit, x140 y232 w180 vKeyDelay Disabled, Set value here (0-500 | Default: 200)
Gui, Add, Checkbox, x20 y255 w100 vUseLoop gToggleLoop, Loop
Gui, Add, Radio, x40 y275 w130 vLoopOptionInfinity gLoopOptionChanged Disabled, Infinite Loop
Gui, Add, Radio, x40 y295 w130 vLoopOptionLimit gLoopOptionChanged Disabled, Limit Loops:
Gui, Add, Edit, x170 y292 w60 vLoopCount Disabled, 1+

; --- Info ---
Gui, Add, GroupBox, x10 y325 w320 h60 Center, Info
Gui, Add, Text, x30 y340 w280 Center, F4 To Play`nPress F7 To Stop`nPress F8 To Pause/Resume

; --- Online Sheets ---
Gui, Add, GroupBox, x340 y5 w280 h380 Center, Online Sheets
Gui, Add, ListBox, r26 x350 y25 w260 vSheetList AltSubmit gSheetList,

; --- Gui ---
Gui, Add, StatusBar,, Ready.
Gui, Color, FFFFFF
Gui, Show, w630 h415, Auto-player for Roblox

CheckForUpdates(false)
LoadSongsFromURL(url)
return

; --- Load from File ---
^o::
LoadFromFile:
    SB_SetText("Loading file...")

    SetTimer, ClearStatusBar, Off

    FileSelectFile, SelectedFile, 3,, Open a Sheet File, Text Documents (*.txt)
    if (!SelectedFile) {
        SB_SetText("No file selected.")
        SetTimer, ClearStatusBar, -3000
        return
    }

    SplitPath, SelectedFile, FileNameOnly, FileDir, FileExt
    
    if (FileExt != "txt") {
        SB_SetText("Only .txt files are supported.")
        SetTimer, ClearStatusBar, -3000
        return
    }

    FileRead, FileContent, %SelectedFile%

    GuiControl,, Sheet, %FileContent%
    SB_SetText("Loaded file: " . FileNameOnly)

    SetTimer, ClearStatusBar, -3000
return

ClearStatusBar:
    SB_SetText("Ready.")
return

; --- ListBox selection changed ---
SheetList:
    selectedIndex := A_EventInfo
    if (selectedIndex > 0) {
        selectedSong := Songs[selectedIndex]
        if (selectedSong) {
            GuiControl,, Sheet, % selectedSong.sheet
        }
}

; --- Load songs JSON ---
LoadSongsFromURL(url) {
    global Songs
    try {
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, false)
        http.Send()

        if (http.Status == 429) {
            MsgBox, 16, Rate Limit Exceeded, % "Rate limit exceeded. Please try again in a minute."
            return
        }
        if (http.Status != 200) {
            MsgBox, 16, HTTP Error, % "HTTP Error: " http.Status
            return
        }

        response := http.ResponseText

        Songs := JSON_Parse(response)
        if !IsObject(Songs) {
            MsgBox, 16, JSON Error, Failed to parse songs JSON.
            return
        }

        GuiControl,, SheetList, |

        listItems := ""
        for index, song in Songs {
            if IsObject(song) && song.HasKey("name") {
                listItems .= (listItems = "" ? "" : "|") . song.name
            }
        }
        GuiControl,, SheetList, %listItems%
        SB_SetText("Loaded " . Songs.MaxIndex()-1 . " songs from online.")
        SetTimer, ClearStatusBar, -3000
    } 
    catch e {
        MsgBox, 16, Connection Error, % "Failed to connect to server.`nOnline Sheets won't be loaded.`nMake sure you are connected to the internet."
    }
}
return

; --- Reload Online Sheets ---
ReloadOnlineSheets:
    SB_SetText("Reloading online sheets...")
    LoadSongsFromURL(url)
    return

; --- Check for Updates ---
CheckForUpdates(isManual := true) {
    global LatestScriptURL, Version
    if (isManual)
        SB_SetText("Checking for updates...")
    try {
        http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", LatestScriptURL, false)
        http.Send()
        if (http.Status == 429) {
            if (isManual) {
                MsgBox, 16, Update Check, % "Update check rate limited. Try again later."
            } else {
                SB_SetText("Update check rate limited. Try again later.")
                SetTimer, ClearStatusBar, -3000
            }
            return
        }
        if (http.Status != 200) {
            if (isManual) {
                MsgBox, 16, Update Check, % "Failed to check for updates.`nHTTP Error: " http.Status
            } else {
                SB_SetText("Update check failed: HTTP " . http.Status)
                SetTimer, ClearStatusBar, -3000
            }
            return
        }
        response := http.ResponseText
        pattern := "Version\s*:=\s*""([^""]+)"""
        
        if RegExMatch(response, pattern, m) {
            latestVersion := m1
            if (latestVersion != Version) {
                MsgBox, 68, Update Available, % "A new version (v " latestVersion ") is available!`nDo you want to update to the newest version?"
                IfMsgBox, Yes
                {
                    tempFile := A_Temp . "\auto-player-update.ahk"
                    FileAppend, %response%, %tempFile%
                    currentFile := A_ScriptFullPath
                    FileCopy, %tempFile%, %currentFile%, 1
                    FileDelete, %tempFile%
                    MsgBox, 64, Update Check, % "The script has been updated to the latest version.`nIt will close in 3 seconds.", 3
                    Run, %currentFile%
                    ExitApp
                }
            } else {
                SB_SetText("You are using the latest version.")
                SetTimer, ClearStatusBar, -3000
            }
        } else {
            SB_SetText("Could not determine latest version.")
            SetTimer, ClearStatusBar, -3000
        }
    }
    catch e {
        if (isManual) {
            MsgBox, 16, Update Check, % "Failed to connect to the server."
        } else {
            SB_SetText("Update check failed: connection error.")
            SetTimer, ClearStatusBar, -3000
        }
    }
    return
}

CheckForUpdatesMenu:
    CheckForUpdates(true)
return

; --- Toggle Loop ---
ToggleLoop:
Gui, Submit, NoHide
if (UseLoop) {
    GuiControl, Enable, LoopOptionInfinity
    GuiControl,, LoopOptionInfinity, 1
    GuiControl, Enable, LoopOptionLimit
    GuiControl, % LoopOptionLimit ? "Enable" : "Disable", LoopCount
} else {
    GuiControl, Disable, LoopOptionInfinity
    GuiControl,, LoopOptionInfinity, 0
    GuiControl, Disable, LoopOptionLimit
    GuiControl,, LoopOptionLimit, 0
    GuiControl, Disable, LoopCount
    GuiControl,, LoopCount, 1+
}
return

; --- Toggle Edits ---
LoopOptionChanged:
Gui, Submit, NoHide
if (LoopOptionLimit && UseLoop) {
    GuiControl, Enable, LoopCount
    GuiControl,, LoopCount, 1+
} else {
    GuiControl, Disable, LoopCount
    GuiControl,, LoopCount, 1+
}
return

TogglePauseDelay:
Gui, Submit, NoHide
if (UsePauseDelay) {
    GuiControl, Enable, PauseDelay
    GuiControl,, PauseDelay, Set value here (0-500 | Default: 100)
} else {
    GuiControl, Disable, PauseDelay
    GuiControl,, PauseDelay, Set value here (0-500 | Default: 100)
}
return

ToggleKeyDelay:
Gui, Submit, NoHide
if (UseKeyDelay) {
    GuiControl, Enable, KeyDelay
    GuiControl,, KeyDelay, Set value here (0-500 | Default: 200)
} else {
    GuiControl, Disable, KeyDelay
    GuiControl,, KeyDelay, Set value here (0-500 | Default: 200)
}
return

; --- Play (F4) ---
F4::
if (isPlaying)
    return
isPlaying := true
Paused := false
Gui, Submit, NoHide

KeyDelayFound := false
SkipLines := true
NewSheet := ""

if !RegExMatch(Sheet, "i)^.*delay[^\d]{0,10}(\d+).*", delayMatch)
{
    SkipLines := false
}

Loop, Parse, Sheet, `n, `r
{
    line := A_LoopField
    if (SkipLines) {
        if (RegExMatch(line, "i)delay[^\d]{0,10}(\d+)", delayMatch)) {
            KeyDelayText := "Auto set: " . delayMatch1
            GuiControl,, KeyDelay, %KeyDelayText%
            KeyDelay := delayMatch1
            KeyDelayFound := true
            SkipLines := false
            continue
        }
        continue
    }
    NewSheet .= line "`n"
}

if (UsePauseDelay) {
    if (!RegExMatch(PauseDelay, "^\d+$")) {
        MsgBox, 4,, Invalid value in Pause Delay.`nMust be a whole number.`nUse default value 100?`nChoosing "No" will stop the auto-player.
        IfMsgBox, Yes
            PauseDelay := 100
        else {
            isPlaying := false
            return
        }
    } else if (PauseDelay < 0 || PauseDelay > 500) {
        MsgBox, 4,, Pause Delay value out of range (0-500).`nUse default value 100?`nChoosing "No" will stop the auto-player.
        IfMsgBox, Yes
            PauseDelay := 100
        else {
            isPlaying := false
            return
        }
    }
} else {
    PauseDelay := 100
}

if RegExMatch(KeyDelay, "i)Auto set:\s*(\d+)", autoMatch) {
    extractedKeyDelay := autoMatch1 + 0
} else if RegExMatch(KeyDelay, "^\d+$") {
    extractedKeyDelay := KeyDelay + 0
} else {
    if (UseKeyDelay = false) {
        extractedKeyDelay := 200
    } else {
        MsgBox, 4,, Invalid value in Key Delay.`nValue must be in between of 0 to 500.`nUse default value 200?`nChoosing "No" will stop the auto-player.
        IfMsgBox, Yes
            extractedKeyDelay := 200
        else {
            isPlaying := false
            return
        }
    }
}

if (extractedKeyDelay < 0 || extractedKeyDelay > 500) {
    MsgBox, 4,, Key Delay value out of range (0-500).`nUse default value 200?`nChoosing "No" will stop the auto-player.
    IfMsgBox, Yes
        extractedKeyDelay := 200
    else {
        isPlaying := false
        return
    }
}

KeyDelayValue := extractedKeyDelay
PauseDelayValue := PauseDelay

NewSheet := RTrim(NewSheet, "`n")
Sheet := NewSheet
GuiControl,, Sheet, %Sheet%

if (!UseLoop) {
    LoopLimit := 1
} else if (LoopOptionLimit) {
    if (!RegExMatch(LoopCount, "^\d+$") || LoopCount < 1) {
        MsgBox, 4,, Invalid Loop Count value.`nMust be a whole number >=1.`nUse infinite loops instead?`nChoosing "No" will stop the auto-player.
        IfMsgBox, Yes
            LoopLimit := 0
        else {
            isPlaying := false
            return
        }
    } else {
        LoopLimit := LoopCount + 0
    }
} else {
    LoopLimit := 0
}

CurrentLoop := 0
StopPlay := false
ToolTip

SetTimer, UpdateTooltip, 30

while (!StopPlay) {
    CurrentLoop++
    if (EnableToolboxOption) {
        SB_SetText("Playing - Loop " . CurrentLoop . "/" . (LoopLimit = 0 ? "inf" : LoopLimit))
    }

    X := 1
    while (X := RegExMatch(Sheet, "U)(\[[^\[\]]+\]|.)", Match, X))
    {
        if (StopPlay) {
            break
        }

        WaitWhilePaused()

        X += StrLen(Match)
        Note := Trim(Match)

        if (RegExMatch(Note, "^\[.*\]$")) {
            NotesOnly := SubStr(Note, 2, -1)
            Loop, Parse, NotesOnly 
	          {
                WaitWhilePaused()
		            if (StopPlay)
		              break
                SendInput, %A_LoopField%
            }
            Sleep, %KeyDelayValue%
            }
            else if (Note ~= "^[|/\\\n\r]$") {
                Sleep, %PauseDelayValue%
            }
	          else if (Note ~= "-") {
	              Sleep, %KeyDelayValue%
	          }
            else if !(Note ~= "[\[\]|/\\\n\r]") {
                WaitWhilePaused()
	              if (StopPlay)
		                break
            SendInput, %Note%
            Sleep, %KeyDelayValue%
            }
    }

    if (StopPlay || (LoopLimit != 0 && CurrentLoop >= LoopLimit))
        break
}

SetTimer, UpdateTooltip, Off
ToolTip
SB_SetText("Finished.")
SetTimer, ClearStatusBar, -3000 
isPlaying := false
return

WaitWhilePaused() {
    global Paused, CurrentLoop, LoopLimit, StopPlay, EnableToolboxOption
    static prev_mx := "", prev_my := ""

    while (Paused && !StopPlay) {
        MouseGetPos, mx, my
        if (mx != prev_mx || my != prev_my) {
            TooltipText := "Auto-player running`nLoop " . CurrentLoop . "/" . (LoopLimit = 0 ? "inf" : LoopLimit) . " (Paused)"
            if(EnableToolboxOption) {
                ToolTip, %TooltipText%
            }
            prev_mx := mx
            prev_my := my
            Sleep, 20
        }
    }
    if (Paused && !StopPlay) {
        SB_SetText("Paused - Loop " . CurrentLoop . "/" . (LoopLimit = 0 ? "inf" : LoopLimit))
    }
}

UpdateTooltip() {
    global Paused, CurrentLoop, LoopLimit, EnableToolboxOption
    static prev_mx := "", prev_my := ""
    if (Paused)
        return

    MouseGetPos, mx, my
    if (mx != prev_mx || my != prev_mx) {
        TooltipText := "Auto-player running`nLoop " . CurrentLoop . "/" . (LoopLimit = 0 ? "inf" : LoopLimit)
        if (EnableToolboxOption) {
            ToolTip, %TooltipText%
        }
        prev_mx := mx
        prev_my := my
    }
    SB_SetText("Playing - Loop " . CurrentLoop . "/" . (LoopLimit = 0 ? "inf" : LoopLimit))
}

RemoveDebugTip:
ToolTip
return

; --- Stop (F7) ---
F7::
Critical
StopPlay := true
Paused := false
SetTimer, UpdateTooltip, Off
SB_SetText("Stopped.")
ToolTip
SetTimer, ClearStatusBar, -3000
return

; --- Suspend/Resume (F8) ---
F8::
Paused := !Paused
return

GuiClose:
ExitApp

AboutPage:
    Gui, About:Destroy
    Gui, About:+AlwaysOnTop +ToolWindow -SysMenu
    Gui, About:Add, Text, x20 y15 w260 Center, Auto-player for Roblox
    Gui, About:Add, Text, x20 y40 w260 Center, Version: %Version%
    Gui, About:Add, Text, x20 y65 w260 Center, Auto-player by @ml3czus_
    Gui, About:Add, Text, x20 y90 w260 Center, Sheets by @phrogfibsh (DB Guitar)
    Gui, About:Add, Text, x20 y105 w260 Center, and Others/Websites (Piano)
    Gui, About:Add, Text, x20 y135 w260 Center, Special thanks to:
    Gui, About:Add, Text, x20 y150 w260 Center, zeku (first tester and my pookie <3)
    Gui, About:Add, Text, x20 y165 w260 Center, phrog (for sharing the autoplayer on trello <3)
    Gui, About:Add, Text, x20 y180 w260 Center, and you (%A_UserName%) for using it!
    Gui, About:Add, Text, x20 y215 w260 Center cBlue gAboutDiscord, [Give Feedback on Discord]
    Gui, About:Add, Button, x100 y235 w100 gAboutClose, Close
    Gui, About:Show, w300 h275, About Auto-player
return

OpenTrelloBoard:
    Run, https://trello.com/b/ue1LfwEa/
return

AboutDiscord:
    Run, https://discord.com/users/1345183564655890544
return

AboutClose:
    Gui, About:Destroy
return
