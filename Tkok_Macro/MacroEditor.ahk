#NoEnv
SendMode Input
SetWorkingDir, %A_ScriptDir%
#SingleInstance Force
FileEncoding, UTF-8
SetTitleMatchMode, 2

; 관리자 권한이 아니면 재실행
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

#Include %A_ScriptDir%\src\InitMacroEditor.ahk
#Include %A_ScriptDir%\src\MacroEdit.ahk
#Include %A_ScriptDir%\src\MacroEditorEvents.ahk
#Include %A_ScriptDir%\src\TreeViewHandler.ahk
#Include %A_ScriptDir%\src\MacroExec.ahk
#Include %A_ScriptDir%\lib\CommonUtils.ahk
