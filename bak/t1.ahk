#SingleInstance Force
#Persistent
CoordMode, Mouse, Screen
SetBatchLines, -1

global isSelecting := false
global startX := 0, startY := 0, curX := 0, curY := 0
global scale := GetDPIScale()

#Include Gdip.ahk

; GDI+ 초기화
OnExit, ExitCleanup
if !pToken := Gdip_Startup() {
    MsgBox, GDI+ 초기화 실패
    ExitApp
}

; ===== MAIN GUI 생성 =====
Gui, main:New
Gui, main:+AlwaysOnTop +ToolWindow
Gui, main:Add, Text, vMouseInfo w200 h50, 마우스 위치 추적중...
Gui, main:Show, x10 y10 w220 h70, Main Tracker

SetTimer, UpdateMouseInfo, 100

; ===== 핫키 - 영역 선택 시작 / 캡처 =====
F4::
if (!isSelecting) {
    MouseGetPos, startX, startY
    Gui, cap:New
    Gui, cap:+AlwaysOnTop -Caption +E0x20 +LastFound
    WinSet, Transparent, 100
    Gui, cap:Color, Red
    Gui, cap:Show, x%startX% y%startY% w1 h1, Selector
    SetTimer, TrackMouse, 10
    isSelecting := true
} else {
    SetTimer, TrackMouse, Off
    WinGetPos, x, y, w, h, Selector
    MsgBox, % x "`n" y "`n" w "`n" h  Selector
    CaptureRegion(x, y, w, h)
    Gui, cap:Destroy
    isSelecting := false
}
return




{
    wdw
}

; ===== 마우스 추적 =====
TrackMouse:
MouseGetPos, curX, curY
x := (curX < startX) ? curX : startX
y := (curY < startY) ? curY : startY
w := (Abs(curX - startX) + 1) / scale
h := (Abs(curY - startY) + 1) / scale
Gui, cap:Show, x%x% y%y% w%w% h%h% NoActivate
return

; ===== 마우스 상태 표시 =====
UpdateMouseInfo:
MouseGetPos, mx, my
GuiControl, main:, MouseInfo, X: %mx%`nY: %my%
return

; ===== 캡처 후 이미지 표시 (img:) =====
CaptureRegion(x, y, w, h) {
    global pToken
    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
    if !pBitmap {
        MsgBox, 캡처 실패!
        return
    }
    Gui, img:Destroy
    Gui, img:New
    Gui, img:+AlwaysOnTop +ToolWindow
    Gui, img:Add, Picture, vImg1, HBITMAP:%pBitmap%
    Gui, img:Show, x300 y100, img: 캡처 이미지
    Gdip_DisposeImage(pBitmap)
}

; ===== DPI 스케일 계산 =====
GetDPIScale(){
    hDC := DllCall("GetDC", "ptr", 0, "ptr")
    dpi := DllCall("GetDeviceCaps", "ptr", hDC, "int", 88)  ; LOGPIXELSX
    DllCall("ReleaseDC", "ptr", 0, "ptr", hDC)
    return dpi / 96.0
}

; ===== GUI 종료 처리 =====
mainGuiClose:
ExitApp

ExitCleanup:
Gdip_Shutdown(pToken)
ExitApp

; ===== 핫키: Ctrl + Shift + R 로 리로드 =====
^+r::
Reload
return
