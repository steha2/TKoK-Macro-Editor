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

Win_BringToFront(winTitle := "A") {
    if (winTitle is integer) {
        winTitle := "ahk_id " . winTitle
    }    DllCall("SetWindowPos", "UInt", winTitle, "UInt", -1  ; HWND_TOP
        , "Int", 0, "Int", 0, "Int", 0, "Int", 0
        , "UInt", 0x0001 | 0x0002)  ; SWP_NOMOVE | SWP_NOSIZE
}

SetWindowTopNoActivate(hwnd) {
    ; HWND_TOPMOST = -1
    ; SWP_NOMOVE = 0x0002
    ; SWP_NOSIZE = 0x0001
    ; SWP_NOACTIVATE = 0x0010
    ; SWP_SHOWWINDOW = 0x0040
    flags := 0x0001 | 0x0002 | 0x0010 | 0x0040
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", flags)
}

WinActivateWait(winTitle) {
    if (winTitle is integer) {
        winTitle := "ahk_id " . winTitle
    }
    ;ShowTip("winwait........:`n" winTitle)
    WinActivate, %winTitle%
    WinWaitActive, %winTitle%,, 0.1
}
;-------------------------------- 마우스 함수 --------------------------------


; force가 false이고 마우스가 이미 클립된 상태면 클립 해제
; → force: 무조건 클립할지 여부. false일 경우 toggle처럼 동작.
UnclipMouse() {
    DllCall("ClipCursor", "Ptr", 0)
}

ToggleClipMouse(hwnd := "") {
    if (IsMouseClipped())
        UnclipMouse()
    else 
        ClipMouse(hwnd) ; 무조건 클립 실행
}

ClipMouse(hwnd := "") {
    hwnd := hwnd ? hwnd : WinExist("A")

    ; 클라이언트 좌표 및 크기 구하기
    VarSetCapacity(rect, 16, 0)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
    DllCall("ClientToScreen", "ptr", hwnd, "ptr", &rect)

    x1 := NumGet(rect, 0, "Int")
    y1 := NumGet(rect, 4, "Int")
    x2 := x1 + NumGet(rect, 8, "Int")  ; width
    y2 := y1 + NumGet(rect, 12, "Int") ; height

    ClipCursor(x1, y1, x2, y2)
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


; ------------------------------- 화면 함수 ---------------------------------

IsAllowedWindow(target) {
    if (target = "" || IsTargetWindow(target))
        return true
    else 
        return GetTargetWin(target) 
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

GetTargetWin(target, timeout := 1000, interval := 100) {
    if (target = "")
        return false

    candidates := ["ahk_class " . target, "ahk_exe " . target . ".exe", target]
    start := A_TickCount

    while ((A_TickCount - start) < timeout) {
        for index, each in candidates {
            if WinExist(each)
                return each
        }
        Sleep, interval
    }

    return false  ; 타임아웃까지 못 찾으면 false
}


GetClientSize(hwnd, ByRef w := "", ByRef h := "") {
    if (!hwnd) 
        return
    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
    w := NumGet(rect, 8, "int")
    h := NumGet(rect, 12, "int")
}

GetClientPos(hwnd, ByRef x:= "", ByRef y := "") {
    if (!hwnd)
        return
    ; 클라이언트 (0,0) → 화면 좌표 변환
    VarSetCapacity(pt, 8, 0)
    NumPut(0, pt, 0, "Int")  ; pt.x = 0
    NumPut(0, pt, 4, "Int")  ; pt.y = 0
    DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)

    x := NumGet(pt, 0, "Int")
    y := NumGet(pt, 4, "Int")
}

GetMouseRatio(hwnd, ByRef ratioX := "", ByRef ratioY := "") {
    if(!hwnd)
        return
    GetClientSize(hwnd, w, h)
    MouseGetPos, x, y, , , 2  ; 클라이언트 기준

    ; 유효성 검사
    if (!w || !h || w < 10 || h < 10) {
        ratioX := -1
        ratioY := -1
        ; ShowTip("오류: 클라이언트/스크린 크기를 가져올 수 없습니다.`n창 크기: width: " w " height: " h)
        return false
    }

    ; 비율 계산
    ratioX := Round(x / w, 3)
    ratioY := Round(y / h, 3)
    return true
}

GetMonitorSize(hwnd, ByRef w, ByRef h) {
    if(!hwnd)
        return

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

GetMouseMonitorRatio(ByRef rx, ByRef ry) {
    MouseGetPos, x, y

    SysGet, count, MonitorCount
    Loop %count%
    {
        SysGet, mon, Monitor, %A_Index%
        if (x >= monLeft && x < monRight && y >= monTop && y < monBottom) {
            monW := monRight - monLeft
            monH := monBottom - monTop
            rx := Round((x - monLeft) / monW, 3)
            ry := Round((y - monTop) / monH, 3)
            return true
        }
    }
    rx := ry := -1
    return false
}

GetWindowDPI(hwnd := "A") {
    if (hwnd = "A")
        WinGet, hwnd, ID, A
    ; AHK 1.1 은 기본적으로 DPI unaware → DPI 인식 설정이 필요할 수 있음
    hdc := DllCall("GetDC", "Ptr", hwnd, "Ptr")
    dpi := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 88)  ; LOGPIXELSX
    DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdc)
    return Round(dpi / 96 * 100)  ; 96 DPI가 100%
}


AdjustClientToWindow(win, ByRef x, ByRef y) {
    WinGet, hwnd, ID, %win%
    if (!hwnd)
        return false

    VarSetCapacity(pt, 8, 0)
    NumPut(x, pt, 0, "Int")
    NumPut(y, pt, 4, "Int")

    if !DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)
        return false

    ; 활성창의 좌상단 좌표 가져오기
    WinGetPos, wx, wy,,, ahk_id %hwnd%

    ; ControlClick 기준은 윈도우 내부 좌표 → 빼준다
    x := NumGet(pt, 0, "Int") - wx
    y := NumGet(pt, 4, "Int") - wy
    return true
}

ToggleMinimize(winTitle, force := "") {
    ; winTitle이 숫자면 HWND로 간주하고 변환
    if (winTitle is integer)
        winTitle := "ahk_id " . winTitle

    if !WinExist(winTitle)
        return false

    WinGet, style, MinMax, %winTitle%
    if (force = "min" || (!force && style != 1)) {
        WinMinimize, %winTitle%
    } else if (force = "restore" || (!force && style = 1)) {
        WinRestore, %winTitle%
    }
    return true
}
