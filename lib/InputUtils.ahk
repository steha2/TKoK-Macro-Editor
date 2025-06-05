Chat(text, send_mode := "", hwnd := "") {
    if (send_mode = "inactive" && hwnd) {
        SendKeyI("{Enter}", hwnd, -20)
        SendKeyI(text, hwnd, -20)
        SendKeyI("{Enter}", hwnd, 30)
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
SmartSendKey(key,  hwnd := "", delay := 0, send_mode := "", ignoreSpace := false) {
    StringLower, key, key

    if (delay < 0)
        Sleep, -delay

    if (ignoreSpace)
        key := StrReplace(key, " ")

    if (send_mode = "inactive" && hwnd) {
        ControlSend,, %key%, ahk_id %hwnd%
    }
    else 
        Send, {Blind}%key%

    if (delay > 0)
        Sleep, delay
}

SendKeyI(key, hwnd, delay:=0){
    SmartSendKey(key, hwnd, delay, "inactive")
}

SendKey(key, delay:=0) {
    WinGet, hwnd, ID, A
    SmartSendKey(key, hwnd, delay)
}

CalcCoords(hwnd, ByRef x, ByRef y, coord_mode := "", coord_type := "") {
    isClient := !InStr(coord_mode,"screen")
    isRatio := !InStr(coord_type,"fixed")
    
    if(!hwnd)
        return

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if(isRatio) {
        GetClientSize(hwnd, w, h)
        x := Round(x * w)
        y := Round(y * h)
    }
}

SmartClick(x, y, hwnd := "", btn := "L", send_mode := "", coord_Mode := "", coord_type := "") {
    if(!hwnd)
        return
    
    CalcCoords(hwnd, x, y, coord_mode, coord_type)
    if(send_mode = "inactive" && win && !InStr(coord_mode,"screen")) {
        AdjustClientToWindow(win, x, y)
        Sleep, 100
        SetControlDelay -1
        ControlClick, x%x% y%y%, %win%,, %btn%, , NA
    } else {
        MouseMove, %x%, %y%
        Sleep, 60
        if (btn = "R") {
            ; 우클릭: 0x08 (Down), 0x10 (Up)
            DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
            Sleep, 45
            DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
        } else {
            ; 좌클릭: 0x02 (Down), 0x04 (Up)
            DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
            Sleep, 45
            DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
        }
    }
}

;ControlClick
ClickI(x, y, hwnd:="", btn:= "L") {
    SmartClick(x, y, hwnd, btn, "inactive")
}

Click(x, y, hwnd:="", btn := "L") {
    SmartClick(x, y, hwnd, btn)
}

ClickA(x, y, btn := "L") {
    WinGet, hwnd, ID, A
    SmartClick(x, y, hwnd, btn)
}

ClickBack(x, y, targetHwnd, btn := "L") {
    if (!targetHwnd) {
        ShowTip("targetHwnd not found")
        return
    }
    BlockInput, On
    WinGet, origHwnd, ID, A
    if (origHwnd != targetHwnd) {
       WinActivateWait(targetHwnd)
    }
    CoordMode, Mouse, Screen
    MouseGetPos, origX, origY
    Click(x, y, targetHwnd, btn)
    CoordMode, Mouse, Screen
    MouseMove, %origX%, %origY%, 0
    if (WinExist("ahk_id " . origHwnd)) {
        WinActivate, ahk_id %origHwnd%
    }
    BlockInput, Off
}