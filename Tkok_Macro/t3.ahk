#SingleInstance
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

CoordMode, Mouse, Client
global xPos := 1355, yPos := 283, winTitle := "Warcraft III"

F1::
MsgBox, x%xPos% y%yPos%, %winTitle%
ControlClick, x%xPos% y%yPos%, %winTitle%
return

F2::
ControlClickSmart("Button1", "Warcraft III", 10, 10)
return

#Include, LibIncludes.ahk

^r:: reload

ControlClickSmart(ctrl, winTitle := "A", x := 5, y := 5, btn := "L") {
    WinGet, hwnd, ID, %winTitle%
    if (!hwnd) {
        MsgBox, 창을 찾을 수 없습니다: %winTitle%
        return
    }

    ; 1. ControlClick 시도

    ; 2. PostMessage 시도
    btnDown := (btn = "R") ? 0x204 : 0x201  ; WM_RBUTTONDOWN : WM_LBUTTONDOWN
    btnUp   := (btn = "R") ? 0x205 : 0x202  ; WM_RBUTTONUP   : WM_LBUTTONUP
    lParam := (y << 16) | (x & 0xFFFF)

    PostMessage, %btnDown%, 0, %lParam%, %ctrl%, ahk_id %hwnd%
    Sleep, 50
    PostMessage, %btnUp%, 0, %lParam%, %ctrl%, ahk_id %hwnd%
    Sleep, 100
    if (A_LastError = 0) {
        MsgBox, 성공: PostMessage
        return
    }

    ; 3. 마우스 물리 클릭 (스크린 좌표로 환산 필요)
    ControlGetPos, cx, cy, cw, ch, %ctrl%, ahk_id %hwnd%
    if (cx = "") {
        MsgBox, 실패: 컨트롤 위치 정보를 가져올 수 없습니다.
        return
    }

    x_screen := cx + x
    y_screen := cy + y
    DllCall("SetCursorPos", "int", x_screen, "int", y_screen)
    Sleep, 50
    if (btn = "R") {
        DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0) ; Right Down
        Sleep, 50
        DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0) ; Right Up
    } else {
        DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0) ; Left Down
        Sleep, 50
        DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0) ; Left Up
    }

    MsgBox, 성공: mouse_event (강제 클릭)
}
