
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

ShowTip(msg, duration := 1500) {
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

Note(newText := "", isAppend := false) {
    static isCreated := false
    static NoteEdit
    ; GUI 없으면 생성
    if (!isCreated) {
        Gui, SimpleNote: New
        Gui, SimpleNote: +Resize
        Gui, SimpleNote: Margin, 10, 10
        Gui, SimpleNote: Add, Edit, vNoteEdit w700 h500 WantTab
        isCreated := true
    }

    if (isAppend) {
        GuiControlGet, existingText, SimpleNote:, NoteEdit
        newText := existingText . (existingText != "" ? "`n" : "") . newText
    }
    GuiControl, SimpleNote:, NoteEdit, %newText%

    ; 창이 이미 떠 있지 않다면 띄우기
    WinGet, existingID, ID, ahk_gui SimpleNote
    if (!existingID) {
        Gui, SimpleNote: Show,, AHK Note
    }

    return

    ; 닫기 버튼 핸들러
    SimpleNoteGuiClose:
        Gui, SimpleNote:Destroy
        isCreated := false
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
        if (hwnd) 
            return hwnd
        else 
            Sleep, %interval%
    }
    return false
}
