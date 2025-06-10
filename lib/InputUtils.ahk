Chat(text, mode := "", hwnd := "") {
    enterMode := 3  ; 기본 앞뒤 Enter
    if (RegExMatch(mode, "E(\d)", m))
        enterMode := m1 + 0

    if (InStr(mode, "NS"))
        text := StrReplace(text, " ")

    ; 앞 Enter
    if (enterMode = 1 || enterMode = 3)
        SendKey("{Enter}", RemoveChars(mode, "R") , hwnd, 30)

    if (InStr(mode, "R")) {
        SendKey(text, mode, hwnd)
    } else {
        PasteText(text, mode, hwnd)  ;복붙이 기본값
    }
    ; 뒤 Enter
    if (enterMode = 2 || enterMode = 3)
        SendKey("{Enter}", RemoveChars(mode, "R"), hwnd, -30)
}

PasteText(text, mode := "", hwnd := "") {
    if (StrLen(text) = 0)
        return
    ;ClipSaved := ClipboardAll
    Clipboard := text
    ClipWait, 0.5
    pasteKey := InStr(mode, "C") ? "{Ctrl down}v{Ctrl up}" : "^v"
    SendKey(pasteKey, RemoveChars(mode, "R"), hwnd, 100)
    ;Clipboard := ClipSaved
}

SendKey(key, mode := "", hwnd := "", delay := 0) {
    if (hwnd && !WinExist("ahk_id " . hwnd))
        return ShowTip("SendKey()`n지정된 창이 없습니다. hwnd :" . hwnd)

    if (delay < 0)
        Sleep, -delay

    if (InStr(mode, "NS"))
        key := StrReplace(key, " ")

    isControl := InStr(mode, "C")
    isRaw := InStr(mode, "R")

    if (isControl) {
        if (!hwnd)
            hwnd := WinExist("A")
        if (isRaw)
            ControlSendRaw,, %key%, ahk_id %hwnd%
        else
            ControlSend,, %key%, ahk_id %hwnd%
    } else {
        ActivateHwnd(hwnd)
        if (isRaw) {
            Suspend, On
            SendRaw, %key%
            Suspend, Off
        } else
            Send, {Blind}%key%
    }

    if (delay > 0)
        Sleep, delay
}


Send1(key, delay := 0) {
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

SmartClick(x, y, hwnd := "", btn := "L", mode := "", coord_mode := "", coord_type := "") {
    if (hwnd && !WinExist("ahk_id " . hwnd))
        return ShowTip("SmartClick()`n지정된 창이 없습니다. hwnd: " . hwnd)
    hwnd := hwnd ? hwnd : WinExist("A")
    CalcCoords(x, y, hwnd, coord_mode, coord_type)

    if (InStr(mode, "I", true)) {
        AdjustClientToWindow(hwnd, x, y)
        Sleep, 100
        ControlClick, x%x% y%y%, ahk_id %hwnd%,, %btn%,, NA
    } else {
        ActivateHwnd(hwnd)
        PhysClick(x, y, btn)
    }
}

PhysClick(x, y, btn) {
    MouseMove, %x%, %y%
    if (btn = "R") {
        Sleep, 60
        DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
        Sleep, 45
        DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
    } else if (btn = "L") {
        Sleep, 60
        DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
        Sleep, 45
        DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
    }
}


;ControlClick
Click(x, y, hwnd:="", btn := "L", mode := "") {
    SmartClick(x, y, hwnd, btn, mode)
}

ClickA(x, y, btn := "L", mode := "") {
    Click(x, y, WinExist("A"), btn, mode)
}

ClickBack(x, y, hwnd, btn := "L") {
    ClickBackEx({x: x, y: y, hwnd: hwnd, btn: btn})
}

ClickBackEx(clickArray) {
    if (!IsObject(clickArray))
        return ShowTip("clickArray is not an object")
    if (!clickArray.HasKey(1))  ; 단일 객체일 경우 배열처럼 래핑
        clickArray := [clickArray]

    BlockInput, On
    CoordMode, Mouse, Screen
    MouseGetPos, origX, origY
    WinGet, origHwnd, ID, A

    minimizedArray := []

    for index, click in clickArray {
        currHwnd := click.hwnd
        
        if (!currHwnd || !WinExist("ahk_id " currHwnd)) {
            ShowTip("Invalid hwnd at index " index)
            continue
        }

        WinGet, winState, MinMax, ahk_id %currHwnd%
        wasMinimized := (winState == 2)

        ; 만약 창이 최소화 상태였다면 목록에 추가
        if (wasMinimized)
            minimizedArray.push(currHwnd)

        ; 현재 활성 윈도우가 아니라면 대상 창 활성화
        ActivateHwnd(hwnd)

        btn := click.HasKey("btn") ? click.btn : "L"
        Click(click.x, click.y, currHwnd, btn)
    }

    ; 마우스 위치 복귀
    CoordMode, Mouse, Screen
    MouseMove, %origX%, %origY%, 0

    ; 작업 전 활성화되었던 창 복귀
    if (WinExist("ahk_id " . origHwnd)) {
        WinActivate, ahk_id %origHwnd%
    }

    ; 최소화 상태였던 창들 다시 최소화 처리
    for index, hwnd in minimizedArray {
        if (WinExist("ahk_id " hwnd)) {
            WinMinimize, ahk_id %hwnd%
        }
    }

    currHwnd := ""
    BlockInput, Off
}
