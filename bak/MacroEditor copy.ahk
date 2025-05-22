global macroDir := A_ScriptDir . "\macro"

if !FileExist(macroDir)
    FileCreateDir, %macroDir%

global isRecording := false
global runMacroCount := 0
global macroAbortRequested := false
global macroGuiShown := false

global hMacro
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
buttons.Push({text: "New",      g: "AddMacro",      v: "AddBtn"})
buttons.Push({text: "Save",     g: "SaveMacro",     v: "SaveBtn"})
buttons.Push({text: "Rename",   g: "RenameMacro",   v: "RenameBtn"})
buttons.Push({text: "Delete",   g: "DeleteMacro",   v: "DeleteBtn"})
buttons.Push({text: "Back",     g: "BackMacro",     v: "BackBtn"})
buttons.Push({text: "Clear",    g: "ClearMacro",    v: "ClearBtn"})
buttons.Push({text: "Pack",     g: "PackMacro",     v: "PackBtn"})

; === 버튼 추가 루프 ===
for index, btn in buttons {
    xPos := btnX + (index - 1) * btnGap
    Gui, macro:Add, Button, % Format("g{} v{} x{} y{} w{} h{}", btn.g, btn.v, xPos, btnY, btnW, btnH), % btn.text
}

Gui, Font, s14
Gui, macro:Add, ListBox, x10 y50 w190 h500 vMacroList gLoadMacroFiles
LoadMacroFileList()

Gui, macro:Add, Edit, x210 y50 w510 h410 vEditMacro
Gui, macro:Add, Edit, x210 y470 w250 h30 vLastestMacro1 +ReadOnly
Gui, macro:Add, Edit, x210 y510 w250 h30 vLastestMacro2 +ReadOnly

Gui, macro:Add, Edit, x470 y470 w250 h30 vMacroName +ReadOnly
Gui, macro:Add, Edit, x470 y510 w250 h30 vStatusBar +ReadOnly

IniRead, macroWinX, %configFile%, MacroGUI, X, Center
IniRead, macroWinY, %configFile%, MacroGUI, Y, Center
if(macroWinX < 0)
    macroWinX := 0
if(macroWinY < 0)
    macroWinY := 0
Gui, macro:Show, Hide x%macroWinX% y%macroWinY% w730 h550, Macro Editor
IniRead, macroState, %configFile%, MacroGUI, Shown, false
if((macroState) == "true"){
    gosub, ToggleMacroGui
}

BuildTreeView(rootPath, parentID := 0) {
    Loop, Files, % rootPath "\*", D  ; 폴더 먼저
    {
        folderName := A_LoopFileName
        fullPath := A_LoopFileFullPath
        folderID := TV_Add(folderName, parentID)
        g_PathMap[folderID] := fullPath
        BuildTreeView(fullPath, folderID)
    }
    Loop, Files, % rootPath "\*.txt"
    {
        fileName := A_LoopFileName
        fullPath := A_LoopFileFullPath
        fileID := TV_Add(fileName, parentID)
        g_PathMap[fileID] := fullPath
    }
}

OnTreeSelect:
TV_GetText(itemText, A_EventInfo)
filePath := g_PathMap[A_EventInfo]

MsgBox, % filePath
if (filePath && FileExist(filePath) && !InStr(FileExist(filePath), "D")) {
    MsgBox, 선택된 파일: %filePath%
}
return

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

LoadMacroFileList(target := "") {
    macroListArr := []  ; 배열 초기화

    Loop, Files, %macroDir%\*.txt
        macroListArr.Push(A_LoopFileName)

    if (macroListArr.MaxIndex() > 0)
        Sort, macroListArr  ; 배열 정렬 (오름차순)

    ; 리스트박스에 넣을 문자열 생성 (구분자 |)
    fileList := ""
    for index, macroName in macroListArr
        fileList .= macroName . "|"

    ; 마지막 '|' 제거
    if (StrLen(fileList) > 0)
        fileList := SubStr(fileList, 1, -1)

    GuiControl, macro:, MacroList, |  ; 리스트박스 초기화 (빈 문자열 넣기)
    GuiControl, macro:, MacroList, %fileList%

    ; 항목 선택 (확장자 없는 이름도 허용)
    if (target != "") {
        Loop, Parse, fileList, |
        {
            nameNoExt := RegExReplace(A_LoopField, "\.[^.]*$")  ; 확장자 제거
            if (A_LoopField = target || nameNoExt = target) {
                GuiControl, macro:Choose, MacroList, %A_Index%
                gosub, LoadMacroFiles
                break
            }
        }
    }
}
return

