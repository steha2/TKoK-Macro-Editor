ToggleMacroGui:
macroGuiShown := !macroGuiShown
;ShowTip("macro gui : " macroGuiShown)
if(macroGuiShown) {
    Gui, macro:Show
} else {
    SaveGuiSettings(false)
    Gui, macro:Hide
}
return

OnTreeViewClick:
OnClickTreeItem()
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
if (!IsFile(macroPath)) {
    MsgBox, 유효한 매크로 파일을 선택하세요.
    return
}

SplitPath, macroPath, itemName

MsgBox, 4, %itemName% 삭제 확인, 정말 삭제하시겠습니까?
IfMsgBox, No
    return

FileDelete, %macroPath%
if FileExist(macroPath) {
    MsgBox, 파일을 삭제할 수 없습니다.
}
ReloadTreeView()
return


RenameMacro:
if (!FileExist(macroPath) || InStr(FileExist(macroPath), "D")) {
    MsgBox, 이름을 바꿀 **파일**을 선택하세요.
    return
}

SplitPath, macroPath, oldName, dir  ; oldName = 파일명, dir = 폴더경로

InputBox, newName, 매크로 이름 변경, 새 파일 이름을 입력하세요:`n(확장자 제외), , 300, 150, , , , , %oldName%
if (ErrorLevel || newName = "")
    return

if !(InStr(newName, ".txt"))  ; 확장자 없으면 자동 추가
    newName .= ".txt"

newPath := dir . "\" . newName

if (FileExist(newPath)) {
    MsgBox, 동일한 이름의 파일이 이미 존재합니다.`n%newPath%
    return
}

FileMove, %macroPath%, %newPath%
ReloadTreeView(newPath)
ShowTip("이름 변경 완료: " . newName)
return

AddMacro:
; 상위 폴더로 이동
SplitPath, macroPath, , outputDir
    
; macroDir 기준 상대 경로 계산
if (outputDir != "" && InStr(outputDir, macroDir)) {
    ; +2는 백슬래시 포함한 다음 문자부터
    macroRelPath := SubStr(outputDir, StrLen(macroDir) + 2)
    defaultInput := (macroRelPath != "") ? macroRelPath . "\" : ""
} else {
    defaultInput := ""
}

InputBox, macroRelPath, 새 매크로 파일, 파일 경로+이름을 입력하세요:`n(확장자 제외), , 300, 150, , , , , %defaultInput%
if (!ErrorLevel)
    WriteMacroFile("", Trim(macroRelPath))
return

WriteMacroFile(content := "", macroRelPath := "") {
    if (macroRelPath  = "") {
        FormatTime, now,, MMdd_HHmmss
        macroRelPath := "Macro_" . now . ".txt"
    }

    ; .txt 확장자 붙이기 (없으면)
    if (!RegExMatch(macroRelPath, "\.txt$", "i")) 
        macroRelPath .= ".txt"

    ; 절대경로인지 검사 (드라이브 문자 or \로 시작)
    if (SubStr(macroRelPath, 1, 1) = "\" || RegExMatch(macroRelPath, "^[a-zA-Z]:\\")) {
        fullPath := macroRelPath
    } else {
        fullPath := macroDir . "\" . macroRelPath
    }

    ; 이미 파일 존재하면 메시지 후 리턴
    if FileExist(fullPath) {
        MsgBox, 이미 존재하는 파일이 있습니다.`n%fullPath%
        return
    }

    ; 파일 쓰기
    FileAppend, %content%, %fullPath%
    ShowTip("매크로 파일 생성 완료`n" fullPath)

    ; 트리뷰 갱신 (함수에 맞게 인자 조정 필요할 수 있음)
    ReloadTreeView(fullPath)
}

SaveMacro:
GuiControlGet, content, macro:, EditMacro

; 내용을 모두 지운채로도 저장가능
if (Trim(content, "`n`t ") = "" && macroPath = "")
    return

if (macroPath = "") {
; 선택된 매크로가 없으면 새 파일 생성
    WriteMacroFile(content)
    return
}

; 선택된 경로가 있으면 기존 파일 덮어쓰기
FileDelete, %macroPath%
FileAppend, %content%, %macroPath%
ShowTip("저장 완료: " . macroPath)
return

ToggleMacro:
;ShowTip("runcount:       "  runMacroCount)
DisableShortTime("ExecBtn")
if (runMacroCount > 0) {
    macroAbortRequested := true
    runMacroCount = 0
} else if (runMacroCount < 1) {
    runMacroCount = 0
    SetTimer, ToggleMacroImpl, -1
}
return

DisableShortTime(ctrlName, delay := 500, guiName := "macro") {
    GuiControl, %guiName%:Disable, %ctrlName%
    fn := Func("EnableGuiControl").Bind(ctrlName, guiName)
    SetTimer, % fn, -%delay%
}

EnableGuiControl(ctrlName, guiName := "macro") {
    GuiControl, %guiName%:Enable, %ctrlName%
}

ToggleMacroImpl() {
    GuiControlGet, content, macro:, EditMacro
    GuiControlGet, macroName, macro:, MacroList
    ;MsgBox, runMacron%content%
    ExecMacro(content, macroName)
}

packMacro:
MsgBox, 4, Pack, 반복 명령 합치기를 실행합니까?
IfMsgBox, No
    return
    
GuiControlGet, content, macro:, EditMacro
GuiControl, macro:, EditMacro, % PackMacro(content)
return

; -------------------------
; 기록 시작/중지
ToggleRecord:

DisableShortTime("RecordBtn")
isRecording := !isRecording
btnText := isRecording ? "■ Stop" : "Record"
GuiControl, macro:, RecordBtn, %btnText%

if (isRecording) {
    GuiControl, macro:+ReadOnly, EditMacro
    WinActivate, %w3Win%
    LastTime := A_TickCount
} else {
    GuiControl, macro:-ReadOnly, EditMacro
}
SetHotkey(isRecording)
return



;~ ^+r::
;~ Reload

;^u:: ; Ctrl + U
; {
;     output := "g_PathMap 구조:`n`n"
;     for id, path in g_PathMap {
;         output .= "ID: " . id . "`n경로: " . path . "`n"
;     }
;     MsgBox, %output%
;     return
; }
