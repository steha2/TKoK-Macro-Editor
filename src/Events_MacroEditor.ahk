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
   if ConfirmNotSaved()
       OnClickTreeItem()
return

OnTimeGapsCheck:
    lastTime := 0
return

BackMacro:
    GuiControlGet, content, macro:, EditMacro
    if (!content)
        return
    ; 우측 공백 및 줄바꿈 제거
    trimmed := RTrim(content,"`n`t ")
    ; 마지막 \n 위치 찾기 (없으면 -1)
    GuiControl, macro:, EditMacro, % TrimLastToken(trimmed, "`n")
    if(IsTargetWindow("Macro Editor")) {
        GuiControl, macro:Focus, EditMacro
        Send, ^{End}
    }
return  

ClearMacro:
    GuiControlGet, curText, macro:, EditMacro
    if (Trim(curText) = "")  ; 이미 비어있으면 무시
        return

    MsgBox, 4|4096, %EDITOR_TITLE%, 내용을 모두 지웁니까?
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
    if !ConfirmNotSaved()
        return
    if (!macroPath || !FileExist(macroPath)) {
        MsgBox,,%EDITOR_TITLE%, 선택된 파일이 없습니다.
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

ReloadTV:
    ReloadTreeView()
return

AddMacro:
    if !ConfirmNotSaved()
        return
    outputDir := macroPath
    if (isFile(macroPath))
        SplitPath, macroPath, , outputDir

    if (outputDir != "" && InStr(outputDir, MACRO_DIR)) {
        relPath := SubStr(outputDir, StrLen(MACRO_DIR) + 2)
        defaultInput := (relPath != "") ? relPath . "\" : ""
    } else {
        defaultInput := ""
    }

    InputBox, relPath, %EDITOR_TITLE% 
            ,새 매크로 파일`n 파일 경로\이름을 입력하세요:`n(확장자 제외)
            , , 300, 170, , , , , %defaultInput%
    if (ErrorLevel)
        return
    relPath := Trim(relPath)
    relPath := StrReplace(relPath, "/", "\")
    SplitPath, relPath, fileName, outDir

    vars := {rel_path:relPath, out_dir:outDir}
    newContents := LoadPresetForMacro(fileName, vars)

    WriteMacroFile(newContents, relPath, true)
    GuiControl, macro:Focus, EditMacro
return

SaveMacroFile(content, path) {
    isEmpty := Trim(content, "`n`t ") = ""
    isDir := IsDirectory(macroPath)

    ; 내용이 비었고 저장할 경로가 없거나 폴더일 경우 저장하지 않음
    if (isEmpty && (!macroPath || isDir))
        return

    origContent := content
    ; 내용이 있고 경로가 없거나 폴더인 경우: 새 파일 생성
    if (!isEmpty && (!macroPath || isDir)) {
        WriteMacroFile(content) ; 현재 시간으로 새 파일 저장
        return
    }

    ; 나머지 경우: 기존 파일 덮어쓰기
    FileDelete, %macroPath%
    FileAppend, %content%, %macroPath%
    ShowTip("매크로 저장 완료:`n" . macroPath)
}

SaveMacro:
GuiControlGet, content, macro:, EditMacro
SaveMacroFile(content, macroPath)
return

ToggleMacro:
    DisableShortTime("ExecBtn")
    if (runMacroCount > 0 || isRecording) {
        macroAbortRequested := true
    } else if (runMacroCount < 1) {
        SetTimer, ToggleMacroImpl, -1
    }
return

ToggleMacroImpl() {
    if(overlayVisible)
        ToggleOverlay()
    FileDelete, %logFilePath%
    GuiControlGet, content, macro:, EditMacro
    GuiControlGet, currentNum, macro:, LineEdit
    vars := {base_path:macroPath, start_line:currentNum}
    ExecMacro(content, vars, macroPath)
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
    if(runMacroCount > 0)
        return

    DisableShortTime("RecordBtn")
    isRecording := !isRecording
    btnText := isRecording ? "■ Stop" : "Record"
    lastTime := 0
    GuiControl, macro:, RecordBtn, %btnText%

    if (isRecording) {
        GuiControl, macro:+ReadOnly, EditMacro
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

ConfirmNotSaved() {
    GuiControlGet, currentText, macro:, EditMacro
    if (currentText != origContent) {
        showDiff := GetFirstDiffPreview(origContent, currentText)
        MsgBox, 4100, Not Saved, 변경 내용이 감지되었습니다:`n`n%showDiff%`n`n저장하지 않고 진행합니까?
        IfMsgBox, No
            return false

        origContent := ""
        GuiControl, macro:, EditMacro,
    }
    return true
}

GetFirstDiffPreview(orig, curr, context := 20) {
    minLen := Min(StrLen(orig), StrLen(curr))
    loop % minLen {
        i := A_Index
        if (SubStr(orig, i, 1) != SubStr(curr, i, 1)) {
            break
        }
    }

    ; 첫 번째 차이점 위치 기준으로 양쪽 일부 텍스트 미리보기
    i := i ? i : minLen + 1
    start := Max(1, i - context)
    preview1 := SubStr(orig, start, context * 2)
    preview2 := SubStr(curr, start, context * 2)

    ; 보기 쉽게 정리
    return "원본:`n" preview1 "`n`n현재:`n" preview2
}

JumpToLine(lineNum){
    GuiControlGet, content, macro:, EditMacro
    StringSplit, totalLines, content , `n
    lineNum := Min(lineNum, totalLines0) - 1
    
    GuiControl, macro:Focus, EditMacro
    
    SendKey("^{Home}")
    Loop, %lineNum%
        SendKey("{Down}")
    
    SendKey("+{End}")
}

OnNoteBtn:
    GuiControlGet, content, macro:, EditMacro
    Note(content, macroPath)
return

OnOverlayBtn:
    GuiControlGet, btnNum, overlayBtn:, %A_GuiControl%
    ToggleOverlay()
    JumpToLine(btnNum)
return

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

OnLineBtn:
    GuiControlGet, btnText, macro:, %A_GuiControl%
    GuiControlGet, currentNum, macro:, LineEdit
    d := 1
    if (GetKeyState("Shift", "P"))
        d *= 10
    else if (GetKeyState("Ctrl", "P"))
        d *= 5

    currentNum += (btnText = "▲") ? d : -d
    if (currentNum < 1)
        currentNum := 1
    GuiControl, macro:, LineEdit, %currentNum%
return

OnJumpBtn:
    GuiControlGet, line, macro:, LineEdit
    JumpToLine(line)
return


#If macroGuiShown
PrintScreen up::Gosub, ToggleMacro
ScrollLock up::Gosub, BackMacro
Pause up::Gosub, ToggleRecord

#If !isRecording && runningMacroCount <= 0
!F1::ToggleOverlay()

!F2::
    if(coords := GetAdjustedCoords()) {
        lastTime := 0
        LogToEdit("Click:L " . coords.x . ", " . coords.y)
        if(overlayVisible) {
            ToggleOverlay()
            ToggleOverlay()
        }
    }
return

!F3::Gosub, BackMacro

!Numpad9::TogglePanelOverlayAll()

#If IsTargetWindow("Macro Editor")
^S::Gosub, SaveMacro
!N::Note()

#If WinActive("ahk_id " hNote)
^S::SaveNote()
!N::Note()

#If !isLaunchedByMain
^+R::
    SaveMacroEditorSettings()
    reload
return
#If