
SmartClick(x, y, hwnd := "", btn := "L", mode := "", coord_mode := "", coord_type := "") {
    if (hwnd && !WinExist("ahk_id " . hwnd))
        return ShowTip("SmartClick()`n지정된 창이 없습니다. hwnd: " . hwnd)
    hwnd := hwnd ? hwnd : WinExist("A")
    CalcCoords(x, y, hwnd, coord_mode, coord_type)

    if (InStr(mode, "C", true)) {
        AdjustWindowToClient(hwnd, x, y)
        Sleep, 100
        ControlClick, x%x% y%y%, ahk_id %hwnd%,, %btn%,, NA
    } else {
        WinActivateWait(hwnd)
        PhysClick(x, y, btn)
    }
}

;ControlClick
Click(x, y, hwnd:="", btn := "L", mode := "") {
    SmartClick(x, y, hwnd, btn, mode)
}

ClickA(x, y, btn := "L", mode := "") {
    hwnd := WinActive("A")  ; 활성 상태일 때만 HWND를 반환
    if (hwnd)
        Click(x, y, hwnd, btn, mode)
}

ClickW3(coordKey, btn := "L", mode := "", hwnd := "") {
    hwnd := hwnd ? hwnd : WinExist("A")

    if(!IsTargetWindow(W3_WINTITLE, wnd))
        return ShowTip("Warcraft III 창이 아닙니다.")

    w3_ver := IsReforged(hwnd) ? "reforged" : "classic"
    coords := ParseCoords(coordMap[w3_ver][coordKey])

    if(coords)
        SmartClick(coords.x, coords.y, hwnd, btn, mode, "", coords.type)
}

ClickBack(x, y, hwnd, btn := "L") {
    ClickBackEx({x: x, y: y, hwnd: hwnd, btn: btn})
}

ClickBackEx(clickCmdArr) {
    if (!IsObject(clickCmdArr))
        return ShowTip("clickCmdArr is not an object")
    if (!clickCmdArr.HasKey(1))  ; 단일 객체일 경우 배열처럼 래핑
        clickCmdArr := [clickCmdArr]

    ; BlockInput, On
    CoordMode, Mouse, Screen
    MouseGetPos, origX, origY
    WinGet, origHwnd, ID, A

    minimizedArray := []
    for index, clickCmd in clickCmdArr {
        currHwnd := clickCmd.hwnd
        
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
        btn := clickCmd.HasKey("btn") ? clickCmd.btn : "L"
        Click(clickCmd.x, clickCmd.y, currHwnd, btn)
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
    ; BlockInput, Off
    currHwnd := ""

}

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
        WinActivateWait(hwnd)

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

SendA(key, delay := 0) {
    SendKey(key, "", "", delay)
}
