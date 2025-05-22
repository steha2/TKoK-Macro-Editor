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
    GuiControlGet, curText, macro:, EditMacro
    if (Trim(curText) = "")  ; 이미 비어있으면 무시
        return

    MsgBox, 4, Clear, 내용을 모두 지웁니까?
    IfMsgBox, Yes
        GuiControl, macro:, EditMacro,  ; 빈 문자열로 설정
return

DeleteMacro:
    if (!FileExist(macroPath)) {
        MsgBox, 유효한 매크로 파일 또는 폴더를 선택하세요.
        return
    }

    SplitPath, macroPath, itemName

    isFile := IsFile(macroPath)
    title := isFile ? "파일 삭제 확인" : "폴더 삭제 확인"
    confirmMsg := isFile
        ? "정말 이 파일을 삭제하시겠습니까?"
        : "정말 이 폴더를 삭제하시겠습니까?`n(※ 비어있는 폴더만 삭제됩니다.)"

    MsgBox, 4, %itemName% - %title%, %confirmMsg%
    IfMsgBox, No
        return

    if (!DeleteItem(macroPath)) {
        failMsg := isFile
            ? "파일을 삭제할 수 없습니다.`n(사용 중이거나 권한 문제일 수 있습니다.)"
            : "폴더를 삭제할 수 없습니다.`n(※ 비어있는 폴더만 삭제 가능합니다.)"
        MsgBox, 48, 삭제 실패, %failMsg%
    } else {
        ReloadTreeView()
    }
return


RenameMacro:
    if (!macroPath || !FileExist(macroPath)) {
        MsgBox, 선택된 파일이 없습니다.
        return
    }

    SplitPath, macroPath, oldName, dir
    InputBox, newName
        , % IsFile(macroPath) ? "파일명 변경" : "폴더명 변경"
        , 새 이름을 입력하세요:`n
        , , 300, 150, , , , , %oldName%
    if (ErrorLevel || newName = "")
        return

    if (IsFile(macroPath) && !RegExMatch(newName, "i)\.txt$"))
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
    ; 파일일 경우 상위 폴더로 이동
    outputDir := macroPath
    if(isFile(macroPath))
        SplitPath, macroPath, , outputDir
    

    ; macroDir 기준 상대 경로 계산
    if (outputDir != "" && InStr(outputDir, macroDir)) {
        ; +2는 백슬래시 포함한 다음 문자부터
        macroRelPath := SubStr(outputDir, StrLen(macroDir) + 2)
        defaultInput := (macroRelPath != "") ? macroRelPath . "\" : ""
    } else {
        defaultInput := ""
    }

    InputBox, macroRelPath, 새 매크로 파일, 파일 경로\이름을 입력하세요:`n(확장자 제외), , 300, 150, , , , , %defaultInput%
    if (!ErrorLevel){
        macroRelPath := StrReplace(macroRelPath, "/", "\")  ; ✅ / → \ 변환
        WriteMacroFile("", Trim(macroRelPath))
    }
return

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
    origContent := content
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

MergeMacro:
    MsgBox, 4, Pack, 반복 명령 합치기를 실행합니까?
    IfMsgBox, No
        return
        
    GuiControlGet, content, macro:, EditMacro
    GuiControl, macro:, EditMacro, % MergeMacro(content)
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

;^u:: ; Ctrl + U
; {
;     output := "g_PathMap 구조:`n`n"
;     for id, path in g_PathMap {
;         output .= "ID: " . id . "`n경로: " . path . "`n"
;     }
;     MsgBox, %output%
;     return
; }
