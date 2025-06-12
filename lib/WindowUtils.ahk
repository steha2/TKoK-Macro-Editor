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

Win_WaitActive(winTitle, timeout := "") {
    WinWaitActive, %winTitle%, , %timeout%
}

Win_Wait(winTitle, timeout := "") {
    WinWait, %winTitle%, , %timeout%
}

WinActivateWait(winTitleOrHwnd, timeout := 0.1) {
    if (!winTitleOrHwnd)
        return false

    ; hwnd 가져오기
    hwnd := IsInteger(winTitleOrHwnd) ? winTitleOrHwnd : WinExist(winTitleOrHwnd)

    ; hwnd가 없고 문자열이라면 보조 탐색 함수 호출
    if (!hwnd && !IsInteger(winTitleOrHwnd)) {
        winTitle := GetTargetWin(winTitleOrHwnd)
        hwnd := WinExist(winTitle)
    } else {
        winTitle := "ahk_id " . hwnd
    }

    if (!hwnd)
        return false

    ; 이미 활성화된 창인지 확인
    if (hwnd != WinActive("A")) {
        WinActivate, %winTitle%
        WinWaitActive, %winTitle%,, %timeout%
    }
}


WinRaiseWithoutFocus(hwnd) {
    static HWND_TOP := 0
    static SWP_NOSIZE := 0x0001
    static SWP_NOMOVE := 0x0002
    static SWP_NOACTIVATE := 0x0010
    static SWP_SHOWWINDOW := 0x0040

    flags := SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_SHOWWINDOW

    DllCall("SetWindowPos"
        , "Ptr", hwnd
        , "Ptr", HWND_TOP
        , "Int", 0, "Int", 0, "Int", 0, "Int", 0
        , "UInt", flags)
}

;-------------------------------- 마우스 함수 --------------------------------


; force가 false이고 마우스가 이미 클립된 상태면 클립 해제
; → force: 무조건 클립할지 여부. false일 경우 toggle처럼 동작.
UnclipMouse() {
    DllCall("ClipCursor", "Ptr", 0)
    return false
}

; unclip시 false clip시 true
ToggleClipMouse(hwnd := "") {
    if (IsMouseClipped())
        return UnclipMouse()
    else 
        return ClipMouse(hwnd) ; 무조건 클립 실행
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
    return true
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

IsTargetWindow(target, hwnd := "") {
    if (target = "")
        return false

    hwnd := hwnd ? hwnd : WinExist("A")

    if (!hwnd)
        return

    WinGetTitle, title, ahk_id %hwnd%
    WinGetClass, class, ahk_id %hwnd%
    WinGet, exe, ProcessName, ahk_id %hwnd%

    return InStr(title, target, false) || InStr(class, target, false) || InStr(exe, target, false)
}

GetTargetWin(target) {
    if (target = "")
        return false

    candidates := ["ahk_class " . target, "ahk_exe " . target . ".exe", target]
    for index, each in candidates {
        if WinExist(each) {
            return each
        }
    }
    return false
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

ClientToScreen(hwnd, ByRef x, ByRef y) {
    VarSetCapacity(pt, 8, 0)  ; POINT 구조체 (x, y 각각 4바이트)
    NumPut(x, pt, 0, "Int")
    NumPut(y, pt, 4, "Int")
    DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)
    x := NumGet(pt, 0, "Int")
    y := NumGet(pt, 4, "Int")
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