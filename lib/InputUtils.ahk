Chat(text, send_mode := "", hwnd := "") {
   if (InStr(send_mode, "P", 1)) {
        ChatPaste(text, send_mode, hwnd)
   } else {
        ChatRaw(text, send_mode, hwnd)
   }
}

ChatPaste(text, send_mode := "", hwnd := "") {
    isValid := StrLen(text) > 0
    if (isValid) {
        ClipSaved := ClipboardAll
        Clipboard := text
        ClipWait, 0.5
    }
    SendKey("{Enter}", send_mode, hwnd, -50)
    if (isValid) {
        pasteKey := InStr(send_mode, "I", 1) ? "{ctrl down}v{ctrl up}" : "^v"
        SendKey(pasteKey, send_mode, hwnd, -20)
    }
    SendKey("{Enter}", send_mode, hwnd, 50)
    if (isValid)
        Clipboard := ClipSaved
}

ChatRaw(text, send_mode := "", hwnd := "") {
    SendKey("{Enter}", send_mode, hwnd, 100)
    if (StrLen(text) > 0) {
        Suspend, On
        SendRawKey(text, send_mode, hwnd)
        Suspend, Off
    }
    SendKey("{Enter}", send_mode, hwnd)
}

;dealy :음/양수 선/후 딜레이
SendKey(key, send_mode := "", hwnd := "", delay := 0) {
    if (StrLen(key) = 0)
        return

    if (hwnd && !WinExist("ahk_id " . hwnd))
        return ShowTip("SendKey()`n지정된 창이 없습니다. hwnd :" . hwnd)
    
    if(!hwnd)
        hwnd := WinExist("A")

    if (delay < 0)
        Sleep, -delay

    if (InStr(send_mode, "NS", 1))
        key := StrReplace(key, " ")

    if (InStr(send_mode, "I", 1)) {
        if (InStr(send_mode, "R", 1) )
            ControlSendRaw,, %key%, ahk_id %hwnd%
        else
            ControlSend,, %key%, ahk_id %hwnd%
    } else {
        if (hwnd && hwnd != WinExist("A"))
            WinActivateWait(hwnd)

        if (InStr(send_mode, "R", 1) )
            SendRaw, %key%
        else
            Send, {Blind}%key%
    }
    if (delay > 0)
        Sleep, delay
}

SendRawKey(key, send_mode := "",  hwnd := "", delay := 0) {
    SendKey(key, send_mode . "R", hwnd, delay)
}

SendKeyA(key, delay := 0) {
    SendKey(key, "", "", delay)
}

CalcCoords(ByRef x, ByRef y, hwnd, coord_mode := "", coord_type := "") {
    if(!hwnd)
        return

    isClient := !InStr(coord_mode,"screen")
    isRatio := !InStr(coord_type,"fixed")

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if(isRatio) {
        GetClientSize(hwnd, w, h)
        x := Round(x * w)
        y := Round(y * h)
    }
}

SmartClick(x, y, hwnd := "", btn := "L", send_mode := "", coord_mode := "", coord_type := "") {
    if (hwnd && !WinExist("ahk_id " . hwnd))
        return ShowTip("SmartClick()`n지정된 창이 없습니다. hwnd: " . hwnd)

    if (!hwnd)
        hwnd := WinExist("A")

    if (InStr(send_mode, "I", true)) {
        SmartClick_ControlClick(x, y, hwnd, btn, coord_mode, coord_type)
    } else {
        if (hwnd != WinExist("A"))
            WinActivateWait(hwnd)

        if (!WinExist("ahk_id " . hwnd))
            return ShowTip("SmartClick()`n활성화에 실패했습니다. hwnd: " . hwnd)
        
        SmartClick_MouseClick(x, y, hwnd, btn, coord_mode, coord_type)
    }
}

SmartClick_ControlClick(x, y, hwnd, btn, coord_mode := "", coord_type := "") {
    CalcCoords(x, y, hwnd, coord_mode, coord_type)
    AdjustClientToWindow(hwnd, x, y)
    Sleep, 100
    ControlClick, x%x% y%y%, ahk_id %hwnd%,, %btn%,, NA
}

SmartClick_MouseClick(x, y, hwnd, btn, coord_mode := "", coord_type := "") {
    CalcCoords(x, y, hwnd, coord_mode, coord_type)
    MouseMove, %x%, %y%
    Sleep, 60

    if (btn = "R") {
        DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
        Sleep, 45
        DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
    } else {
        DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
        Sleep, 45
        DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
    }
}


;ControlClick
Click(x, y, hwnd:="", btn := "L", send_mode := "") {
    SmartClick(x, y, hwnd, btn, send_mode)
}

ClickA(x, y, btn := "L", send_mode := "") {
    Click(x, y, WinExist("A"), btn, send_mode)
}

ClickBack(x, y, hwnd, btn := "L") {
    ClickBackEx({x: x, y: y, hwnd: hwnd, btn: btn})
}

ClickBackEx(clickArray) {
    static currentHwnd := ""
    
    if (!IsObject(clickArray))
        return ShowTip("clickArray is not an object")
    if (!clickArray.HasKey(1))  ; 단일 객체일 경우 배열처럼 래핑
        clickArray := [clickArray]
    
    BlockInput, On
    CoordMode, Mouse, Screen
    MouseGetPos, origX, origY
    WinGet, origHwnd, ID, A
    WinGet, winState, MinMax, ahk_id %hwnd%
    wasMinimized := (winState == 2)

    for index, click in clickArray {
        ; hwnd가 있으면 currentHwnd 갱신
        if (click.HasKey("hwnd")) {
            currentHwnd := click.hwnd
        }
        if (!currentHwnd || !WinExist("ahk_id " currentHwnd)) {
            ShowTip("Invalid hwnd at index " index)
            continue
        }
        if(WinExist("A") != currentHwnd)
            WinActivateWait(currentHwnd)

        btn := click.HasKey("btn") ? click.btn : "L"
        Click(click.x, click.y, currentHwnd, btn)
    }

    ; 마우스 위치 복귀
    CoordMode, Mouse, Screen
    MouseMove, %origX%, %origY%, 0
    ; 이전 창 복귀
    if (WinExist("ahk_id " . origHwnd)) {
        WinActivate, ahk_id %origHwnd%
    }
    if (wasMinimized) {
        WinMinimize, ahk_id %hwnd%
    }
    BlockInput, Off
}
