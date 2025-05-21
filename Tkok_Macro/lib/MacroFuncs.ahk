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

PackMacro(content) {
    cleanedLines := []
    lastLine := ""
    count := 0

    Loop, Parse, content, `n, `r
    {
        line := A_LoopField  ; 빈 줄도 그대로 사용 (Trim 제거)
        
        if (line = "") {
            ; 빈 줄은 바로 푸시 (연속 빈 줄도 그대로 유지)
            if (count > 0) {
                cleanedLines.Push(FormatLine(lastLine, count))
                count := 0
                lastLine := ""
            }
            cleanedLines.Push("")
            continue
        }

        line := Trim(line)  ; 빈 줄이 아닐때만 트림

        if (line = lastLine) {
            count++
        } else {
            if (lastLine != "") {
                cleanedLines.Push(FormatLine(lastLine, count))
            }
            lastLine := line
            count := 1
        }
    }

    ; 마지막 줄 처리
    if (count > 0) {
        cleanedLines.Push(FormatLine(lastLine, count))
    }

    return StrJoin(cleanedLines, "`n")
}

FormatLine(line, count) {
    if (count > 1) {
        ; 공백 포함 #rep:숫자 패턴 모두 제거
        line := RegExReplace(line, "\s*#rep:\d+#")
        line .= " #rep:" . count . "#"
    }
    return line
}
