
global CONFIG_FILE := A_ScriptDir . "\config.ini"

;---------------------- Macro Editor Const ------------------------------
global EPSILON_RATIO := 0.005
global EPSILON_FIXED := 3
global EPSILON_WAIT := 200
global MACRO_DIR := A_ScriptDir . "\macro"
;global DEFAULT_TARGET := "ahk_class Warcraft III" ;매크로 실행시 활성화 기본 창
global BASE_DELAY := 30
global BASE_LIMIT := 1000
global EDITOR_TITLE := "Macro Editor"

;---------------------- Macro Editor Vars ---------------------------
global g_PathMap := {} ; TreeView ID → 전체 경로 매핑
global runMacroCount := 0
global lastTime := 0
global macroPath := ""
global origContent = ""
global isRecording := false
global macroGuiShown := false
global suspendTreeEvents := false
global macroAbortRequested := false
global CoordTrackingRunning := false
global overlayVisible := false

global hOverlayBG
global hOverlayBtn
global hMacro
global hNote

global uiRegions := {}
global panelGuiMap := {}  ; 패널별 GUI 핸들 저장
global selectedGui        ; 크기조정할 선택된패널

FileRead jsonText, %A_ScriptDir%\res\ui_regions.json
uiRegions := JSON.Load(jsonText)

; test(IsObject(uiRegions), uiRegions)
; testj(uiRegions)
;-----------------------------------------Macro Gui---------------------------------------------------
if !FileExist(MACRO_DIR)
    FileCreateDir, %MACRO_DIR%

Gui, macro:New, +hwndhMacro
Gui, Font, s12, Consolas

; === 버튼 속성 정의 ===
btnW := 67     ; 버튼 너비
btnH := 30     ; 버튼 높이
btnX := 10     ; 시작 X좌표
btnY := 10     ; Y좌표 고정
btnGap := 75  ; 버튼 간 간격

buttons := []  ; 빈 배열 생성
buttons.Push({text: "▶ Run",   g: "ToggleMacro",   v: "ExecBtn"})
buttons.Push({text: "Record",   g: "ToggleRecord",  v: "RecordBtn"})
buttons.Push({text: "✚ New",   g: "AddMacro",      v: "AddBtn"})
buttons.Push({text: "◆ Save",  g: "SaveMacro",     v: "SaveBtn"})
buttons.Push({text: "Rename",   g: "RenameMacro",   v: "RenameBtn"})
buttons.Push({text: "Delete",   g: "DeleteMacro",   v: "DeleteBtn"})
buttons.Push({text: "🡅 Back",  g: "BackMacro",     v: "BackBtn"})
buttons.Push({text: "Clear",    g: "ClearMacro",    v: "ClearBtn"})
buttons.Push({text: "Merge",    g: "MergeMacro",     v: "MergeBtn"})
buttons.Push({text: "Note",     g: "OnNoteBtn",     v: "NoteBtn"})
;buttons.Push({text: "Spy",     g: "ToggleSpy",     v: "SpyBtn"})

; === 버튼 추가 루프 ===
for index, btn in buttons {
    xPos := btnX + (index - 1) * btnGap
    Gui, macro:Add, Button, % Format("g{} v{} x{} y{} w{} h{}", btn.g, btn.v, xPos, btnY, btnW, btnH), % btn.text
}

lineNum := GetIniValue("MacroGUI", "LineNum")
Gui, macro:Add, Edit, x767 y10 w50 h30 Number Limit4 vLineEdit, % !lineNum ? 1 : lineNum
Gui, macro:Add, Button, x840 y10 w50 h30 gOnJumpBtn vJumpBtn, Jump

Gui, Font, s14
Gui, macro:Add, TreeView, x10 y50 w270 h490 vMacroList gOnTreeViewClick

macroWinW := GetIniValue("MacroGUI", "W")
if(!macroWinW || macroWinW < 900)
    macroWinW := 900
editW := macroWinW - 300

Gui, Font, % "s" . GetIniValue("Settings", "EDIT_FONT_SIZE", 14)
Gui, macro:Add, Edit, x290 y50 w%editW% h410 -Wrap vEditMacro

Gui, Font, s14, Segoe UI

Gui, macro:Add, Edit, x290 y470 w490 h30 vMacroPath +ReadOnly
Gui, macro:Add, Edit, x290 y510 w200 h30 vLatestRec +ReadOnly
Gui, macro:Add, Edit, x500 y510 w280 h30 vCoordTrack +ReadOnly

macroWinX := GetIniValue("MacroGUI","X","Center")
macroWinY := GetIniValue("MacroGUI","Y","Center")

if(macroWinX < 0)
    macroWinX := 0
if(macroWinY < 0)
    macroWinY := 0
Gui, macro:Show, Hide x%macroWinX% y%macroWinY% w%macroWinW% h550, %EDITOR_TITLE%

hotkeyMacros := GetIniValue("Macro","")
Loop, Parse, hotkeyMacros, `n, `r
{
    if !InStr(A_LoopField, "=")
        continue
    parts := StrSplit(A_LoopField, "=",, 2)
    hkey := Trim(parts[1])
    macro := Trim(parts[2])
    if(hkey, macro) {
        vars := {}
        cmd := ResolveMarker(macro, vars)
        fn := Func("ExecMacro").Bind(cmd, vars, "")
        Hotkey, %hkey%, % fn
    }
}

Gui, font, s8

isChecked := GetIniValue("MacroGUI","isTimeGaps") ? "Checked" : ""
Gui, macro:Add, Checkbox, x790 y470 vTimeGapsCheck gOnTimeGapsCheck %isChecked%, Record Time Gaps

isChecked := GetIniValue("MacroGUI","isAutoMerge") = 0 ? "" : "Checked"
Gui, macro:Add, Checkbox, x790 y488 vAutoMerge %isChecked%, Auto Merge

Gui, macro:Add, Radio, x790 y510 vClientBtn gOnCoordMode Checked Group, Client
Gui, macro:Add, Radio, x790 y530 vScreenBtn gOnCoordMode, Screen

Gui, macro:Add, Radio, x850 y510 vRatioBtn Checked Group, Ratio
Gui, macro:Add, Radio, x850 y530 vFixedBtn, Fixed
Gui, macro:Add, button, x820 y10 w18 h14 vLineUpBtn gOnLineBtn, ▲
Gui, macro:Add, button, x820 y26 w18 h14 vLineDownBtn gOnLineBtn, ▼

ReloadTreeView(GetIniValue("MacroGUI", "MACRO_PATH"))
ToggleMacroGui(isLaunchedByMain ? GetIniValue("MacroGUI","Shown") : true)
SetTimer, CoordTracking, 500
return

SaveMacroEditorSettings() {
    SetIniValue("MacroGUI", "MACRO_PATH", macroPath)
    SetIniValue("MacroGUI", "Shown", macroGuiShown)
    
    GuiControlGet, isTimeGaps, macro:, TimeGapsCheck
    SetIniValue("MacroGUI", "isTimeGaps", isTimeGaps)

    GuiControlGet, isAutoMerge, macro:, AutoMerge
    SetIniValue("MacroGUI", "isAutoMerge", isAutoMerge)

    GuiControlGet, lineNum, macro:, LineEdit
    SetIniValue("MacroGUI", "LineNum", lineNum)

    WinGetPos, x, y, w, h, ahk_id %hMacro%
    if (x > 0 && w && y > 0 && h) {
        SetIniValue("MacroGUI", "X", x)
        SetIniValue("MacroGUI", "Y", y)
    }
}