ChatPaste(text, hwnd := "", send_mode := "") {
    isValid := StrLen(text) > 0
    
    if(isValid){
        ClipSaved := ClipboardAll
        Clipboard := text
        ClipWait, 0.5
    }
    if (send_mode = "inactive" && hwnd) {
        SendKeyI("{Enter}", hwnd, -20)
        if (isValid)
            SendKeyI("{ctrl down}v{ctrl up}", hwnd, -20)
        SendKeyI("{Enter}", hwnd, 30)
    } else {
        if (isValid) {
            if (hwnd && hwnd != Win_Exist("A"))
                WinActivateWait(hwnd)
        }
        SendKey("{Enter}", -50)
        if (isValid)
            SendKey("^v", -50)
        SendKey("{Enter}", 50)
    }
    if (isValid)
        Clipboard := ClipSaved
}

Chat(text, hwnd := "", send_mode := "") {
    isValid := StrLen(text) > 0
    if (send_mode = "inactive" && hwnd) {
        SendKeyI("{Enter}", hwnd, -20)
        
        if (isValid)
            SendKeyI(text, hwnd, -20)
        
        SendKeyI("{Enter}", hwnd, 30)
    } else {
        if (isValid) {
            if (hwnd && hwnd != Win_Exist("A"))
                WinActivateWait(hwnd)
        }
        SendKey("{Enter}", 100)
        if (isValid) {
            Suspend, On
            SendRaw, %text%
            Suspend, Off
        }
        SendKey("{Enter}")
    }
}

ChatPI(text, hwnd) {
    ChatPaste(text, hwnd, "inactive")
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
    SmartSendKey(key, WinExist("A"), delay)
}

CalcCoords(hwnd, ByRef x, ByRef y, coord_mode := "", coord_type := "") {
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
    SmartClick(x, y, WinExist("A"), btn)
}

ClickBack(x, y, hwnd, btn := "L") {
    click := {x: x, y: y, hwnd: hwnd, btn: btn}
    ClickBackEx(click)
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
