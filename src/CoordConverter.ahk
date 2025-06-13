
CoordTracking() {
    if (CoordTrackingRunning)
        return

    CoordTrackingRunning := true

    ; 저장 상태 검사: EditMacro 현재 내용과 origContent 비교
    GuiControlGet, currContent, macro:, EditMacro
    if (currContent != origContent) {
        GuiControl, macro:, SaveBtn, ◇ Save
    } else {
        GuiControl, macro:, SaveBtn, ◆ Save
    }

    if (GetAdjustedCoords(x, y)) {
        coordStr := x . ", " . y
        GuiControlGet, isClient, macro:, ClientBtn
        WinGetTitle, activeTitle, A
        if (isClient && activeTitle) {
            coordStr .= " / " . activeTitle
        }
        GuiControl, macro:, CoordTrack, %coordStr%
    }

    CoordTrackingRunning := false
}


CalcCoords(ByRef x, ByRef y, hwnd, coord_mode := "", coord_type := "") {
    if(!hwnd)
        return

    isClient := !InStr(coord_mode,"screen")
    isRatio := !InStr(coord_type,"fixed")

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if(isRatio) {
        GetClientSize(hwnd, w, h)
        x := Round(x * w)
        y := Round(y * h)
    }
}

GetAdjustedCoords(ByRef x, ByRef y) {
    GuiControlGet, isClient, macro:, ClientBtn
    GuiControlGet, isRatio, macro:, RatioBtn
    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if (isRatio) {
        WinGet, hwnd, ID, A
        if(!GetMouseRatio(hwnd, x, y))
            return false
    } else {
        MouseGetPos, x, y
    }
    return true
}

ParseCoords(coords) {
    coords := Trim(coords)

    if RegExMatch(coords, "(\d+),\s*(\d+)$", m) {
        return { x: m1, y: m2, type: "fixed" }
    } else if RegExMatch(coords, "(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)$", m) {
        return { x: m1, y: m2, type: "ratio" }
    } else {
        return false
    }
}

AdjustWindowToClient(win, ByRef x, ByRef y) {
    WinGet, hwnd, ID, %win%
    if (!hwnd)
        return false

    VarSetCapacity(pt, 8, 0)
    NumPut(x, pt, 0, "Int")
    NumPut(y, pt, 4, "Int")

    if !DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)
        return false

    ; 활성창의 좌상단 좌표 가져오기
    WinGetPos, wx, wy,,, ahk_id %hwnd%

    ; ControlClick 기준은 윈도우 내부 좌표 → 빼준다
    x := NumGet(pt, 0, "Int") - wx
    y := NumGet(pt, 4, "Int") - wy
    return true
}

ConvertScriptMode(scriptText, from, to) {
    out := ""
    vars := {}
    for index, line in SplitLine(scriptText) {
        ResolveMarker(line, vars, "panel")
        line := RegExReplace(line, "#\s*(w3_ver)\s*=\s*" . from . "\s*#", "#$1=" . to . "#")
        line := RegExReplace(line, "i)^(Import,\s*c_map\\)" . from . "(\\[^`\r\n]+)", "$1" . to . "$2")
        
        panel := vars.panel
        if (panel != "") && RegExMatch(line, "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)(.*)$", m) {
            btn := m1, x := m2+0, y := m3+0, tail := m4
            coords := ConvertCoords(x, y, from, to, panel)
            if(!coords && panel = "shop")
                coords := ConvertCoords(x, y, from, to, "cmd")

            if(coords) 
                line := "Click:" . btn . ", " . coords.x . ", " . coords.y . tail
        }
        out .= line . "`n"
    }
    return RTrim(out, "`n")
}

ConvertCoords(x, y, fromMode, toMode, panelName) {
    from := uiRegions[fromMode][panelName]
    to   := uiRegions[toMode][panelName]

    ; 영역 밖 검사
    if (x < from.x1 || x > from.x2 || y < from.y1 || y > from.y2)
        return false

    ; 영역 내 상대 위치 계산
    relX := (x - from.x1) / (from.x2 - from.x1)
    relY := (y - from.y1) / (from.y2 - from.y1)

    ; 대상 모드에서 실제 좌표 환산
    newX := to.x1 + relX * (to.x2 - to.x1)
    newY := to.y1 + relY * (to.y2 - to.y1)

    return { x: Round(newX, 3), y: Round(newY, 3) }
}
