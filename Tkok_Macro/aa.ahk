#SingleInstance Force
SetBatchLines, -1
Gui, Font, s10, Consolas
Gui, +Resize
Gui, Add, Edit, vMacroBox w600 h400 hwndhEdit HScroll VScroll
Gui, Show,, 매크로 뷰어

; 오버레이 GUI 준비
Gui, Overlay:New, +AlwaysOnTop +ToolWindow -Caption +E0x20 +LastFound
Gui, Overlay:Color, FFDD88
Gui, Overlay:Add, Text, vLineOverlay x0 y0 w600 h20 BackgroundTrans Center

; 주기적 감지
SetTimer, CheckMouseProximity, 500
Return

CheckMouseProximity:
    CoordMode, Mouse, Screen
    MouseGetPos, mx, my

    ; 메크로 파싱
    GuiControlGet, MacroBox
    StringSplit, lines, MacroBox, `n
    Loop, %lines0%
    {
        line := lines%A_Index%
        if RegExMatch(line, "Click:L, *([\d.]+), *([\d.]+)", m)
        {
            px := m1, py := m2

            ; 화면 비율로 실제 위치 환산
            SysGet, mon, Monitor
            screenX := monRight - monLeft
            screenY := monBottom - monTop
            cx := Round(px * screenX)
            cy := Round(py * screenY)

            ; 마우스가 가까우면 강조
            if ( Abs(mx - cx) <= 200 && Abs(my - cy) <= 200 )
            {
                ShowLineOverlay(A_Index)
                Return
            }
        }
    }
    HideOverlay()
Return

ShowLineOverlay(lineNum) {
    global hEdit

    ; 현재 스크롤 위치
    SendMessage, 0xCE, 0, 0,, ahk_id %hEdit%  ; EM_GETFIRSTVISIBLELINE
    firstVisible := ErrorLevel

    ; 줄 높이 계산 (Consolas s10 기준 약 16px)
    lineHeight := 16
    yOffset := (lineNum - firstVisible - 1) * lineHeight
    if (yOffset < 0 || yOffset > 400)
    {
        HideOverlay()
        return
    }

    Gui, Overlay:Show, x10 y%yOffset% w600 h%lineHeight% NoActivate
    GuiControl, Overlay:, LineOverlay, ▶ 줄 %lineNum%
}

HideOverlay() {
    Gui, Overlay:Hide
}

GuiClose:
ExitApp


^r::reload