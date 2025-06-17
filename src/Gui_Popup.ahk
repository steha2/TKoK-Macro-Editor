Note(newText := "", title := "", isAppend := false) {
    static isCreated := false
    global NoteEdit

    ; GUI 없으면 생성
    if (!isCreated) {
        Gui, SimpleNote: New
        Gui, SimpleNote: +Resize +HwndhNote  ; << 핸들 저장
        Gui, SimpleNote: Margin, 10, 10
        Gui, SimpleNote: Font, 16s, Consolas
        Gui, SimpleNote: Add, Edit, vNoteEdit x10 y40 w600 h500 WantTab
        Gui, SimpleNote: Add, Text, x10 y10 w90, Convert to
        Gui, SimpleNote: Add, Button, x100 y10 w90 h20 gOnConvertBtn, reforged
        Gui, SimpleNote: Add, Button, x200 y10 w90 h20 gOnConvertBtn, classic
        Gui, SimpleNote: Add, Button, x300 y10 w90 h20 gOnConvertBtn, custom
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
        GuiControlGet, noteContent, SimpleNote:, NoteEdit

        vars := {}
        for index, line in SplitLine(noteContent)
            ResolveMarkerMute(line, vars, "w3_ver")

        if !(vars.HasKey("w3_ver"))
            return ShowTip("noteContent에 'w3_ver' 값이 없습니다.", 1500, false)
        
        from := vars.w3_ver
        if !(uiRegions.HasKey(from))
            return ShowTip("'" from "'는 UI 영역 정의에 없습니다.", 1500, false)

        if (from = to)
            return ShowTip("w3_ver 이 같습니다.", 1500, false)

        msg := "`n#w3_ver=" from "# 을 #w3_ver=" to "# 로 바꿉니다.`n"
             . "Read: 경로 및 대상 #panel# 의 비율 좌표를 변환합니다.`n`n"
             . "Read: c_map\" from "\items`n"
             . "#panel=items# `nClick, 0.100, 0.200`nClick, 0.100, 0.200"
             
        MsgBox, 4100, Convert to %to%, %msg%
            IfMsgBox, No
                return
        
        ConvertScriptMode(noteContent, from, to)
        GuiControl, SimpleNote:, NoteEdit, % StrJoin(noteContent, "`n")
    return

    SimpleNoteGuiClose:
        Gui, SimpleNote:Destroy
        isCreated := false
        hNote := ""
    return
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

    ; 매크로 에디터와 공유된 경우 동기화
    if (macroPath = filePath) {
        MsgBox, 4100, 동기화, 매크로 에디터의 내용을 AHK Note의 내용으로 교체합니까?
            IfMsgBox, No
                return
        
        origContent := noteContent
        GuiControl, macro:, EditMacro, %noteContent%
    }
    TrueTip("Note 저장 완료:`n" . filePath)
}

ToggleOverlay() {
    Log("ToggleOverlay()")
    if (overlayVisible) {
        Gui, overlayBG:Destroy
        Gui, overlayBtn:Destroy
        overlayVisible := false
        return
    }

    ; 매크로 내용 가져오기
    vars := {}
    GuiControlGet, currentText, macro:, EditMacro
    lines := SplitLine(currentText)
    lines := PreprocessMacroLines(lines, vars)

    ; 타겟 윈도우
    PrepareTargetHwnd(vars)
    hwnd := vars.target_hwnd ? vars.target_hwnd : WinExist("A")
    WinActivateWait(hwnd)

    if(ShouldConvertCoords(vars))
        ConvertScriptMode(lines, vars.w3_ver, vars._active_w3_ver)

    ; 타겟 창 정보
    GetClientRect(hwnd, cx, cy, cw, ch)
    dpi := GetWindowDPI(hwnd)
    cw := cw/dpi*100
    ch := ch/dpi*100

    ; 1. 어두운 배경 GUI
    Gui, overlayBG:+AlwaysOnTop -Caption +ToolWindow +E0x20 +HwndhOverlayBG
    Gui, overlayBG:Color, 0x222244
    Gui, overlayBG:Show, x%cx% y%cy% w%cw% h%ch% NoActivate
    WinSet, Transparent, 150, ahk_id %hOverlayBG%

    ; 2. 버튼 전용 GUI (투명 배경)
    Gui, overlayBtn:+AlwaysOnTop -Caption +ToolWindow +HwndhOverlayBtn
    Gui, overlayBtn:Color, 0x123456
    Gui, overlayBtn:Font, s10 Bold, Segoe UI

    vars := {}
    for index, line in lines {
        line := ResolveMarkerMute(line, vars)
        if RegExMatch(line, "i)^(Click|Drag):([LR])\s*(.+)", m) && !InStr(vars.coord_mode, "screen") {

            isDrag := (StrLower(m1) = "drag")
            coordStr := Trim(m3)
            if vars.HasKey(coordStr)
                coordStr := vars[coordStr]
            if !(coords := ParseCoords(coordStr))
                return

            ; 좌표 계산
            mx := coords.x1 / dpi * 100
            my := coords.y1 / dpi * 100
            CalcCoords(mx, my, hwnd, vars.coord_mode)

            if isDrag {
                ; 드래그 박스 크기 계산
                mx2 := coords.x2 / dpi * 100
                my2 := coords.y2 / dpi * 100
                CalcCoords(mx2, my2, hwnd, vars.coord_mode)

                boxX := Min(mx, mx2)
                boxY := Min(my, my2)
                boxW := Abs(mx2 - mx)
                boxH := Abs(my2 - my)
            }
             else {
                size := 27 / dpi * 100
                boxX := mx - Floor(size / 2)
                boxY := my - Floor(size / 2)
                boxW := size
                boxH := size
            }
            Gui, overlayBtn:Add, Button, x%boxX% y%boxY% w%boxW% h%boxH% gOnOverlayBtn, %A_Index%
        }
    }
    Gui, overlayBtn:Show, x%cx% y%cy% w%cw% h%ch% NoActivate
    WinSet, TransColor, 0x123456 150, ahk_id %hOverlayBtn%

    overlayVisible := true
}

SaveOverlayRegions(w3hwnd) {
    if(!WinExist("ahk_id " . w3hwnd))
        return

    GetClientRect(w3hwnd, cx, cy, cw, ch)

    for guiID, hGui in panelGuiMap {
        WinGetPos, x, y, w, h, ahk_id %hGui%
        ; client 기준 상대 좌표 환산
        x1 := Round( (x - cx) / cw , 3 )
        y1 := Round( (y - cy) / ch , 3 )
        x2 := Round( (x + w - cx) / cw , 3 )
        y2 := Round( (y + h - cy) / ch , 3 )

        w3_ver := StrSplit(guiID, "_",,2)[1]
        panelName := StrSplit(guiID, "_",,2)[2]

        uiRegions[w3_ver][panelName] := { x1:x1, y1:y1, x2:x2, y2:y2 }
    }
    SaveJSON("res/ui_regions.json", JSON.Dump(uiRegions,,2))
    ShowTip("UI 영역 저장 완료!", 1500, false)
}

TogglePanelOverlayAll() {
    static shown := false, w3hwnd, w3_ver
    static OverlayControlGui := "OverlayCtrl"

    if (shown)
        GoTo, OverlayCtrlGuiClose

    w3hwnd := GetTargetHwnd("Warcraft III")
    w3_ver := GetW3_Ver(w3hwnd)

    if (!w3_ver)
        return Alert("Warcraft III 창이 아닙니다")

    WinActivateWait(w3hwnd)
    panelMap := uiRegions[w3_ver]

    Gui, %OverlayControlGui%:New, +AlwaysOnTop +ToolWindow
    Gui, %OverlayControlGui%:Default
    Gui, Font, s10 Bold

    Gui, Add, Text, x10 y10, 표시
    Gui, Add, Text, x110 y10, 크기조절
    Gui, Add, Text, x200 y10, Shift:*10 Ctrl:감소

    yPos := 40  ; 체크박스와 라디오 시작 Y 위치
    for panelName in panelMap {
        Gui, Add, CheckBox, Checked gOverlayCtrl_Chk x10 y%yPos%, %panelName%
        yPos += 30
    }

    idx := 1
    yPos := 40
    for panelName in panelMap {
        if (idx = 1) {
            Gui, Add, Radio, gOverlayCtrl_Select Checked Group x110 y%yPos%, %panelName%
            selectedGui := w3_ver . "_" . panelName
        } else {
            Gui, Add, Radio, gOverlayCtrl_Select x110 y%yPos%, %panelName%
        }
        guiList.Push(panelName)
        yPos += 30
        idx++
    }

    ; 방향 버튼 가로 정렬
    Gui, Add, Button, gOverlayCtrl_North x240 y40 w30 h30, ↑
    Gui, Add, Button, gOverlayCtrl_South x240 y100 w30 h30, ↓
    Gui, Add, Button, gOverlayCtrl_West  x210 y70 w30 h30, ←
    Gui, Add, Button, gOverlayCtrl_East  x270 y70 w30 h30, →

    Gui, Add, Button, gOverlayCtrl_Save x210 y150 w90 h30, UI 영역 저장

    Gui, Show, x100 y100 AutoSize, Overlay 패널 제어

    for panelName in panelMap
        ShowOrHidePanelOverlay(w3_ver, panelName, w3hwnd)

    shown := true
    return

    ; 방향 조절 핸들러
    OverlayCtrl_North: 
        AdjustOverlay("North")
    return

    OverlayCtrl_South:
        AdjustOverlay("South")
    return

    OverlayCtrl_East: 
        AdjustOverlay("East")
    return

    OverlayCtrl_West:
        AdjustOverlay("West")
    return

    ; 라디오 선택
    OverlayCtrl_Select:
        selectedGui := w3_ver . "_" . A_GuiControl
    return

    ; 체크박스 토글
    OverlayCtrl_Chk:
        GuiControlGet, btnVal, %OverlayControlGui%:, %A_GuiControl%
        ShowOrHidePanelOverlay(w3_ver, A_GuiControl, w3hwnd, btnVal)
    return

    OverlayCtrl_Save:
        SaveOverlayRegions(w3hwnd)
    return

    ; 종료
    OverlayCtrlGuiClose:
        for key, hGui in panelGuiMap {
            Gui, %key%:Destroy
        }
        Gui, %OverlayControlGui%:Destroy
        panelGuiMap := {}
        guiList := []
        shown := false
    return
}

AdjustOverlay(direction) {
    if (!panelGuiMap.HasKey(selectedGui)) {
        return Alert("선택된 패널이 없습니다.`n" . selectedGui)
    }
    hGui := panelGuiMap[selectedGui]
    shift := GetKeyState("Shift", "P")
    ctrl  := GetKeyState("Ctrl", "P")

    amount := ctrl ? (shift ? -5 : -1) : (shift ? 5 : 1)
    WinGetPos, x, y, w, h, ahk_id %hGui%

    if (direction = "North")
        y -= amount, h += amount
    else if (direction = "South")
        h += amount
    else if (direction = "East")
        w += amount
    else if (direction = "West")
        x -= amount, w += amount

    WinMove, ahk_id %hGui%, , x, y, w, h
}

ShowOrHidePanelOverlay(w3_ver, panelName, w3hwnd, show := true) {
    key := w3_ver . "_" . panelName
    if (show) {
        ; 이미 존재하면 중복 생성 방지
        if (panelGuiMap.HasKey(key))
            return

        if (!WinExist("ahk_id " . w3hwnd))
            return Alert("Warcraft III 창이 없습니다.")

        rect := uiRegions[w3_ver][panelName]
        GetClientRect(w3hwnd, cx, cy, cw, ch)
        scale := GetWindowDPI(w3hwnd) / 100

        x1 := rect.x1, y1 := rect.y1
        x2 := rect.x2, y2 := rect.y2

        guiX := Round(cx + x1 * cw)
        guiY := Round(cy + y1 * ch)
        guiW := (x2 - x1) * cw / scale
        guiH := (y2 - y1) * ch / scale

        Gui, %key%:New, +AlwaysOnTop +ToolWindow -Caption -Disabled
        Gui, Font, s12 Bold
        Gui, %key%:Color, AEFFDD
        Gui, %key%:Margin, 0, 0
        Gui, %key%:+HwndhGui
        Gui, %key%:Add, Text, , UI_%key%
        Gui, %key%:Show, x%guiX% y%guiY% w%guiW% h%guiH%
        WinSet, Transparent, 120, ahk_id %hGui%

        panelGuiMap[key] := hGui
    } else {
        ; 숨기기
        if (panelGuiMap.HasKey(key)) {
            Gui, %key%:Destroy
            panelGuiMap.Delete(key)
        }
    }
}