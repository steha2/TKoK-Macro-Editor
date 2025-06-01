LogKeyControl(key) {
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  LogToEdit("Send, {" . k . " Down}")
  Critical, Off
  KeyWait, %key%
  Critical
  LogToEdit("Send, {" . k . " Up}")
}

LogMouseClick(key) {
    MouseGetPos,,, hwnd
    if (!isRecording || IsTargetWindow("Macro Editor", hwnd) || !GetAdjustedCoords(xStr, yStr))
        return
    btn := SubStr(key, 1, 1)
    LogToEdit("Click:" . btn . ", " . xStr . ", " . yStr)
}

LogKey() {
    static lastKey := "", lastTime := 0
    Critical

    vksc := SubStr(A_ThisHotkey, 3)
    k := GetKeyName(vksc)
    k := StrReplace(k, "Control", "Ctrl")
    r := SubStr(k, 2)

    ; ShowTip("InputKey: "k,300)

    ; 반복 입력 제어
    if r in Alt,Ctrl,Shift,Win
        LogKeyControl(k)
    else if k in LButton,RButton,MButton
        LogMouseClick(k)
    else {
        if (k = "NumpadLeft" or k = "NumpadRight") and !GetKeyState(k, "P")
            return
        k := StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}"

        now := A_TickCount
        if (k = lastKey && (now - lastTime) < 100)
            return
       
        lastKey := k
        lastTime := now
        LogToEdit("Send, " . k)
    }
}

