; 윈도우 관련 래핑 함수 모음 (AHK v1)

Win_Restore(winTitle := "A") {
    WinRestore, %winTitle%
}

Win_Maximize(winTitle := "A") {
    WinMaximize, %winTitle%
}

Win_Minimize(winTitle := "A") {
    WinMinimize, %winTitle%
}

Win_Activate(winTitle := "A") {
    WinActivate, %winTitle%
}

Win_Close(winTitle := "A") {
    WinClose, %winTitle%
}

Win_Hide(winTitle := "A") {
    WinHide, %winTitle%
}

Win_Show(winTitle := "A") {
    WinShow, %winTitle%
}

Win_Move(winTitle := "A", x := "", y := "", w := "", h := "") {
    WinMove, %winTitle%, , %x%, %y%, %w%, %h%
}

Win_GetActiveTitle() {
    WinGetActiveTitle, title
    return title
}

Win_GetPos(winTitle := "A") {
    WinGetPos, x, y, w, h, %winTitle%
    return { x: x, y: y, w: w, h: h }
}

Win_IsVisible(winTitle := "A") {
    WinGet, style, Style, %winTitle%
    return (style & 0x10000000) != 0 ; WS_VISIBLE
}

Win_Exist(winTitle := "") {
    return WinExist(winTitle)
}

Win_WaitActive(winTitle, timeout := "") {
    WinWaitActive, %winTitle%, , %timeout%
}

Win_Wait(winTitle, timeout := "") {
    WinWait, %winTitle%, , %timeout%
}


;-------------------------------- 마우스 함수 --------------------------------

ClipWindow(force := false) {
    if (!force && IsMouseClipped()) {
        DllCall("ClipCursor", "Ptr", 0)
        isMouseClipped := false
        return
    }

    WinGet, hwnd, ID, A
    ; 클라이언트 좌표 및 크기 구하기
    VarSetCapacity(rect, 16, 0)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
    DllCall("ClientToScreen", "ptr", hwnd, "ptr", &rect)

    x1 := NumGet(rect, 0, "Int")
    y1 := NumGet(rect, 4, "Int")
    x2 := x1 + NumGet(rect, 8, "Int")  ; width
    y2 := y1 + NumGet(rect, 12, "Int") ; height

    ClipCursor(x1, y1, x2, y2)
    isMouseClipped := true
}

ClipCursor(x1 := "", y1 := "", x2 := "", y2 := "") {
    if (x1 = "") {
        DllCall("ClipCursor", "Ptr", 0)  ; 해제
    } else {
        VarSetCapacity(rect, 16, 0)
        args := x1 . "|" . y1 . "|" . x2 . "|" . y2
        Loop, Parse, args, |
            NumPut(A_LoopField, &rect, (a_index - 1) * 4)
        DllCall("ClipCursor", "Str", rect)
	}
}

IsMouseClipped() {
    VarSetCapacity(rc, 16, 0)
    success := DllCall("GetClipCursor", "Ptr", &rc)

    ; 데스크톱 전체 영역 구하기
    SysGet, VirtualScreenLeft, 76
    SysGet, VirtualScreenTop, 77
    SysGet, VirtualScreenRight, 78
    SysGet, VirtualScreenBottom, 79

    screenLeft := VirtualScreenLeft
    screenTop := VirtualScreenTop
    screenRight := VirtualScreenRight
    screenBottom := VirtualScreenBottom

    ; 클립 영역이 전체 화면이면, 클립되지 않은 상태
    left   := NumGet(rc, 0, "Int")
    top    := NumGet(rc, 4, "Int")
    right  := NumGet(rc, 8, "Int")
    bottom := NumGet(rc, 12, "Int")

    if (left = screenLeft && top = screenTop && right = screenRight && bottom = screenBottom)
        return false
    else
        return true
}

Click(x, y, btn := "L", coordMode := "", delay := 30) {
    isClient := !InStr(coordMode,"screen")
    isRatio := !InStr(coordMode,"fixed")

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    
    if(isRatio){
        if(isClient) {
            GetClientSize("A", w, h)
        } else {
            GetMonitorSize("A", w, h)
        }
        x := Round(x * w)
        y := Round(y * h)
    }

    MouseMove, %x%, %y%
    ; 우클릭일 경우
    Sleep, delay

    if (btn == "R" || btn == false) {
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
; ------------------------------- 화면 함수 ---------------------------------

IsAllowedWindow(target) {
    if (target = "" || IsTargetWindow(target))
        return true
    else 
        return ActivateWindow(target) 
}

IsTargetWindow(target, hwnd := "A") {
    if (target = "")
        return false

    hwnd := (hwnd = "A") ? WinExist("A") : hwnd
    if (!hwnd)
        return false

    WinGetTitle, title, ahk_id %hwnd%
    WinGetClass, class, ahk_id %hwnd%
    WinGet, exe, ProcessName, ahk_id %hwnd%

    return InStr(title, target, false) || InStr(class, target, false) || InStr(exe, target, false)
}

ActivateWindow(target) {
    if (target = "")
        return false

    targetClass := "ahk_class " . target
    ; 2. ahk_class 로 시도 
    if WinExist(targetClass) {
        WinActivate, %targetClass%
        return WinActive(targetClass)
    }

    targetExe := "ahk_exe" . target . ".exe"
    if WinExist(targetExe) {
        WinActivate, %targetExe%
        return WinActive(targetExe)
    }

    ; 4. 마지막으로 title에 포함된 창 찾기
    if WinExist(target) {
        WinActivate, %target%
        return WinActive(target)
    }

    ShowTip("대상 창을 활성화 할 수 없습니다.`n`nTarget : "  target)
    return false
}

GetClientSize(hwnd := "A", ByRef w := "", ByRef h := "") {
    if (!hwnd || hwnd = "A")
        WinGet, hwnd, ID, A

    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
    w := NumGet(rect, 8, "int")
    h := NumGet(rect, 12, "int")
}

GetMouseRatio(ByRef ratioX, ByRef ratioY, hwnd := "A") {
    ; hwnd 생략 시 활성 창 사용
    if (hwnd = "A")
        WinGet, hwnd, ID, A

    GetClientSize(hwnd, w, h)

    ; 유효성 검사
    if (!w || !h || w < 10 || h < 10) {
        ratioX := -1
        ratioY := -1
        Showtip("오류, 클라이언트 영역 크기를 가져오지 못했거나 유효하지 않습니다.`n창 크기: width : " w " height : " h)
        return false
    }

    ; 마우스 좌표 (클라이언트 기준)
    MouseGetPos, x, y, , , 2

    ; 비율 계산
    ratioX := Round(x / w, 3)
    ratioY := Round(y / h, 3)
    return true
}

GetMonitorSize(hwnd, ByRef w, ByRef h) {
    if(hwnd = "A")
        WinGet, hwnd, ID, A

    MONITOR_DEFAULTTONEAREST := 2
    hMonitor := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", MONITOR_DEFAULTTONEAREST, "Ptr")

    VarSetCapacity(mi, 40)
    NumPut(40, mi, 0, "UInt")
    DllCall("GetMonitorInfo", "Ptr", hMonitor, "Ptr", &mi)

    left   := NumGet(mi, 4, "Int")
    top    := NumGet(mi, 8, "Int")
    right  := NumGet(mi, 12, "Int")
    bottom := NumGet(mi, 16, "Int")

    w := right - left
    h := bottom - top
}
