#NoEnv
SendMode Input
SetWorkingDir, %A_ScriptDir%
#SingleInstance Force
FileEncoding, UTF-8
SetTitleMatchMode, 3
SetKeyDelay, -1, 60
SetControlDelay, -1
CoordMode, Pixel, Screen

; 관리자 권한이 아니면 재실행
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}
global logFilePath :=  A_Temp "\macro_test_log.txt"
global DEBUG_LEVEL := 2