;----------------------------------------Main Gui---------------------------------------------
global hMacro, hMain

heroSet := {}
; 클래스 자동 추출
Loop, Files, %saveDir%\*, D  ; D = 폴더만
{
    folderName := A_LoopFileName
    if RegExMatch(folderName, "^[A-Z]")  ; 대문자로 시작하는 폴더
        heroSet[folderName] := true
}

; GUI 구성
heroList := ""
for key, _ in heroSet
    heroList .= key "|"
StringTrimRight, heroList, heroList, 1

; --- GUI 구성 ---
xPos := 10
yPos := 10
colCount := 2
colWidth := 130
rowHeight := 30
index := 0

Gui, main:New, +HwndhMain
Gui, Font, s11 bold

for key, _ in heroSet {
    x := xPos + (Mod(index, colCount) * (colWidth + 10))
    y := yPos + (Floor(index / colCount) * (rowHeight + 10))
    Gui, main:Add, Button, gHeroButtonClick x%x% y%y% w%colWidth% h%rowHeight%, %key%
    index++
}

Gui, main:Add, Edit, vResultOutput x300 y10 w390 h150 ReadOnly
IniRead, savedSquad, %configFile%, Settings, savedSquad
Gui, main:Add, Text, x300 y250 w390 h20,로드 목록
Gui, main:Add, Edit, x300 y270 w390 h20 vSquadField, %savedSquad%
Gui, main:Add, Button, x300 y300 w80 h30 gAddHero, 영웅 추가
Gui, main:Add, Button, x390 y300 w30 h30 gRemoveHero, ❌
Gui, main:Add, Button, x430 y300 w80 h30 gMultiLoad, 멀티 로드
Gui, main:Add, Button, x520 y300 w80 h30 gToggleMacroGui, 매크로
Gui, main:Add, Button, x610 y300 w80 h30 gToggleSpy, MiniSpy
Gui, main:Add, Button, x300 y340 w120 h30 gExecMultiW3, 워3 다중실행
Gui, main:Add, Button, gLoadBtn vLoadButton x520 y170 w80 h30, Load
Gui, main:Add, Button, gAptBtn vAptButton x610 y170 w80 h30, Apt

IniRead, mainGuiX, %configFile%, MainGUI, X, Center
IniRead, mainGuiY, %configFile%, MainGUI, Y, Center
IniRead, min1, %configFile%, MainGUI, Minimized, 0
if(mainGuiX < 0)
    mainGuiX := "Center"
if(mainGuiY < 0)
    mainGuiY := "Center"
Gui, main:Show, x%mainGuiX% y%mainGuiY%, TKoK_Macro
if (min1)
    Gui, main:Minimize

IniRead, savedYMapped, %configFile%, Settings, yMapped
ToggleYMapping(savedYMapped ~= "i)^true|1|yes$")


;-----------------------------------------Macro Gui---------------------------------------------------


if !FileExist(macroDir)
    FileCreateDir, %macroDir%


Gui, macro:New, +hwndMacro

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

IniRead, macroWinW, %configFile%, MacroGUI, W

Gui, Font, s14
Gui, macro:Add, TreeView, x10 y50 w270 h490 vMacroList gOnTreeViewClick


if(!macroWinW || macroWinW < 730)
    macroWinW := 730
editW := macroWinW - 300
Gui, macro:Add, Edit, x290 y50 w%editW% h410 -Wrap vEditMacro

Gui, Font, , Segoe UI

Gui, macro:Add, Edit, x290 y510 w210 h30 vLastestMacro1 +ReadOnly
Gui, macro:Add, Edit, x510 y510 w210 h30 vLastestMacro2 +ReadOnly

Gui, macro:Add, Edit, x290 y470 w430 h30 vMacroPath +ReadOnly

IniRead, macroWinX, %configFile%, MacroGUI, X, Center
IniRead, macroWinY, %configFile%, MacroGUI, Y, Center

if(macroWinX < 0)
    macroWinX := 0
if(macroWinY < 0)
    macroWinY := 0
Gui, macro:Show, Hide x%macroWinX% y%macroWinY% w%macroWinW% h550, Macro Editor
IniRead, macroState, %configFile%, MacroGUI, Shown, false
if((macroState) == "true"){
    gosub, ToggleMacroGui
}

IniRead, hotkeyMacros, %configFile%, Macro
Loop, Parse, hotkeyMacros, `n, `r
{
    if !InStr(A_LoopField, "=")
        continue
    parts := StrSplit(A_LoopField, "=")
    hotkey := Trim(parts[1])
    macro := Trim(parts[2])
    fn := Func("ExecMacroFile").Bind(macro)
    Hotkey, %hotkey%, % fn
}

ReloadTreeView()