LogKeyControl(key) {
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  LogToEdit("Send, {" k " Down}")
  Critical, Off
  KeyWait, %key%
  Critical
  LogToEdit("Send, {" k " Up}")
}

LogMouseClick(key) {
    global isRecording, w3Win
    if (!isRecording || !WinActive(w3Win))
        return

    GetMouseRatio(ratioX,ratioY)
    btn := SubStr(key,1,1)
    LogToEdit("Click:" . btn . ", " . ratioX . ", " . ratioY)
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
        LogToEdit("Send, "k)
    }
}

; 🔁 핫키 등록/해제
SetHotkey(enable := false) {
    excludedKeys := "MButton,WheelDown,WheelUp,WheelLeft,WheelRight,Pause"
    mode := enable ? "On" : "Off"

    ShowTip("SetHotKey:" mode)

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
    GuiControlGet, l2, macro:, LastestMacro2
    GuiControl, macro:, LastestMacro1, % l2
    GuiControl, macro:, LastestMacro2, % line
}

MergeMacro(content) {
    cleanedLines := []
    lastLine := ""
    count := 0

    Loop, Parse, content, `n, `r 
    {
        line := Trim(A_LoopField)
        if (line = "") {
            if (count > 0)
                cleanedLines.Push(FormatLine(lastLine, count))
            cleanedLines.Push("")
            count := 0
            lastLine := ""
            continue
        }

        if (IsSameMacroLine(line, lastLine)) {
            count++
        } else {
            if (lastLine != "")
                cleanedLines.Push(FormatLine(lastLine, count))
            lastLine := line
            count := 1
        }
    }

    if (count > 0)
        cleanedLines.Push(FormatLine(lastLine, count))

    return StrJoin(cleanedLines, "`n")
}


FormatLine(line, count) {
    if (count > 1) {
        line := RegExReplace(line, "\s*#rep:\d+#")
        line .= " #rep:" . count . "#"
    }
    return line
}

IsSameMacroLine(line1, line2, epsilon := 0.004) {
    if (StrLen(line1) != StrLen(line2) || InStr(line1, "#") || InStr(line1, ";") || InStr(line1, "%"))
        return false
    pattern := "i)^Click:(\w),\s*([\d.]+),\s*([\d.]+)"
    if (RegExMatch(line1, pattern , am) && RegExMatch(line2, pattern , bm)) {
        x1 := am2 + 0, y1 := am3 + 0
        x2 := bm2 + 0, y2 := bm3 + 0
        ;test(x1,y1,x2,y2)
        return am1 = bm1 && (Abs(x1 - x2) <= epsilon && Abs(y1 - y2) <= epsilon)
    } else {
        return (line1 = line2)
    }
}


IsMacroModified() {
    GuiControlGet, currentText,, EditMacro
    return (currentText != origContent)
}


WriteMacroFile(content := "", macroFilePath := "") {
    if (macroFilePath  = "") {
        FormatTime, now,, MMdd_HHmmss
        macroFilePath := "Macro_" . now . ".txt"
    }

    ; .txt 확장자 붙이기 (없으면)
    if (!RegExMatch(macroFilePath, "i)\.txt$"))
        macroFilePath .= ".txt"

    ; 절대경로인지 검사 (드라이브 문자 or \로 시작)
    if (SubStr(macroFilePath, 1, 1) = "\" || RegExMatch(macroFilePath, "^[a-zA-Z]:\\")) {
        fullPath := macroFilePath
    } else {
        fullPath := macroDir . "\" . macroFilePath
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

    ; 트리뷰 갱신 (함수에 맞게 인자 조정 필요할 수 있음)
    ReloadTreeView(fullPath)
}

DisableShortTime(ctrlName, delay := 500, guiName := "macro") {
    GuiControl, %guiName%:Disable, %ctrlName%
    fn := Func("EnableGuiControl").Bind(ctrlName, guiName)
    SetTimer, % fn, -%delay%
}

EnableGuiControl(ctrlName, guiName := "macro") {
    GuiControl, %guiName%:Enable, %ctrlName%
}

ToggleMacroImpl() {
    GuiControlGet, content, macro:, EditMacro
    GuiControlGet, macroName, macro:, MacroList
    ;MsgBox, runMacron%content%
    ExecMacro(content, macroName)
}