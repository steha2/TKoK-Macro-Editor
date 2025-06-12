
test(a := "", b := "", c := "", d := "", e := "", f := "", isTip := false, writeLog := true) {
    args := [a, b, c, d, e, f]
    output := ""
    for index, value in args {
        if (value != "")
            output .= "Arg" index " : " FormatValue(value) "`n`n"
    }
    if (writeLog) {
        FileDelete, %logFilePath%
        FileAppend, % output, % logFilePath
    }

    if (isTip)
        ShowTip(output)
    else
        MsgBox, % output
}
test4(hwnd) {
    ; 기본 정보 수집
    WinGetTitle, title, ahk_id %hwnd%
    WinGetClass, class, ahk_id %hwnd%
    WinGet, pid, PID, ahk_id %hwnd%
    WinGet, exe, ProcessName, ahk_id %hwnd%
    WinGetPos, x, y, w, h, ahk_id %hwnd%

    dpi := GetWindowDPI(hwnd)

    GetClientPos(hwnd, cx, cy)
    GetClientSize(hwnd, cw, ch)

    ; 문자열 조합 (변수 확장 사용)
    msg := "HWND         : " hwnd "`n"
    msg .= "Title        : " title "`n"
    msg .= "Class        : " class "`n"
    msg .= "EXE Name     : " exe "`n"
    msg .= "Window Pos   : x=" x ", y=" y ", w=" w ", h=" h "`n"
    msg .= "DPI Scale    : " dpi "`n`n"
    msg .= "Client Pos   : x=" cx ", y=" cy "`n"
    msg .= "Client Size  : w=" cw ", h=" ch

    MsgBox, 64, HWND 정보, %msg%
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

ShowTip(msg, duration := 1500, writeLog := true) {
    if (writeLog) {
        FileAppend, `n%msg%, % logFilePath
    }
    Tooltip, %msg%
    SetTimer, RemoveToolTip, -%duration%
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

Alert(msg, title := "알림", writeLog := true) {
     if (writeLog) {
        FileAppend, % msg, % logFilePath
    }
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
    Run, *RunAs %path%
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
            Sleep, %interval%
    }
    return false
}
