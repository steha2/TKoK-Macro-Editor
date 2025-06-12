
ToggleOverlay() {
    if (overlayVisible) {
        Gui, overlayBG:Destroy
        Gui, overlayBtn:Destroy
        overlayVisible := false
        return
    }

    ; 매크로 내용 가져오기
    vars := {}
    GuiControlGet, currentText, macro:, EditMacro
    lines := StrSplit(currentText, ["`r`n", "`n", "`r"])
    lines := PreprocessMacroLines(lines, vars)

    ; 타겟 윈도우
    PrepareTargetHwnd(vars)
    hwnd := vars.target_hwnd ? vars.target_hwnd : WinExist("A")
    
    WinActivateWait(hwnd)

    ; 타겟 창 정보
    GetClientPos(hwnd, x, y)
    GetClientSize(hwnd, w, h)
    dpi := GetWindowDPI(hwnd)
    w := w/dpi*100
    h := h/dpi*100

    ; 1. 어두운 배경 GUI
    Gui, overlayBG:+AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhOverlayBG
    Gui, overlayBG:Color, 0x222244
    Gui, overlayBG:Show, x%x% y%y% w%w% h%h% NoActivate
    WinSet, Transparent, 100, ahk_id %hOverlayBG%

    ; 2. 버튼 전용 GUI (투명 배경)
    Gui, overlayBtn:+AlwaysOnTop -Caption +ToolWindow +HwndhOverlayBtn
    Gui, overlayBtn:Color, 0x123456
    Gui, overlayBtn:Font, s10 Bold, Segoe UI

    vars := {}
    Loop, % lines.Length()
    {
        ResolveMarker(lines[A_Index], vars)
        if RegExMatch(lines[A_Index], "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)", m)
            && !InStr(vars.coordMode, "screen") 
        {
            mx := m2/dpi*100, my := m3/dpi*100
            CalcCoords(mx, my, hwnd, vars.coordMode)
            size := 27/dpi*100
            boxX := mx - Floor(size / 2)
            boxY := my - Floor(size / 2)
            Gui, overlayBtn:Add, Button, x%boxX% y%boxY% w%size% h%size% cRed gOnOverlayBtn, %A_Index%
        }
    }
    Gui, overlayBtn:Show, x%x% y%y% w%w% h%h% NoActivate
    WinSet, TransColor, 0x123456 200, ahk_id %hOverlayBtn%

    overlayVisible := true
}

Note(newText := "", title := "", isAppend := false) {
    static isCreated := false
    global NoteEdit

    ; GUI 없으면 생성
    if (!isCreated) {
        Gui, SimpleNote: New
        Gui, SimpleNote: +Resize +HwndhNote  ; << 핸들 저장
        Gui, SimpleNote: Margin, 10, 10
        Gui, SimpleNote: Font, 16s, Consolas
        Gui, SimpleNote: Add, Text, x10 y10 w80, Convet To
        Gui, SimpleNote: Add, Button, x95 y10 w80 h20 gOnConvertBtn, reforged
        Gui, SimpleNote: Add, Button, x180 y10 w80 h20 gOnConvertBtn, classic
        Gui, SimpleNote: Add, Edit, vNoteEdit x10 y40 w600 h500 WantTab
        isCreated := true
    }

    if (isAppend) {
        GuiControlGet, existingText, SimpleNote:, NoteEdit
        newText := existingText . (existingText != "" ? "`n" : "") . newText
    }
    GuiControl, SimpleNote:, NoteEdit, %newText%

    ; 창이 떠있지 않다면 띄우기
    WinGet, existingID, ID, ahk_gui SimpleNote
    if (!existingID) {
        Gui, SimpleNote: Show,, % title ? title : "AHK Note"
        GuiControl, SimpleNote:Focus, NoteEdit
    }
    return

    OnConvertBtn:
        GuiControlGet, to, SimpleNote:, %A_GuiControl%
        from := (to = "reforged") ? "classic" : "reforged"
        msg := "스크립트의 w3_ver 을 [ " from " ] 에서 [ " to " ] 로 바꿉니다.`n`n"
             . "Import 경로 및 대상 패널의 비율 좌표를 변환합니다.`n`n"
             . "#panel=shop#  or  #panel=skill#`nClick, 0.100, 0.200`nClick, 0.100, 0.200`n#panel#"
             
        MsgBox, 4100, Convert o %to%, %msg%
            IfMsgBox, No
                return

        GuiControlGet, noteContent, SimpleNote:, NoteEdit
        converted := ConvertScriptMode(noteContent, from)
        GuiControl, SimpleNote:, NoteEdit, %converted%
    return

    SimpleNoteGuiClose:
        Gui, SimpleNote:Destroy
        isCreated := false
        hNote := ""
    return
}

TogglePanelOverlayAll(ignore := "") {
    static shown := false
    if shown {
        ; 이미 띄워졌다면 닫기
        for key, hGui in panelGuiMap {
            Gui, %key%:Destroy
        }
        panelGuiMap := {}
        shown := false
        return
    }
    
    hwnd := WinExist("A")
    if (!IsTargetWindow("Warcraft III", hwnd))
        return
    
    isReforged := IsReforged(hwnd)

    ; 새로 띄우기
    GetClientPos(hwnd, clientX, clientY)
    GetClientSize(hwnd, clientW, clientH)
    scale := GetWindowDPI(hwnd) / 100

    for mode, pMap in panelMap {
        for panelName, p in pMap {
            if (isReforged && mode = "classic") 
            || (!isReforged && mode = "reforged")
            || (InStr(ignore, panelName, true))
                continue

            x1 := p.x1, y1 := p.y1
            x2 := p.x2, y2 := p.y2

            guiX := Round(clientX + x1 * clientW)
            guiY := Round(clientY + y1 * clientH)
            guiW := (x2 - x1) * clientW / scale
            guiH := (y2 - y1) * clientH / scale

            guiID := "Panel_" . mode . "_" . panelName


            Gui, %guiID%:New, +AlwaysOnTop +ToolWindow -Caption
            Gui, %guiID%:Color, AEFFDD
            Gui, %guiID%:Margin, 0, 0
            Gui, %guiID%:+HwndhGui
            Gui, %guiID%:Add, Text, , %guiID%
            Gui, %guiID%:Show, x%guiX% y%guiY% w%guiW% h%guiH%
            WinSet, Transparent, 120, ahk_id %hGui%

            panelGuiMap[guiID] := hGui
        }
    }
    shown := true
}



SaveNote() {
    GuiControlGet, noteContent, SimpleNote:, NoteEdit
    WinGetTitle, filePath, ahk_id %hNote%

    ; 파일 경로가 없거나 확장자 없으면 다이얼로그
    if (!IsFile(filePath, "txt")) {
        FileSelectFile, selectedPath, S16, , 저장할 파일을 선택하세요, 텍스트 파일 (*.txt)
        if (!selectedPath)
            return  ; 사용자가 취소함

        filePath := selectedPath
        AppendExt(filePath)
        WinSetTitle, ahk_id %hNote%, , %filePath%  ; 창 제목도 갱신
    }
    FileDelete, %filePath%
    FileAppend, %noteContent%, %filePath%
    ShowTip("Note 저장 완료:`n" . filePath)

    ; 매크로 에디터와 공유된 경우 동기화
    if (macroPath = filePath) {
        MsgBox, 4100, 동기화, 매크로 에디터의 내용을 AHK Note의 내용으로 교체합니까?
            IfMsgBox, No
                return
        
        origContent := noteContent
        GuiControl, macro:, EditMacro, %noteContent%
    }
}
