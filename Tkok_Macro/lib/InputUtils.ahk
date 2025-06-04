Chat(text) {
    ClipSaved := ClipboardAll
    Clipboard := text
    ClipWait, 0.5
    SendKey("{Enter}", -20)
    SendKey("^v", -50)
    SendKey("{Enter}", 30)
    Clipboard := ClipSaved
}

Chat2(text) {
    SendKey("{Enter}", 100)
    Suspend, On
    SendRaw, %text%
    Suspend, Off
    SendKey("{Enter}")
} 

;dealy :음/양수 선/후 딜레이
SendKey(key, delay := 0, ignoreSpace := false) {
    StringLower, key, key

    if (delay < 0)
        Sleep, -delay

    if (ignoreSpace)
        key := StrReplace(key, " ")

    Send, {Blind}%key%

    if (delay > 0)
        Sleep, delay
}

CalcCoords(ByRef x, ByRef y, coordMode := "") {
    isClient := !InStr(coordMode,"screen")
    isRatio := !InStr(coordMode,"fixed") && isClient

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    
    if(isRatio){
        GetClientSize("A", w, h)
        x := Round(x * w)
        y := Round(y * h)
    }
}

Click(x, y, btn := "L", delay := 50, coordMode := "") {
    CalcCoords(x, y, coordMode)
    MouseMove, %x%, %y%
    Sleep, delay
    ; MouseClick, %btn%
    if (btn = "R") {
        ; 우클릭: 0x08 (Down), 0x10 (Up)
        DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
        Sleep, delay
        DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
    } else {
        ; 좌클릭: 0x02 (Down), 0x04 (Up)
        DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
        Sleep, delay
        DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
    }
}
