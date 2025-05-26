global logFilePath :=  A_Temp "\macro_test_log.txt"
test(a := "", b := "", c := "", d := "", e := "", f := "", isTip := false, writeLog := true) {
    args := [a, b, c, d, e, f]
    output := ""
    for index, value in args {
        if (value != "")  ; ← 수정: a가 아니라 value 기준 체크해야 함
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

; --------------------------- 파일 함수 -----------------------------------
