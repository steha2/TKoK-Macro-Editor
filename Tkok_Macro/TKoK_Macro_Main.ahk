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

global W3_LAUNCH_DELAY := 4000 ; 워크래프트3 실행 후 4초간 대기한다

global w3Win := "Warcraft III"
global pl1, pl2, la, yMapped
global configFile := A_ScriptDir . "\config.ini"
global macroDir := A_ScriptDir . "\macro"

IniRead, savedPath, %configFile%, Settings, SAVE_DIR
IniRead, savedLnk, %configFile%, Settings, W3_LNK

global saveDir := Trim(savedPath)
global w3lnk := Trim(savedLnk)

if (saveDir = "")
    saveDir := A_ScriptDir

;----------------Macro global vars------------------
global g_PathMap := {}  ; TreeView ID → 전체 경로 매핑
global isRecording := false
global runMacroCount := 0
global macroAbortRequested := false
global macroGuiShown := false
global macroPath := ""
global suspendTreeEvents := false

;---------------------------------------------------

#Include %A_ScriptDir%\lib\InitGui.ahk 
return ;---------------여기 까지 자동실행 ------------------
#Include %A_ScriptDir%\lib\/\MacroEditor.ahk
#Include %A_ScriptDir%\lib\TreeViewFuncs.ahk
#Include %A_ScriptDir%\lib\MacroExecFuncs.ahk
#Include %A_ScriptDir%\lib\MacroFuncs.ahk
#Include %A_ScriptDir%\lib\CommonFuncs.ahk
#Include %A_ScriptDir%\lib\TKoK_Funcs.ahk
#Include %A_ScriptDir%\lib\War3Funcs.ahk

mainGuiClose:
SaveGuiSettings()

ToggleSpy:
if (WinExist("ahk_id " . miniSpyHwnd))
{
    WinClose, ahk_id %miniSpyHwnd%
    miniSpyHwnd := ""
}
else
{
    Run, *RunAs "%A_ScriptDir%\lib\MiniSpy.ahk", , , pid
    WinWait, ahk_pid %pid%, , 2
    if ErrorLevel {
        MsgBox, MiniSpy 실행 실패
        return
    }
    miniSpyHwnd := WinExist("ahk_pid " . pid)
}
return

MultiLoad:
LoadSquad()
return

ExecMultiW3:
ExecMultiW3()
return

HeroButtonClick:
Gui, Submit, NoHide
GuiControlGet, btnText, , %A_GuiControl% ; 버튼의 텍스트를 가져온다
UpdateHeroInfo(btnText)
return

AddHero:
GuiControlGet, resultText,, ResultOutput
if(!resultText)
    return
heroNames := ""

Loop, Parse, resultText, `n, `r
{
    if (RegExMatch(A_LoopField, "Hero:\s*(.+)", match))
        heroNames .= match1 . ","
}

; 마지막 쉼표 제거
StringTrimRight, heroNames, heroNames, 1

GuiControlGet, oldSquad,, SquadField

; 일반 클릭 시 클래스 추가
if (oldSquad != "")
    newSquad := oldSquad . "," . heroNames
else
    newSquad := heroNames

GuiControl,, SquadField, %newSquad%
IniWrite, %newSquad%, %configFile%, Settings, SavedSquad
return

RemoveHero:
GuiControlGet, oldSquad,, SquadField
if (oldSquad = "")
    return
newSquad := TrimLastToken(oldSquad, ",")
GuiControl,, SquadField, %newSquad%
IniWrite, %newSquad%, %configFile%, Settings, SavedSquad
return

AptBtn:
ReadAptFile()
if(la != "" && WinExist(w3Win)) {
    WinActivate, %w3Win%
    Chat(la)
}
return

LoadBtn:
if(WinExist(w3Win)) {
    WinActivate, %w3Win%
    SendCodeToW3()
}
return

; GUI 위치 저장
SaveGuiSettings(isExit := true) {
    ; 메인 GUI
    WinGet, min1, MinMax, ahk_id %hMain%
    IniWrite, % (min1 == -1), %configFile%, MainGUI, Minimized

    if(min1)
        WinRestore, ahk_id %hMain%

    WinGetPos, x1, y1,,, ahk_id %hMain%
    IniWrite, %x1%, %configFile%, MainGUI, X
    IniWrite, %y1%, %configFile%, MainGUI, Y

    IniWrite, % (yMapped ? "true" : "false"), %configFile%, Settings, yMapped
    IniWrite, % (macroGuiShown ? "true" : "false"), %configFile%, MacroGUI, Shown

    WinGetPos, x2, y2,,, ahk_id %hMacro%
    if(x2 > 0)
        IniWrite, %x2%, %configFile%, MacroGUI, X
    if(y2 > 0)
        IniWrite, %y2%, %configFile%, MacroGUI, Y
    ;~ MsgBox, %x2% %y2%
    if(isExit)
        ExitApp
}

#If (WinActive("ahk_class Warcraft III") and yMapped and !isRecording)
;Y키와 F키를 서로바꿈 Ctrl+F 를 누르면 F를 누른것처럼 작동
y::Send, f
f::Send, y
^f::Send, % yMapped ? "f" : "^f"

#IfWinActive ahk_class Warcraft III
^y::ToggleYMapping(2)

; 토글 함수
ToggleYMapping(force := 2) {
    if (force != 2)
        yMapped := !!force
    else
        yMapped := !yMapped
    ShowTip(yMapped ? "🟢 y↔f 매핑 켜짐" : "🔴 y↔f 매핑 꺼짐")
}

;Interact
F4::
SendKey("n",550)
SendKey("{Numpad8}",100)
SendKey("i",100)
MouseClick,L
return

F5::Chat("-inv")
F6::Chat("-tt")

;마우스 가두기
F7::ClipWindow()

^+A::
SendAptToW3()
return

;아이템 교체
!x::
KeyWait, Alt
gosub, F5
Sleep, 200
SwapItems()
;gosub, F5
return

;Ctrl+Shift+C
^+c::ChampChat()
ChampChat() {
    Chat("!dr 10")
    Chat("-fog")
    Chat("-cdist 2300")
    Chat("-music")
    Chat("-spsi 4")
    SendAptToW3()
}

!+w::SaveW3Pos()

Insert::Gosub, ToggleMacro
#If ;워크래프트3 내에서만 작동 끝

Pause:: Gosub, ToggleRecord

#If (WinActive("ahk_class AutoHotkeyGUI"))
^s:: Gosub, SaveMacro
#If

;Alt
!e::RestoreW3Pos()
!3::SwitchToMainW3()
!2::TrySwitchW3()
!u::MoveOldSaves()
!t::LoadSquad()
!h::LoadSquad(true) ;Champion Mode

;Alt+Shift
!+n::LastSaveTimes()

;Ctrl+Shift
^+k::ExecW3()
^+w::ExecMultiW3()
^+i:: Run, notepad.exe "%configFile%"
^+o:: Run, %A_ScriptDir%
^+p:: Run, %saveDir%

;매크로 재시작
^+R::
SaveGuiSettings(false)
reload
return