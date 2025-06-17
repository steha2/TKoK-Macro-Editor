
test(a := "", b := "", c := "", d := "", e := "", f := "", isTip := false, writeLog := true) {
    args := [a, b, c, d, e, f]
    output := ""
    for index, value in args {
        if (value != "")
            output .= "Arg" index " : " FormatValue(value) "`n`n"
    }
    if (writeLog)
        Log(a "  " b "  " c "  " d "  " e "  " f, 3)

    if (isTip)
        ShowTip(output, 1500, true)
    else
        MsgBox, % output
}

hwndInfo(hwnd) {
    ; 기본 정보 수집
    WinGetTitle, title, ahk_id %hwnd%
    WinGetClass, class, ahk_id %hwnd%
    WinGet, pid, PID, ahk_id %hwnd%
    WinGet, exe, ProcessName, ahk_id %hwnd%
    WinGetPos, x, y, w, h, ahk_id %hwnd%

    dpi := GetWindowDPI(hwnd)
    GetClientRect(w3hwnd, cx, cy, cw, ch)

    ; 문자열 조합 (변수 확장 사용)
    msg := "HWND         : " hwnd "`n"
    msg .= "Title        : " title "`n"
    msg .= "Class        : " class "`n"
    msg .= "EXE Name     : " exe "`n"
    msg .= "Window Pos   : x=" x ", y=" y ", w=" w ", h=" h "`n"
    msg .= "DPI Scale    : " dpi "`n`n"
    msg .= "Client Pos   : x=" cx ", y=" cy "`n"
    msg .= "Client Size  : w=" cw ", h=" ch

    return msg
}


FormatValue(val) {
    if IsObject(val) {
        out := "[Object]`n"
        for k, v in val {
            if(!InStr(k, "path"))
                out .= k ": " v "`n"
        }
        return out . "`n"
    } else {
        return "[Value] " val . "`n"
    }
}

OpenLogFile() {
    if FileExist(logFilePath)
        Run, notepad.exe "%logFilePath%"
    else
        MsgBox, 로그 파일이 없습니다.
}

test2(a:="", b:="", c:="", d:="", e:="", f:="",isTip:=true,isLog:=true) {
    test(a,b,c,d,e,f,isTip,isLog)
}

testj(data) {
    if(IsObject(data)) {
        json := JSON.Dump(data,, 2)
        MsgBox, -------------JSON------------`n%json%
    } else {
        MsgBox, 오브젝트가 아님`n%data%
    }
}

Log(msg, level := 3) {
    if (DEBUG_LEVEL >= level) {
        FormatTime, timeStr,, HH:mm:ss
        FileAppend, `n[%timeStr%][L%level%] %msg%, %logFilePath%
    }
}

ShowTip(msg, duration := 1500, writeLog := false) {
    if (writeLog)
        Log("ShowTip(): " msg, 2)  ; INFO 수준
    
    if(!muteAll)
        Tooltip, %msg%

    SetTimer, RemoveToolTip, -%duration%
}

TrueTip(msg := "", duration := 1500, level := 2, writeLog := true) {
    ShowTip(msg, duration)
    if (writeLog)
        Log("TrueTip(): " msg, level)  ; INFO
    return msg ? msg : true
}

FalseTip(msg := "", duration := 1500,  level := 0, writeLog := true) {
    ShowTip(msg, duration)
    if (writeLog)
        Log("FalseTip(): " msg, level)  ; ERROR
    return false
}


TipResult(isSuccess, msg := "", duration := 1500, writeLog := true) {
    return isSuccess ? TrueTip(msg, duration, writeLog) : FalseTip(msg, duration, writeLog)
}

RemoveToolTip() {
    ToolTip
}

Clone(obj) {
    new := {}
    for k, v in obj
        new[k] := v
    return new
}

Alert(msg, title := "알림", level := 2) {
     if (level >= 0) {
        Log(msg, level)
    }

    if(muteAll)
        return

    MsgBox, 4096, %title%, %msg%
}

Confirm(msg, title:="확인") {
    MsgBox, 4100, %title%, %msg%
    IfMsgBox, No
        return false
    
    return true
}

ModiKeyWait() {
    if (GetKeyState("Alt", "P"))
        KeyWait, Alt
    if (GetKeyState("Ctrl", "P"))
        KeyWait, Ctrl
    if (GetKeyState("Shift", "P"))
        KeyWait, Shift
    if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
        KeyWait, LWin
}

RunGetHwnd(path, winTitle := "") {
    Run_("runas", path)
    hwndR := WaitGetHwnd(winTitle)
    if (!hwndR)
        return false
    return hwndR
}

WaitGetHwnd(winTitle, interval := 100, maxLoop := 50) {
    Loop, %maxLoop% {
        hwnd := WinExist(winTitle)
        WinGetClass, w3Class, ahk_id %hwnd%
        if (hwnd && w3Class = W3_WINTITLE) 
            return hwnd
        else 
            Sleep(interval)
    }
    return false
}

Sleep(delay) {
    if(muteAll)
        return

    Sleep, %Delay%
}