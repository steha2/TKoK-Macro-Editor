
global CONFIG_FILE := A_ScriptDir . "\config.ini"

;---------------------- Macro Editor Const ------------------------------
global EPSILON_RATIO := 0.005
global EPSILON_FIXED := 3
global MACRO_DIR := A_ScriptDir . "\macro"
global DEFAULT_TARGET := "ahk_class Warcraft III" ;매크로 실행시 활성화 기본 창
global BASE_DEALY := 50
global MACRO_LIMIT := 1000

;---------------------- Macro Editor Vars ---------------------------
global g_PathMap := {} ; TreeView ID → 전체 경로 매핑
global runMacroCount := 0
global macroPath := ""
global origContent = ""
global isRecording := false
global macroGuiShown := false
global suspendTreeEvents := false
global macroAbortRequested := false
;---------------------------------------------------


;-----------------------------------------Macro Gui---------------------------------------------------
if !FileExist(MACRO_DIR)
    FileCreateDir, %MACRO_DIR%

global hMacro
Gui, macro:New, +hwndhMacro
Gui, Font, s12, Consolas


; === 버튼 속성 정의 ===
btnW := 70     ; 버튼 너비
btnH := 30     ; 버튼 높이
btnX := 10     ; 시작 X좌표
btnY := 10     ; Y좌표 고정
btnGap := 80  ; 버튼 간 간격

buttons := []  ; 빈 배열 생성
buttons.Push({text: "▶ Run",   g: "ToggleMacro",   v: "ExecBtn"})
buttons.Push({text: "Record",   g: "ToggleRecord",  v: "RecordBtn"})
buttons.Push({text: "✚ New",      g: "AddMacro",      v: "AddBtn"})
buttons.Push({text: "💾 Save",     g: "SaveMacro",     v: "SaveBtn"})
buttons.Push({text: "Rename",   g: "RenameMacro",   v: "RenameBtn"})
buttons.Push({text: "Delete",   g: "DeleteMacro",   v: "DeleteBtn"})
buttons.Push({text: "🡅 Back",     g: "BackMacro",     v: "BackBtn"})
buttons.Push({text: "Clear",    g: "ClearMacro",    v: "ClearBtn"})
buttons.Push({text: "Merge",     g: "MergeMacro",     v: "MergeBtn"})

; === 버튼 추가 루프 ===
for index, btn in buttons {
    xPos := btnX + (index - 1) * btnGap
    Gui, macro:Add, Button, % Format("g{} v{} x{} y{} w{} h{}", btn.g, btn.v, xPos, btnY, btnW, btnH), % btn.text
}

macroWinW := GetIniValue("MacroGUI","W")

Gui, Font, s14
Gui, macro:Add, TreeView, x10 y50 w270 h490 vMacroList gOnTreeViewClick


if(!macroWinW || macroWinW < 900)
    macroWinW := 900
editW := macroWinW - 300
Gui, macro:Add, Edit, x290 y50 w%editW% h410 -Wrap vEditMacro

Gui, Font, , Segoe UI

Gui, macro:Add, Edit, x290 y470 w%editW% h30 vMacroPath +ReadOnly
Gui, macro:Add, Edit, x290 y510 w240 h30 vLatestRec1 +ReadOnly
Gui, macro:Add, Edit, x540 y510 w240 h30 vLatestRec2 +ReadOnly

macroWinX := GetIniValue("MacroGUI","X","Center")
macroWinY := GetIniValue("MacroGUI","Y","Center")

if(macroWinX < 0)
    macroWinX := 0
if(macroWinY < 0)
    macroWinY := 0
Gui, macro:Show, Hide x%macroWinX% y%macroWinY% w%macroWinW% h550, Macro Editor

ToggleMacroGui(isLaunchedByMain ? GetIniValue("MacroGUI","Shown") : true)

hotkeyMacros := GetIniValue("Macro","")
Loop, Parse, hotkeyMacros, `n, `r
{
    if !InStr(A_LoopField, "=")
        continue
    parts := StrSplit(A_LoopField, "=")
    hotkey := Trim(parts[1])
    macro := Trim(parts[2])
    vars := {}
    cmd := ParseLine(macro, vars)
    fn := Func("ExecMacro").Bind(cmd, vars)
    Hotkey, %hotkey%, % fn
}

Gui, font, s8

Gui, macro:Add, Radio, x790 y510 vClientBtn Checked Group, Client
Gui, macro:Add, Radio, x790 y530 vScreenBtn, Screen

Gui, macro:Add, Radio, x850 y510 vRatioBtn Checked Group, Ratio
Gui, macro:Add, Radio, x850 y530 vFixedBtn, Fixed

ReloadTreeView(GetIniValue("MacroGUI", "MACRO_PATH"))
return

SaveMacroEditorSettings() {
    SetIniValue("MacroGUI", "MACRO_PATH", macroPath)
    SetIniValue("MacroGUI", "Shown", (macroGuiShown ? 1 : 0))
    WinGetPos, x2, y2,,, ahk_id %hMacro%
    if (x2 > 0)
        SetIniValue("MacroGUI", "X", x2)
    if (y2 > 0)
        SetIniValue("MacroGUI", "Y", y2)
}