ToggleMacroGui:
macroGuiShown := !macroGuiShown
if(macroGuiShown) {
    Gui, macro:Show
} else {
    SaveGuiSettings(false)
    Gui, macro:Hide
}
return

macroGuiClose:
gosub, ToggleMacroGui
return

BackMacro:
GuiControlGet, content, macro:, EditMacro
if content =  ; 내용 없으면 종료
    return
; 우측 공백 및 줄바꿈 제거
trimmed := RTrim(content,"`n`t ")
; 마지막 \n 위치 찾기 (없으면 -1)
GuiControl, macro:, EditMacro, % TrimLastToken(trimmed, "`n")
return

ClearMacro:
MsgBox, 4, Clear, 내용을 모두 지웁니까?
IfMsgBox, Yes
GuiControl, macro:, EditMacro,  ; 빈 문자열로 설정
return

DeleteMacro:
GuiControlGet, macroName, macro:, MacroList
if (macroName = "") {
    MsgBox, 삭제할 파일을 선택하세요.
    return
}

MsgBox, 4, %macroName% 삭제 확인, 정말 삭제하시겠습니까?
IfMsgBox, No
    return

FileDelete, %macroDir%\%macroName%
LoadMacroFileList()
GuiControl, macro:, EditMacro
return

RenameMacro:
GuiControlGet, macroName, macro:, MacroList
if (macroName = "") {
    MsgBox, 이름을 바꿀 파일을 선택하세요.
    return
}

InputBox, newName, 매크로 이름 변경, 새 파일 이름을 입력하세요, , 300, 150
if (ErrorLevel || newName = "")
    return

oldPath := macroDir . "\" . macroName
newPath := macroDir . "\" . newName . ".txt"

if FileExist(newPath) {
    MsgBox, 동일한 이름의 파일이 이미 존재합니다.
    return
}

FileMove, %oldPath%, %newPath%
LoadMacroFileList(newName)
return


AddMacro:
InputBox, newName, 새 매크로 파일, 파일명을 입력하세요 (확장자 제외):
if (ErrorLevel || newName = "")
    return

filePath := macroDir . "\" . newName . ".txt"
if FileExist(filePath) {
    MsgBox, 이미 존재하는 파일입니다.
    return
}

FileAppend,, %filePath%
LoadMacroFileList(newName)
return


SaveMacro:
GuiControlGet, macroName, macro:, MacroList
GuiControlGet, content, macro:, EditMacro

if (macroName = "") {
    ; 임의의 매크로 이름 생성: Macro_날짜_시각.ahk
    FormatTime, now,, MMdd_HHmmss
    macroName := "Macro_" . now . ".txt"
}

FileDelete, %macroDir%\%macroName%
FileAppend, %content%, %macroDir%\%macroName%
LoadMacroFileList(macroName)
ShowTip("저장 완료: " . macroName)
return

; -------------------------
; 파일 선택 → 편집기로 불러오기
LoadMacroFiles:
GuiControlGet, macroName, macro:, MacroList
if (macroName != "") {
    FileRead, content, %macroDir%\%macroName%
    GuiControl, macro:, EditMacro, %content%
}
return

global isQueued := false
ToggleMacro:
GuiControl, macro:Disable, ExecBtn  ; 버튼 비활성화
SetTimer, EnableToggleButton, -500
if (runMacroCount > 0) {
    macroAbortRequested := true
} else {
    SetTimer, ToggleMacroImpl, -1
}
return

EnableToggleButton:
    GuiControl, macro:Enable, ExecBtn
return

ToggleMacroImpl() {
    if(isRecording)
        gosub, ToggleRecord
    GuiControlGet, content, macro:, EditMacro
    GuiControlGet, macroName, macro:, MacroList
    ;MsgBox, runMacron%content%
    ExecMacro(content, macroName)
}


StopMacro:
return

packMacro:
MsgBox, 4, Pack, 반복 매크로 정리를 실행합니까?
IfMsgBox, No
    return
    
GuiControlGet, content, macro:, EditMacro
GuiControl, macro:, EditMacro, % PackMacro(content)
return

; -------------------------
; 기록 시작/중지
ToggleRecord:
isRecording := !isRecording
btnText := isRecording ? "Stop" : "Record"
GuiControl, macro:, Button1, %btnText%

if (isRecording) {
    GuiControl, macro:+ReadOnly, EditMacro
    WinActivate, %w3Win%
    LastTime := A_TickCount
} else {
    GuiControl, macro:-ReadOnly, EditMacro
}
SetHotkey(isRecording)
return

LogKeyControl(key) {
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  LogToEdit("Send, {" k " Down}")
  Critical, Off
  KeyWait, %key%
  Critical
  LogToEdit("Send, {" k " Up}")
}

