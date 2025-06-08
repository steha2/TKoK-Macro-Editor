#NoEnv
SendMode Input
SetWorkingDir, %A_ScriptDir%
#SingleInstance Force
FileEncoding, UTF-8
SetTitleMatchMode, 2
SetKeyDelay, -1, 60
SetControlDelay, -1

; 관리자 권한이 아니면 재실행
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}
global logFilePath :=  A_Temp "\macro_test_log.txt"
global isLaunchedByMain := true

#Include %A_ScriptDir%\src\InitCodeLoader.ahk 
#Include %A_ScriptDir%\MacroEditor.ahk

#Include %A_ScriptDir%\src\CodeLoaderEvents.ahk
#Include %A_ScriptDir%\src\TKoK_Funcs.ahk
#Include %A_ScriptDir%\src\War3Funcs.ahk

#Include %A_ScriptDir%\lib\LibIncludes.ahk