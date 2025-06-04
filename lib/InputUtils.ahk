Chat(text, send_mode := "", win := "") {
    if (send_mode = "inactive" && win) {
        SendKey("{Enter}", -20, send_mode, win)
        SendKey(text, -20, send_mode, win)
        SendKey("{Enter}", 30, send_mode, win)
    } else {
        ClipSaved := ClipboardAll
        Clipboard := text
        ClipWait, 0.5
        SendKey("{Enter}", -20)
        SendKey("^v", -50)
        SendKey("{Enter}", 30)
        Clipboard := ClipSaved
    }
}

Chat2(text) {
    SendKey("{Enter}", 100)
    Suspend, On
    SendRaw, %text%
    Suspend, Off
    SendKey("{Enter}")
}

;dealy :음/양수 선/후 딜레이
SendKey(key, delay := 0, send_mode := "", win := "", ignoreSpace := false) {
    StringLower, key, key

    if (delay < 0)
        Sleep, -delay

    if (ignoreSpace)
        key := StrReplace(key, " ")

    if (send_mode = "inactive" && win){
        ControlSend,, %key%, %win%
    }
    else 
        Send, {Blind}%key%

    if (delay > 0)
        Sleep, delay
}

CalcCoords(ByRef x, ByRef y, coord_mode := "", coord_type := "") {
    isClient := !InStr(coord_mode,"screen")
    isRatio := !InStr(coord_type,"fixed")

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if(isRatio){
        GetClientSize("A", w, h)
        x := Round(x * w)
        y := Round(y * h)
    }
}

Click(x, y, btn := "L", coord_Mode := "", coord_type := "", send_mode := "", win := "") {
    CalcCoords(x, y, coord_mode, coord_type)
    if(send_mode = "inactive" && win) {
        AdjustClientToWindow(x,y,win)
        Sleep, 100
        SetControlDelay -1
        ControlClick, x%x% y%y%, %win%,, %btn%, , NA
    } else {
        MouseMove, %x%, %y%
        Sleep, 50
        if (btn = "R") {
            ; 우클릭: 0x08 (Down), 0x10 (Up)
            DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
            Sleep, 50
            DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
        } else {
            ; 좌클릭: 0x02 (Down), 0x04 (Up)
            DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
            Sleep, 50
            DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
        }
    }
}
