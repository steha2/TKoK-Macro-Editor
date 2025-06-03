#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

;global hOver
global hBtn
; ----------------------------
; 1. 배경 오버레이 (어두운 블루, 투명도 낮음)
;WinSet, Transparent, 160, ahk_id %hOver%

; ----------------------------
; 2. 버튼 GUI (완전 투명 배경 + 선명한 버튼)
Gui, buttons:+AlwaysOnTop +ToolWindow +HwndhBtn
Gui, buttons:Color, 0xF23456  ; 배경색 (투명 처리용)

; 버튼 추가 (배경색은 기본 시스템색으로, 불투명하게 보임)
Gui, buttons:Font, s10, Segoe UI
Gui, buttons:Add, Button, x50 y50 w120 h40 gMyAction, 실행
Gui, buttons:Show, x200 y200 NoActivate

WinSet, TransColor, 0xF23456 200, ahk_id %hBtn%
;WinSet, TransColor, 0xF23456 50, ahk_id %hBtn%
return



MyAction:
MsgBox, 버튼 클릭됨!
return

^r:: reload