
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

    if (coords := GetAdjustedCoords()) {
        coordStr := coords.x . ", " . coords.y
        GuiControlGet, isClient, macro:, ClientBtn
        WinGetTitle, activeTitle, A
        if (isClient && activeTitle) {
            coordStr .= " / " . activeTitle
        }
        GuiControl, macro:, CoordTrack, %coordStr%
    }

    CoordTrackingRunning := false
}


CalcCoords(ByRef x, ByRef y, hwnd, coord_mode := "") {
    if(!hwnd)
        return

    isClient := !InStr(coord_mode,"screen")
    isRatio := !InStr(coord_mode,"fixed")

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    if(isRatio) {
        GetClientSize(hwnd, w, h)
        x := Round(x * w)
        y := Round(y * h)
    }
}

GetAdjustedCoords() {
    obj := {}
    GuiControlGet, isClient, macro:, ClientBtn
    GuiControlGet, isRatio, macro:, RatioBtn
    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    obj.isClient := isClient
    obj.isRatio := isRatio

    if (isRatio) {
        WinGet, hwnd, ID, A
        obj.hwnd := hwnd
        if (!GetMouseRatio(hwnd, x, y)) {
            return false
        }
    } else {
        MouseGetPos, x, y
    }
    obj.x := x  
    obj.y := y
    return obj
}

ParseCoords2(coords) {
    coords := Trim(coords)

    if RegExMatch(coords, "(\d+)\s*,\s*(\d+)$", m) {
        return { x: m1, y: m2, type: "fixed" }
    } else if RegExMatch(coords, "(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)$", m) {
        return { x: m1, y: m2, type: "ratio" }
    } else {
        return false
    }
}

ParseCoords(coords) {
    coords := StrReplace(coords," ")
    parts := StrSplit(coords, ",")  ; 쉼표/공백/탭 구분

    if (parts.Length() = 2 || parts.Length() = 4) {
        floats := 0
        nums := []

        for i, part in parts {
            part := Trim(part)
            if (!RegExMatch(part, "^\d+(\.\d+)?$"))
                return false
            if (InStr(part, "."))
                floats++
            nums.Push(part + 0)
        }

        type := (floats > 0) ? "ratio" : "fixed"

        if (nums.Length() = 2)
            return { x1: nums[1], y1: nums[2], type: type }
        else
            return { x1: nums[1], y1: nums[2], x2: nums[3], y2: nums[4], type: type }
    }

    return false
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

ConvertScriptMode(ByRef script, from, to, startIndex := 1) {
    vars := {}

    ; 문자열인 경우 배열로 변환
    if !IsObject(script)
        script := SplitLine(script)

    Loop % script.Length()
    {
        i := A_Index
        if (i < startIndex)
            continue
        script[i] := ConvertLine(script[i], from, to, vars)
    }
    Log("ConvertScriptMode(from  " from "  to " to)
}

ConvertLine(line, from, to, vars) {
    ResolveMarkerMute(line, vars, "panel")
    line := RegExReplace(line, "#\s*(w3_ver)\s*=\s*" . from . "\s*#", "#$1=" . to . "#")
    line := RegExReplace(line, "i)^(Read:\s*c_map\\)" . from . "(\\[^`\r\n]+)", "$1" . to . "$2")
    line := ConvertClickLine(line, from, to, vars.panel)
    return line
}

ConvertClickLine(line, from, to, panel) {
    if (panel != "") && RegExMatch(line, "i)^Click:([LR])\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)(.*)$", m) {
        btn := m1, x := m2+0, y := m3+0, tail := m4
        coords := ConvertCoordsWithFallback(x, y, from, to, panel)

        if (coords)
            return "Click:" . btn . " " . coords.x . ", " . coords.y . tail
    }
    return line
}

ConvertCoords(x, y, fromMode, toMode, panelName) {
  if (!uiRegions.HasKey(fromMode) || !uiRegions[fromMode].HasKey(panelName)
   || !uiRegions.HasKey(toMode)   || !uiRegions[toMode].HasKey(panelName))
        return FalseTip("ConvertCoords Fail !HasKey from:  " fromMode " to:  " toMode "  panel: " panelName)

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

ConvertCoordsWithFallback(x, y, fromMode, toMode, panelName := "") {
    if (!panelName)
        return false  ; 명시 안된 경우 변환하지 않음

    result := ConvertCoords(x, y, fromMode, toMode, panelName)
    if (result)
        return result

    ; 특정 패널만 fallback 허용
    if (panelName = "skill" || panelName = "items" || panelName = "cp_boss") {
        ; cmd fallback
        result := ConvertCoords(x, y, fromMode, toMode, "cmd")
        if (result)
            return result
        ; map fallback
        return ConvertCoords(x, y, fromMode, toMode, "map")
    }

    ; field, cmd, map 등은 fallback 없음
    return false
}