LogMouseClick(key) {
    global isRecording, w3Win
    if (!isRecording || !WinActive(w3Win))
        return

    GetMouseRatio(ratioX,ratioY)
    btn := SubStr(key,1,1)
    LogToEdit("Click:" . btn . ", " . ratioX . ", " . ratioY)
}

LogKey() {
    static lastKey := "", lastTime := 0
    Critical

    vksc := SubStr(A_ThisHotkey, 3)
    k := GetKeyName(vksc)
    k := StrReplace(k, "Control", "Ctrl")
    r := SubStr(k, 2)

    ; ShowTip("InputKey: "k,300)

    ; 반복 입력 제어
    if r in Alt,Ctrl,Shift,Win
        LogKeyControl(k)
    else if k in LButton,RButton,MButton
        LogMouseClick(k)
    else {
        if (k = "NumpadLeft" or k = "NumpadRight") and !GetKeyState(k, "P")
            return
        k := StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}"

        now := A_TickCount
        if (k = lastKey && (now - lastTime) < 100)
            return
       
        lastKey := k
        lastTime := now
        LogToEdit("Send, "k)
    }
}

; 🔁 핫키 등록/해제
SetHotkey(enable := false) {
    excludedKeys := "MButton,WheelDown,WheelUp,WheelLeft,WheelRight,Pause"
    mode := enable ? "On" : "Off"

    ShowTip("SetHotKey:" mode)

    Loop, 254 {
        vk := Format("vk{:X}", A_Index)
        key := GetKeyName(vk)
        if key not in ,%excludedKeys%
            Hotkey, ~*%vk%, LogKey, %mode% UseErrorLevel
    }

    ; 추가 키 (방향키 등 SC 기반)
    extraKeys := "NumpadEnter|Home|End|PgUp|PgDn|Left|Right|Up|Down|Delete"
    For i, key in StrSplit(extraKeys, "|") {
        sc := Format("sc{:03X}", GetKeySC(key))
        if key not in ,%excludedKeys%
            Hotkey, ~*%sc%, LogKey, %mode% UseErrorLevel
    }
}

LogToEdit(line) {
    GuiControlGet, current, macro:, EditMacro
    if (current != "" && SubStr(current, -1) != "`n")
        current .= "`n"  ; 마지막 줄에 줄바꿈 추가

    GuiControl, macro:, EditMacro, % current . line
    GuiControlGet, l2, macro:, LastestMacro2
    GuiControl, macro:, LastestMacro1, % l2
    GuiControl, macro:, LastestMacro2, % line
}

PackMacro(content) {
    cleanedLines := []
    lastLine := ""
    count := 0

    Loop, Parse, content, `n, `r
    {
        line := A_LoopField  ; 빈 줄도 그대로 사용 (Trim 제거)
        
        if (line = "") {
            ; 빈 줄은 바로 푸시 (연속 빈 줄도 그대로 유지)
            if (count > 0) {
                cleanedLines.Push(FormatLine(lastLine, count))
                count := 0
                lastLine := ""
            }
            cleanedLines.Push("")
            continue
        }

        line := Trim(line)  ; 빈 줄이 아닐때만 트림

        if (line = lastLine) {
            count++
        } else {
            if (lastLine != "") {
                cleanedLines.Push(FormatLine(lastLine, count))
            }
            lastLine := line
            count := 1
        }
    }

    ; 마지막 줄 처리
    if (count > 0) {
        cleanedLines.Push(FormatLine(lastLine, count))
    }

    return StrJoin(cleanedLines, "`n")
}

FormatLine(line, count) {
    if (count > 1) {
        ; 공백 포함 #rep:숫자 패턴 모두 제거
        line := RegExReplace(line, "\s*#rep:\d+")
        line .= " #rep:" . count
    }
    return line
}

ResolveExpr(str, vars) {
    pos := 1
    while (found := RegExMatch(str, "i)(%([^%]+)%)", m, pos)) {
        fullMatch := m1    ; "%...%"
        expr := m2         ; 내부 내용
        ; vars 객체의 키들을 치환
        for k, v in vars {
            expr := StrReplace(expr, k, v)
        }

        ; 산술 계산 가능한지 검사
        if RegExMatch(expr, "^[\d+\-*/.() ]+$") {
            result := Eval(expr)
        } else {
            result := expr
        }

        str := StrReplace(str, fullMatch, result)
        pos := found + StrLen(result) -1
    }
    return str
}

