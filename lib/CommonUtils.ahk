
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

FormatValue(val) {
    if IsObject(val) {
        out := "[Object] {"
        for k, v in val {
            if(!InStr(k, "path"))
                out .= k ": " v ", "
        }
        return Trim(out, ", ") . "}"
    } else {
        return "[Value] " val
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

ShowTip(msg, duration := 1500, writeLog := false) {
    if (writeLog) {
        FileAppend, % msg, % logFilePath
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

Alert(msg) {
    MsgBox, %msg%
}

Confirm(msg, title:="확인") {
    MsgBox, 4, %title%, %msg%
    IfMsgBox, No
        return false
    
    return true
}

Note(newText := "", title := "", isAppend := false) {
    static isCreated := false
    global NoteEdit

    ; GUI 없으면 생성
    if (!isCreated) {
        Gui, SimpleNote: New
        Gui, SimpleNote: +Resize +HwndhNote  ; << 핸들 저장
        Gui, SimpleNote: Margin, 10, 10
        Gui, SimpleNote: Font, 16s, Consolas
        Gui, SimpleNote: Add, Edit, vNoteEdit w600 h500 WantTab
        isCreated := true
    }

    if (isAppend) {
        GuiControlGet, existingText, SimpleNote:, NoteEdit
        newText := existingText . (existingText != "" ? "`n" : "") . newText
    }
    GuiControl, SimpleNote:, NoteEdit, %newText%

    ; 창이 떠있지 않다면 띄우기
    WinGet, existingID, ID, ahk_gui SimpleNote
    if (!existingID) {
        Gui, SimpleNote: Show,, % title ? title : "AHK Note"
    }
    return

    SimpleNoteGuiClose:
        Gui, SimpleNote:Destroy
        isCreated := false
        hNote := ""
    return
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
