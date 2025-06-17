
; 🔁 핫키 등록/해제
SetHotkey(enable := false) {
    excludedKeys := "LButton,RButton,MButton,WheelDown,WheelUp,WheelLeft,WheelRight,Pause,ScrollLock,PrintScreen"
    mode := enable ? "On" : "Off"

    Loop, 254 {
        vk := Format("vk{:X}", A_Index)
        key := GetKeyName(vk)
        if key not in ,%excludedKeys%
            Hotkey, ~*%vk%, LogKey, %mode% UseErrorLevel
    }

    ; 추가 키 (방향키 등 SC 기반)
    extraKeys := "NumpadEnter|Home|End|PgUp|PgDn|Left|Right|Up|Down|Delete"
    For i, key in StrSplit(extraKeys, "|") {
        sc := Format("sc{:03X}", GetKeySC(key))
        if key not in ,%excludedKeys%
            Hotkey, ~*%sc%, LogKey, %mode% UseErrorLevel
    }
}

LogKey() {
    Critical
    vksc := SubStr(A_ThisHotkey, 3)
    k := GetKeyName(vksc)
    k := StrReplace(k, "Control", "Ctrl")
    r := SubStr(k, 2)

    if r in Alt,Ctrl,Shift,Win
        LogKeyControl(k)
    else {
        if (k = "NumpadLeft" or k = "NumpadRight") and !GetKeyState(k, "P")
            return
        k := StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}"
        LogToEdit("Send: " . k, k)
    }
}

LogKeyControl(key) {
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  LogToEdit("Send: {" . k . " down}", k, true)
  Critical, Off
  KeyWait, %key%
  Critical
  LogToEdit("Send: {" . k . " up}" , k, true)
} 

LogMouseClick(key) {
    MouseGetPos,,, hwnd
    if (!isRecording || IsTargetWindow("Macro Editor", hwnd) || !GetAdjustedCoords())
        return
    
    btn := SubStr(key, 1, 1)
    LogToEdit("Click:" . btn . " " . xStr . ", " . yStr, key)
}

LogToEdit(line, k := "", isModifier := false) {
    static lastKey := ""

    currTime := A_TickCount
    elapsed := currTime - lastTime
    if (k = lastKey && elapsed < 100 && !isModifier) {
        return
    } else 
        lastKey := k

    GuiControlGet, isTimeGaps, macro:, TimeGapsCheck
    if (isTimeGaps && lastTime) {
        line .= " #wait=" . Format("{:4}", elapsed) . "#"
    }
    lastTime := currTime

    GuiControlGet, scriptText, macro:, EditMacro
    GuiControlGet, isAutoMerge, macro:, AutoMerge
    
    if(isAutoMerge && !isModifier){
        trimmedScript := RTrim(scriptText, "`n`t ")
        lastLine := GetLastPart(trimmedScript, "`n")
        if(IsSameMacroLine(line, lastLine)){
            scriptText := TrimLastToken(trimmedScript, "`n")
            line := MergeLine(lastLine, 2)
        }
    }
    if (scriptText != "" && SubStr(scriptText, 0) != "`n")
        scriptText .= "`n"  ; 줄바꿈 보정
    scriptText .= line
    GuiControl, macro:, EditMacro, %scriptText%
    GuiControl, macro:, LatestRec, %line%

    ControlSend, Edit2, ^{End}, ahk_id %hMacro%
}

#If isRecording
global down_info := false
~LButton::
    if (!LButtonDown) {
        LButtonDown := true
        MouseDown("L")
    }
return

~LButton Up::
    LButtonDown := false
    MouseUp("L")
return

~RButton::
    if (!RButtonDown) {
        RButtonDown := true
        MouseDown("R")
    }
return

~RButton Up::
    RButtonDown := false
    MouseUp("R")
return
#If

MouseDown(btn) {
    down_info := GetAdjustedCoords()
    down_info.btn := btn
    if (IsTargetWindow("Macro Editor", down_info.hwnd))
        down_info := false
}

MouseUp(btn) {
    up_info := GetAdjustedCoords()
    if (!up_info || IsTargetWindow("Macro Editor", up_info.hwnd)) {
        down_info := false
    } else if (down_info && down_info.btn = btn) {
        x1 := down_info.x
        y1 := down_info.y

        x2 := up_info.x
        y2 := up_info.y
        state := IsClosePoint(x1, y1, x2, y2) ? "Click" : "Drag"
        
        coords := x1 . ", " . y1
        if(state = "Drag")
            coords .= ", " . x2 ", " . y2

        LogToEdit(state . ":" . btn . " " . coords , btn)
    }
    down_info := false
}