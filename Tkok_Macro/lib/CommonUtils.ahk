global logFilePath :=  A_Temp "\macro_test_log.txt"
test(a := "", b := "", c := "", d := "", e := "", f := "", isTip := false, writeLog := true) {
    args := [a, b, c, d, e, f]
    output := ""
    for index, value in args {
        if (value != "")
            output .= "Arg" index " : " FormatValue(value) "`n`n"
    }
    if (writeLog) {
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

test2(a="", b="", c="", d="", e="", f="",isTip:=true,isLog:=true) {
    test(a,b,c,d,e,f,isTip,isLog)
}


Chat(text) {
    SendKey("{Enter}",100)
    Suspend, On
    SendRaw, %text%
    Suspend, Off
    SendKey("{Enter}")
}

;dealy :음/양수 선/후 딜레이
SendKey(key, delay := 0, ignoreSpace := false) {
    if (delay < 0)
        Sleep, -delay

    if (ignoreSpace)
        key := StrReplace(key, " ")

    Send, {Blind}%key%

    if (delay > 0)
        Sleep, delay
}

ShowTip(msg, duration := 1500) {
    Tooltip, %msg%
    SetTimer, RemoveToolTip, -%duration%
    return
}

RemoveToolTip() {
    ToolTip
}

Note(newText := "") {
    static guiName := "SingleNote"
    static isCreated := false

    ; GUI 없으면 생성
    if (!isCreated) {
        Gui, %guiName%:New
        Gui, %guiName%:Default
        Gui, +Resize +AlwaysOnTop
        Gui, Margin, 10, 10
        Gui, Add, Edit, vNoteEdit w400 h300 WantTab
        Gui, Add, Button, g%guiName%_CloseSection Default, 닫기
        isCreated := true
    }

    ; 기존 텍스트에 이어붙이기
    GuiControlGet, existingText, %guiName%:, NoteEdit
    updatedText := existingText . (existingText != "" ? "`n" : "") . newText
    GuiControl, %guiName%:, NoteEdit, %updatedText%

    ; 창이 이미 떠 있지 않다면 띄우기
    WinGet, existingID, ID, ahk_gui %guiName%
    if (!existingID) {
        Gui, %guiName%:Show,, AHK 메모장
    }

    return

    ; 닫기 버튼 핸들러
    %guiName%_CloseSection:
        Gui, %guiName%:Destroy
        isCreated := false
    return
}