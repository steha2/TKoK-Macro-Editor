global CONFIG_FILE := A_ScriptDir . "\config.ini"

;-----------------------Code Loader Const------------------------------
global CLIENT_TITLE := "W3_Client_"
global W3_WINTITLE := "Warcraft III"
global W3_LNK := GetIniValue("Settings", "W3_LNK")
global W3_LAUNCH_DELAY := 1300 ; 워크 실행후 검은 화면이 끝나고 UI 로딩까지 대기할 시간
global SAVE_DIR := GetIniValue("Settings", "SAVE_DIR", A_ScriptDir)
global NEW_HERO_DELAY := 800 ; 새 영웅 선택시 화살표 누를때 딜레이
global heroArr := ["Arcanist","Warrior","Cleric","Pyromancer","Hydromancer","Chronowarper","Phantom Stalker","Chaotic Knight","Shadowblade","Ranger","Barbarian","Paladin","Druid","Medicaster","Venomancer","Aeromancer","Earthquaker","Shadow Shaman"]

;-----------------------Code Loader Vars------------------------------
global c_map := {}
global pl1 := ""
global pl2 := ""
global la := ""
global yMapped := false
global whenSwitchMinimize := GetIniValue("Settings", "whenSwitchMinimize", 1)
;global switchRunning := 0
;----------------------------------------Main Gui---------------------------------------------
global hMain

heroSet := {}
; 클래스 자동 추출
Loop, Files, %SAVE_DIR%\*, D  ; D = 폴더만
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

Gui, main:Add, Edit, vResultOutput x300 y10 w380 h150 ReadOnly
Gui, main:Add, Button, gLoadBtn vLoadButton x300 y170 w100 h30, Load Hero
Gui, main:Add, Button, gAptBtn vAptButton x410 y170 w100 h30, APT
Gui, main:Add, Text, x520 y170 w100 h30 vAptText, APT:`nDEDI:

Gui, main:Add, Text, x300 y250 w380 h20, Load Hero List:
Gui, main:Add, Edit, x300 y270 w380 h20 vSquadField, % GetIniValue("Settings", "savedSquad")
Gui, main:Add, Button, x300 y300 w120 h30 gAddHero, Add to List
Gui, main:Add, Button, x430 y300 w30 h30 gRemoveHero, ❌

Gui, main:Add, Button, x300 y340 w120 h30 gExecMultiW3, W3 Multi-Run
Gui, main:Add, Button, x430 y340 w120 h30 gMultiLoad, Multi-Load
Gui, main:Add, Button, x560 y340 w120 h30 gToggleMacroGui, Macro Editor

mainGuiX := GetIniValue("MainGUI", "X", "Center")
mainGuiY := GetIniValue("MainGUI", "Y", "Center")

if(mainGuiX < 0)
    mainGuiX := "Center"
if(mainGuiY < 0)
    mainGuiY := "Center"
Gui, main:Show, x%mainGuiX% y%mainGuiY%, TKoK_Code_Loader
if (GetIniValue("MainGUI", "Minimized", 0))
    Gui, main:Minimize

yMapped := GetIniValue("Settings","yMapped")

c_map["classic"] := LoadMacroContext("classic")
c_map["reforged"] := LoadMacroContext("reforged")

LoadMacroContext(path := "") {
    ctx := {}
    dir := A_ScriptDir . "\macro\c_map\" . path
    Loop, %dir%\*.txt 
        ImportVars(ReadFile(A_LoopFileFullPath), ctx)
    
    return ctx
}

; GUI 위치 저장
SaveCodeLoaderSettings() {
    ; 메인 GUI
    WinGet, min1, MinMax, ahk_id %hMain%
    SetIniValue("MainGUI", "Minimized", (min1 == -1))

    if (min1)
        WinRestore, ahk_id %hMain%

    WinGetPos, x1, y1,,, ahk_id %hMain%
    SetIniValue("MainGUI", "X", x1)
    SetIniValue("MainGUI", "Y", y1)
    SetIniValue("Settings", "yMapped", yMapped)
}