ParseLineWithMarkers(line, ByRef command, ByRef params) 
{
    params := {rep:1}
    command := Trim(RegExReplace(line, "(#\w+:[^\s]+)", ""),"`t ")  ; 설정 제거 (공백 유지)
    ;MsgBox, % line
    Loop, Parse, line, %A_Space%
    {
        token := A_LoopField
        if RegExMatch(token, "#(\w+):(\w+)", m)
            params[m1] := m2
            ;MsgBox, % m1 ":" m2
    }
}

ExecMacroFile(macroName, vars := "") {
    if (!RegExMatch(macroName, "\.txt$") || RegExMatch(macroName, "^#"))
        return

    FileRead, scriptText, %macroDir%\%macroName%
    if (ErrorLevel) {
        MsgBox, % "파일을 불러오는 데 실패했습니다: " . macroName
        return
    }

    ExecMacro(ResolveExpr(scriptText, vars), macroName)
}

ExecSingleCommand(baseCmd, cfg) {
    if RegExMatch(baseCmd, "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)$", m) {
        Click2(m2, m3, 10, m1)
    } else if RegExMatch(baseCmd, "i)^Send\s*,\s*(.*)$", m) {
        text := Trim(m1)
        Send, {Blind}%text% 
    } else if RegExMatch(baseCmd, "i)^Chat\s*,\s*(.*)$", m) {
        Chat(Trim(m1))
    } else if RegExMatch(baseCmd, "i)^(Sleep|Wait)\s*,?\s*(\d*)", m) {
        Sleep, %m2%
    } else if RegExMatch(baseCmd, "^(.+\.txt)$", m) {
        ExecMacroFile(m1, cfg)
    } else if RegExMatch(baseCmd, "^([a-zA-Z0-9_]+)\s*\((.*)\)\s*$", m) {
        execFunc(m1, m2)
    } else {
        MsgBox, 0, 경고, 올바른 명령문이 아님 `nCmd: %baseCmd%, 5
        return false
    }
    return true
}

ExecMacro(scriptText, macroName := "") {
    if (scriptText = "" || !ActivateWar3())
        return
    UpdateMacroState(+1)

    lines := StrSplit(scriptText, ["`r`n", "`n", "`r"])
    maxRepeat := 1000

    for index, line in lines {
        line := CleanLine(line)
        if (line = "")
            continue

        ParseLineWithMarkers(line, baseCmd, cfg)

        ; cfg.maxRepeat가 유효한 숫자면 갱신
        if (cfg.maxRepeat is digit)
            maxRepeat := cfg.maxRepeat

        if (maxRepeat <= 0)
            break

        if (!ExecSingleCommand(baseCmd, cfg))
            break

        maxRepeat-- ; 실행 성공했으면 반복 횟수 감소

        if (isDigit(cfg.delay + cfg.wait)) {
            if (!CheckAbortAndSleep(cfg.delay))
                break
        }
    }
    UpdateMacroState(-1)
    ;ShowTip("--- Macro End ---`nmacroName:" macroName "`nmacroCount: " runMacroCount)
}

CheckAbortAndSleep(totalDelay) {
    interval := 100  ; 100ms 단위로 쪼갬
    loops := Ceil(totalDelay / interval)
    global macroAbortRequested
    Loop, %loops% {
        if (macroAbortRequested) {
            ShowTip("매크로 중단 요청")
            return false  ; 중단신호
        }
        Sleep, interval
    }
    return true  ; 정상종료
}

UpdateMacroState(delta) {
    runMacroCount += delta
    ;MsgBox, update state : %runMacroCount%  %delta%
    if (runMacroCount > 0) {
        GuiControl, macro:Disable, RecordBtn
        GuiControl, macro:Text, execBtn, ■ Stop
    } else {
        GuiControl, macro:Enable, RecordBtn
        GuiControl, macro:Text, execBtn, ▶ Run
        macroAbortRequested := false
    }
    ; GuiControlGet, aaa , macro:, RecordBtn
    ; GuiControlGet, bb , Macro:, execBtn
    ; MsgBox, % aaa " "bb

}

execFunc(fnName, argsStr) {
    ; 함수 객체 가져오기
    fn := Func(fnName)
    if !IsObject(fn) {
        MsgBox, Function "%fnName%" not found.
        return
    }

    ; 인자 파싱 (쉼표로 나누고 양쪽 공백/따옴표 제거)
    args := []
    Loop, Parse, argsStr, `,
    {
        arg := Trim(A_LoopField, " `t`r`n""'")
        args.Push(arg)
    }
    return fn.Call(args*)
}

Pause:: Gosub, ToggleRecord
Insert::Gosub, ToggleMacro

#If (WinActive("ahk_class AutoHotkeyGUI"))
^s:: Gosub, SaveMacro
#If

;~ ^+r::
;~ Reload
