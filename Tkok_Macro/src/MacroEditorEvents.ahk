macroGuiClose:
    ToggleMacroGui()
return

ToggleMacroGui(force := 2) {
    if (force = 0)
        macroGuiShown := false
    else if (force = 1)
        macroGuiShown := true
    else
        macroGuiShown := !macroGuiShown

    if (macroGuiShown) {
        Gui, macro:Show
    } else {
        SaveMacroEditorSettings()
        if (isLaunchedByMain)
            Gui, macro:Hide
        else
            ExitApp
    }
}

OnTreeViewClick:
    OnClickTreeItem()
return

OnTimeGapsCheck:
    lastTime := 0
return

BackMacro:
    GuiControlGet, content, macro:, EditMacro
    if content =  ; 내용 없으면 종료
        return
    ; 우측 공백 및 줄바꿈 제거
    trimmed := RTrim(content,"`n`t ")
    ; 마지막 \n 위치 찾기 (없으면 -1)
    GuiControl, macro:, EditMacro, % TrimLastToken(trimmed, "`n")
    GuiControl, macro:Focus, EditMacro
    Send, ^{End}
    return

ClearMacro:
    GuiControlGet, curText, macro:, EditMacro
    if (Trim(curText) = "")  ; 이미 비어있으면 무시
        return

    MsgBox, 4, %EDITOR_TITLE%, 내용을 모두 지웁니까?
    IfMsgBox, No
        return
    
    GuiControl, macro:, EditMacro,  ; 빈 문자열로 설정
    GuiControl, macro:Focus, EditMacro
return

DeleteMacro:
    if (!FileExist(macroPath)) {
        MsgBox,, %EDITOR_TITLE%, 유효한 매크로 파일 또는 폴더를 선택하세요.
        return
    }
    SplitPath, macroPath, itemName, outDir

    isFile := IsFile(macroPath)
    title := isFile ? "파일 삭제 확인" : "폴더 삭제 확인"
    confirmMsg := isFile
        ? "정말 이 파일을 삭제하시겠습니까?"
        : "정말 이 폴더를 삭제하시겠습니까?`n(※ 비어있는 폴더만 삭제됩니다.)"

    MsgBox, 4, %EDITOR_TITLE%, % itemName " - " title "`n " confirmMsg
    IfMsgBox, No
        return

    if (!DeleteItem(macroPath)) {
        failMsg := isFile
            ? "파일을 삭제할 수 없습니다.`n(사용 중이거나 권한 문제일 수 있습니다.)"
            : "폴더를 삭제할 수 없습니다.`n(※ 비어있는 폴더만 삭제 가능합니다.)"
        MsgBox, 48, %EDITOR_TITLE%, 삭제 실패`n%failMsg%
    } else {
        origContent := ""
        GuiControl, macro:, EditMacro
        ReloadTreeView(outDir)
    }
return

RenameMacro:
    if (!macroPath || !FileExist(macroPath)) {
        MsgBox,,%EDITOR_TITLE%, 삭제 선택된 파일이 없습니다.
        return
    }

    isFile := IsFile(macroPath)
    SplitPath, macroPath, rawName, dir

    ; 파일이면 확장자 제거
    if (isFile)
        oldName := RegExReplace(rawName, "i)\.txt$", "")
    else
        oldName := rawName

    msgText := (isFile ? "파일명 변경" : "폴더명 변경")
    InputBox, newName
        , %EDITOR_TITLE%
        , %msgText%`n새 이름을 입력하세요:`n
        , , 300, 150, , , , , %oldName%
    if (ErrorLevel || newName = "")
        return

    ; 파일명인 경우, 확장자가 없으면 추가
    if (isFile)
        AppendExt(newName)

    newPath := dir . "\" . newName

    if (FileExist(newPath)) {
        MsgBox,,%EDITOR_TITLE%, 동일한 이름의 파일이 이미 존재합니다.`n%newPath%
        return
    }

    if (isFile)
        FileMove, %macroPath%, %newPath%
    else
        FileMoveDir, %macroPath%, %newPath%

    ReloadTreeView(newPath)
    ShowTip("이름 변경 완료: " . newName)
    GuiControl, macro:Focus, EditMacro
return


