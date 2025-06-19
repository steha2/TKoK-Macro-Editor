
SmartClick(x, y, hwnd := "", btn := "L", send_mode := "", coord_mode := "") {
    event := {x:x, y:y, hwnd:hwnd, btn:btn, send_mode:send_mode, coord_mode:coord_mode}
    MouseEvent(event)
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

; ClickW3(coordKey, btn := "L", mode := "", hwnd := "") {
;     hwnd := hwnd ? hwnd : WinExist("A")

;     if(!IsTargetWindow(W3_WINTITLE, wnd))
;         return ShowTip("Warcraft III 창이 아닙니다.")

;     w3_ver := IsReforged(hwnd) ? "reforged" : "classic"
;     coords := ParseCoords(coordMap[w3_ver][coordKey])

;     if(coords)
;         SmartClick(coords.x, coords.y, hwnd, btn, mode, "", coords.type)
; }

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
    MouseMove(origX, origY, "", "", "screen,fixed")

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
        SendKey("{Enter}", RemoveChars(mode, "R") , hwnd, 50)

    if (InStr(mode, "R")) {
        SendKey(text, mode, hwnd)
    } else {
        PasteText(text, mode, hwnd)  ;복붙이 기본값
    }
    ; 뒤 Enter
    if (enterMode = 2 || enterMode = 3)
        SendKey("{Enter}", RemoveChars(mode, "R"), hwnd, -50)
}

PasteText(text, mode := "", hwnd := "") {
    if (StrLen(text) = 0)
        return
    ;ClipSaved := ClipboardAll
    Clipboard := text
    ClipWait, 0.5
    Sleep(50)
    pasteKey := InStr(mode, "C") ? "{Ctrl down}v{Ctrl up}" : "^v"
    SendKey(pasteKey, RemoveChars(mode, "R"), hwnd, 110)
    ;Clipboard := ClipSaved
}

SendKey(key, mode := "", hwnd := "", delay := 0) {
    if (muteAll)   
        return

    if (hwnd && !WinExist("ahk_id " . hwnd))
        return ShowTip("SendKey()`n지정된 창이 없습니다. hwnd :" . hwnd)

    if (delay < 0)
        Sleep(-delay)

    if (InStr(mode, "NS"))
        key := StrReplace(key, " ")

    isControl := InStr(mode, "C")
    isRaw := InStr(mode, "R")

    if (isControl) {
        if (!hwnd)
            hwnd := WinActive("A")
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
        Sleep(delay)
}

SendA(key, delay := 0) {
    SendKey(key, "", "", delay)
}

MouseMove(x, y, hwnd := "", send_mode := "", coord_mode := "") {
    MouseEvent({x:x, y:y, hwnd:hwnd, send_mode:send_mode, coord_mode:coord_mode})
}

ClickDrag(x1, y1, x2, y2, btn := "L", speed := 500) {
    hwnd := WinActive("A")
    CalcCoords(x1, y1, hwnd)
    CalcCoords(x2, y2, hwnd)
    MouseClickDrag, %btn%, %x1%, %y1%, %x2%, %y2%, %speed%
}

MouseDrag(x1, y1, x2, y2, hwnd := "" , btn := "L", send_mode := "", coord_mode := "") {
    event := {x:x1, y:y1, hwnd:hwnd, btn:btn . "D", send_mode:RemoveChars(send_mode, "C"), coord_mode:coord_mode}
    
    MouseEvent(event)
    event.btn := ""
    event.x := x2
    event.y := y2
    
    Sleep(100)
    MouseEvent(event)

    event.btn := btn . "U"
    MouseEvent(event)
}

MouseEvent(event) {
    if (muteAll)   
        return

    hwnd := event.hwnd
    if (hwnd && !WinExist("ahk_id " . hwnd))
        return FalseTip("MouseEvent()`n지정된 창이 없습니다. hwnd: " . hwnd)

    ; 필수 값 추출
    x := event.x, y := event.y
    hwnd := hwnd ? hwnd : WinExist("A")
    btn := event.btn

    ; 좌표 변환
    CalcCoords(x, y, hwnd, event.coord_mode)

    ; 버튼 및 액션 파싱
    baseBtn := SubStr(btn, 1, 1)
    isDown := InStr(btn, "D")
    isUp   := InStr(btn, "U")

    ; ControlClick 모드
    if (InStr(event.send_mode, "C")) {
        AdjustWindowToClient(hwnd, x, y)
        Sleep(100)
        clickOpt := isDown ? "D" : isUp ? "U" : ""
        ControlClick, x%x% y%y%, ahk_id %hwnd%,, %baseBtn%,, %clickOpt% NA
    }
    ; 물리 입력
    else {
        WinActivateWait(hwnd)
        PhysMouseInput(x, y, btn)
    }
}