; 🔁 핫키 등록/해제
SetHotkey(enable := false) {
    excludedKeys := "MButton,WheelDown,WheelUp,WheelLeft,WheelRight,Pause"
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

LogToEdit(line) {
    GuiControlGet, current, macro:, EditMacro
    if (current != "" && SubStr(current, -1) != "`n")
        current .= "`n"  ; 마지막 줄에 줄바꿈 추가

    GuiControl, macro:, EditMacro, % current . line
    GuiControl, macro:, LatestRec, % line
}

MergeMacro(content) {
    mergedLines := []
    lastLine := ""
    count := 0

    Loop, Parse, content, `n, `r 
    {
        line := Trim(A_LoopField)
        if (line = "") {
            if (count > 0)
                mergedLines.Push(MergeLine(lastLine, count))
            mergedLines.Push("")
            count := 0
            lastLine := ""
            continue
        }

        if (IsSameMacroLine(line, lastLine)) {
            count++
        } else {
            if (lastLine != "")
                mergedLines.Push(MergeLine(lastLine, count))
            lastLine := line
            count := 1
        }
    }

    if (count > 0)
        mergedLines.Push(MergeLine(lastLine, count))

    return StrJoin(mergedLines, "`n")
}

MergeLine(line, count) {
    if (count > 1) {
        line := RegExReplace(line, "\s*#rep:\d+#")
        line .= " #rep:" . count . "#"
    }
    return line
}

IsSameMacroLine(line1, line2) {
    if (InStr(line1, "#") || InStr(line1, ";") || InStr(line1, "%"))
        return false

    pattern := "i)^Click:(\w),\s*([\d.]+),\s*([\d.]+)"
    if (RegExMatch(line1, pattern , am) && RegExMatch(line2, pattern , bm)) {
        ; 문자열 기반 소수점 포함 여부로 정수/실수 판별
        isFloat1 := InStr(am2, ".") || InStr(am3, ".")
        isFloat2 := InStr(bm2, ".") || InStr(bm3, ".")

        x1 := am2 + 0, y1 := am3 + 0
        x2 := bm2 + 0, y2 := bm3 + 0
        dist := Sqrt((x1 - x2)**2 + (y1 - y2)**2)

        if (am1 != bm1)
            return false
        else if (!isFloat1 && !isFloat2) ; 둘 다 정수
            return dist <= EPSILON_FIXED
        else if (isFloat1 && isFloat2)   ; 둘 다 실수
            return dist <= EPSILON_RATIO
        else
            return false ; 정수/실수 혼합 → 다르다고 판단
    } else {
        return (line1 = line2)
    }
}

IsMacroModified() {
    GuiControlGet, currentText, macro:, EditMacro
    return (currentText != origContent)
}


WriteMacroFile(content := "", macroFilePath := "") {
    if (macroFilePath  = "") {
        FormatTime, now,, MMdd_HHmmss
        macroFilePath := "Macro_" . now
    }
    AppendExt(macroFilePath)
    ; 절대경로인지 검사 (드라이브 문자 or \로 시작)
    if (SubStr(macroFilePath, 1, 1) = "\" || RegExMatch(macroFilePath, "^[a-zA-Z]:\\")) {
        fullPath := macroFilePath
    } else {
        fullPath := MACRO_DIR . "\" . macroFilePath
    }

    ; 이미 파일 존재하면 메시지 후 리턴
    if FileExist(fullPath) {
        MsgBox, 이미 존재하는 파일이 있습니다.`n%fullPath%
        return
    }
    ; ✅ 디렉토리 자동 생성
    SplitPath, fullPath, , outDir
    if !FileExist(outDir) {
        FileCreateDir, %outDir%
    }

    ; 파일 쓰기
    FileAppend, %content%, %fullPath%
    ShowTip("매크로 파일 생성 완료`n" fullPath)
    ReloadTreeView(fullPath)
}

GetAdjustedCoords(ByRef x, ByRef y) {
    GuiControlGet, isClient, macro:, ClientBtn
    GuiControlGet, isRatio, macro:, RatioBtn
    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if (isRatio) {
        if(!GetMouseRatio(x, y, "A"))
            return false
    } else {
        MouseGetPos, x, y
    }
    return true
}

CoordTracking() {
    if CoordTrackingRunning || GetKeyState("Shift", "P")
        return
    CoordTrackingRunning := true
    if (GetAdjustedCoords(x, y)) {
        coordStr := x . ", " . y
        GuiControlGet, isClient, macro:, ClientBtn
        WinGetTitle, activeTitle, A
        if (isClient && activeTitle) {
            coordStr .= " / " . activeTitle
        }
        GuiControl, macro:, CoordTrack, %coordStr%
    }
    CoordTrackingRunning := false
}

PreprocessMacroLines(lines, vars) {
    processedLines := []
    for index, line in lines {
        line := ResolveExpr(line, vars)
        cmd := StripComments(cmd)
        cmd := ParseLine(line, vars)
        if (vars.HasKey("force")) {
            vars.Delete("force")
            ExecSingleCommand(cmd, vars)
        } else {
            processedLines.Push(line)
        }
    }
    return processedLines
}

LoadPresetForMacro(fileName, vars) {
    presetDir := MACRO_DIR . "\preset"
    Loop, Files, %presetDir%\*.txt
    {
        SplitPath, A_LoopFileName,,,, noExt
        if InStr(fileName, noExt) {
            FileRead, presetContent, %A_LoopFileFullPath%

            ; fileName를 - 또는 _ 기준으로 분리하여 vars에 넣기
            i := 1
            Loop, Parse, fileName, -_ 
            {
                key := "part" . i
                vars[key] := A_LoopField
                i++
            }
            
            lines := StrSplit(presetContent, ["`r`n", "`n", "`r"])
            newContents := PreprocessMacroLines(lines, vars)
            return RTrim(StrJoin(newContents),"`t`n ")
        }
    }
}

ToggleOverlay() {
    if (overlayVisible) {
        Gui, overlay:Destroy
        overlayVisible := false
        return
    }

    ; Overlay GUI 준비
    Gui, overlay:+AlwaysOnTop -Caption +ToolWindow +HwndhOverlay
    Gui, overlay:Font, Bold

    vars := {}
    GuiControlGet, currentText, macro:, EditMacro
    lines := StrSplit(currentText, ["`r`n", "`n", "`r"])
    lines := PreprocessMacroLines(lines, vars)

    if(vars.target) 
        hwnd := ActivateWindow(vars.target)
    else 
        WinGet, hwnd, ID, A

    if(!hwnd)
        return
        
    GetClientPos(hwnd, x, y)
    GetClientSize(hwnd, w, h)
    dpi := GetWindowDPI(hwnd)
    
    w := w/dpi*100
    h := h/dpi*100

    Loop, % lines.Length()
    {
        if RegExMatch(lines[A_Index], "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)$", m) {
            mx := m2/dpi*100, my := m3/dpi*100
            CalcCoords(mx, my, vars.coordMode)
            boxX := mx - 14
            boxY := my - 14
            Gui, overlay:Add, Button, x%boxX% y%boxY% w29 h29 cRed BackgroundTrans Border gOnOverlayBtn, %A_Index%
        }
    }

    Gui, overlay:Color, 0x222244
    Gui, overlay:Show, x%x% y%y% w%w% h%h% NoActivate
    WinSet, Transparent, 150, ahk_id %hOverlay% 
    overlayVisible := true
}

OnOverlayBtn:
GuiControlGet, btnText, overlay:, %A_GuiControl%
Gui, overlay:Destroy
overlayVisible := false
GuiControl, macro:Focus, EditMacro
lineNum := btnText -1
SendKey("^{Home}")
Loop, %lineNum% {
    SendKey("{Down}")
}
SendKey("+{End}")
return