AddMacro:
    outputDir := macroPath
    if (isFile(macroPath))
        SplitPath, macroPath, , outputDir

    if (outputDir != "" && InStr(outputDir, MACRO_DIR)) {
        macroRelPath := SubStr(outputDir, StrLen(MACRO_DIR) + 2)
        defaultInput := (macroRelPath != "") ? macroRelPath . "\" : ""
    } else {
        defaultInput := ""
    }

    InputBox, macroRelPath, %EDITOR_TITLE% 
            ,새 매크로 파일`n 파일 경로\이름을 입력하세요:`n(확장자 제외)
            , , 300, 170, , , , , %defaultInput%
    if (ErrorLevel)
        return
    macroRelPath := Trim(macroRelPath)
    macroRelPath := StrReplace(macroRelPath, "/", "\")
    SplitPath, macroRelPath, fileName, outDir

    vars := {rel_path:acroRelPath, out_dir:outDir}
    newContents := LoadPresetForMacro(fileName, vars)

    WriteMacroFile(newContents, macroRelPath)
    GuiControl, macro:Focus, EditMacro
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
    DisableShortTime("ExecBtn")
    if (runMacroCount > 0) {
        macroAbortRequested := true
    } else if (runMacroCount < 1) {
        SetTimer, ToggleMacroImpl, -1
    }
return

ToggleMacroImpl() {
    GuiControlGet, content, macro:, EditMacro
    ExecMacro(content, "")
}


MergeMacro:
    GuiControlGet, content, macro:, EditMacro
    if(Trim(content) = "")
        return
    MsgBox,4,%EDITOR_TITLE%,반복 명령 병합를 실행합니까?`n오차범위 wait:%EPSILON_WAIT%, %EPSILON_RATIO%, %EPSILON_FIXED%px 이내라면 합쳐집니다.
    IfMsgBox, No
        return
    GuiControl, macro:, EditMacro, % MergeMacro(content)
    GuiControl, macro:Focus, EditMacro
return

ToggleSpy:
if (WinExist("ahk_id " . miniSpyHwnd))
{
    WinClose, ahk_id %miniSpyHwnd%
    miniSpyHwnd := ""
}
else
{
    Run, *RunAs "%A_ScriptDir%\src\MiniSpy.ahk", , , pid
    WinWait, ahk_pid %pid%, , 2
    if ErrorLevel {
        MsgBox, MiniSpy 실행 실패
        return
    }
    miniSpyHwnd := WinExist("ahk_pid " . pid)
}
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
        WinActivate, %DEFAULT_TARGET%
    } else {
        GuiControl, macro:-ReadOnly, EditMacro
    }
    SetHotkey(isRecording)
return

DisableShortTime(ctrlName, delay := 500, guiName := "macro") {
    GuiControl, %guiName%:Disable, %ctrlName%
    fn := Func("EnableGuiControl").Bind(ctrlName, guiName)
    SetTimer, % fn, -%delay%
}

EnableGuiControl(ctrlName, guiName := "macro") {
    GuiControl, %guiName%:Enable, %ctrlName%
}

OnCoordMode:
    GuiControlGet, isClient, macro:, ClientBtn
    if (isClient) {
        GuiControl, macro:Enable, RatioBtn
        GuiControl, macro:, RatioBtn, 1
    } else {
        GuiControl, macro:Disable, RatioBtn
        GuiControl, macro:, FixedBtn, 1  ; Fixed 선택
    }
return

Insert up::Gosub, ToggleMacro
Pause up::Gosub, ToggleRecord

!F1::ToggleOverlay()

#If !isRecording && runningMacroCount <= 0
!F2::
    MouseGetPos,,, hwnd
    if(GetAdjustedCoords(xStr,yStr))
        LogToEdit("Click:L, " . xStr . ", " . yStr)
return

#If IsTargetWindow("Macro Editor")
^S:: Gosub, SaveMacro

#If !isLaunchedByMain
^+R::
    SaveMacroEditorSettings()
    reload
return
#IF

;^u:: ; Ctrl + U
; {
;     output := "g_PathMap 구조:`n`n"
;     for id, path in g_PathMap {
;         output .= "ID: " . id . "`n경로: " . path . "`n"
;     }
;     MsgBox, %output%
;     return
; }

