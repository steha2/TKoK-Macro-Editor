ExecMacro(scriptText, vars, current_path) {
    if (scriptText = "")
        return
    if (runMacroCount > 10)
        return Alert("실행 중인 매크로 수가 10을 초과 합니다.")
    
    ModiKeyWait()

    UpdateMacroState(+1)
    lines := SplitLine(scriptText)
    
    if !IsObject(vars) {
        ShowTip("Warning! : vars is not an object")
        vars := {}
    }
    
    vars.current_path := current_path
    for index, line in lines {
        if(macroAbortRequested)
            break
        line := StripComments(line)
        if (line = "")
            continue

        ExtractVar(vars, "start_line", start_line, "natural")
        
        tempVars := Clone(vars)
        ResolveMarker(line, tempVars, ["if", "force", "end_if"])
        if (tempVars.HasKey("end_if")) {
            vars.Delete("if")
        } else if(tempVars.HasKey("if") && vars.if_mode = "block") {
            vars.if := tempVars.if
        }

        if((StrLower(tempVars.if) = "false"))
            tempVars.if := false

        ; 조건 확인: force가 없고, skip_mode=vars 이며, start_line 전이면 건너뛰기
        if (!tempVars.HasKey("force")) {
            if (InStr(vars.skip_mode, "vars") && index < start_line)
                continue
        
            if (tempVars.HasKey("if")){
                if(IsLogicExpr(tempVars.if)) {
                    if(!Eval(tempVars.if))
                        continue
                } else {
                    if(!TryStringLogic(tempVars.if))
                        continue
                }
            }
        }
        
        ; 단일 라인 변수 초기화
        vars.rep := 1
        vars.wait := 0
        vars.dp_mode := "trim"
        vars.delay := vars.HasKey("base_delay") ? vars.base_delay : BASE_DELAY

        ; 명령어 처리 (vars에서 실제 파싱)
        cmd := ResolveMarker(line, vars, "", ["if","force","end_if"])
        newCmd := ResolveExpr(cmd, vars)
        if (newCmd != cmd)
            cmd := ResolveMarker(newCmd, vars, "", ["if","force","end_if"])

        ; 조건 2: 실행 전 제어 흐름
        if (ShouldBreak(vars, "wait"))
            break
        
        ; 조건 3: start_line 이후만 실행 (강제 실행 아닌 경우)
        if(!tempVars.HasKey("force")) {
            if(InStr(vars.skip_mode, "vars") || !RegExMatch(cmd, "i)^Import,?\s*(.+?)$")) {
                if(index < start_line)
                    continue
            }
        }

        PrepareTargetHwnd(vars)

        Loop, % vars.rep
        {
            ExecSingleCommand(cmd, vars, line, index)
            if(cmd != "" && vars.HasKey("limit")) {
                if(index = 1 || vars.limit_mode != "line")
                    vars.limit--
            }
            if (ShouldBreak(vars, "delay"))
                break
        }
    }
    UpdateMacroState(-1)
    ; ShowTip("--- Macro End ---`n,실행중인 매크로 수 : " runMacroCount)
}

ShouldBreak(vars, timeKey) {
    if (!CheckAbortAndSleep(vars[timeKey]))
        return true

    if (vars.HasKey("limit") && !IsNatural(vars.limit))
        return true

    if (vars.HasKey("break"))
        return true

    return false
}

PrepareTargetHwnd(vars) {
    ; 타겟이 없고 hwnd 도 없으면
    if (!vars.HasKey("target") && !vars.target_hwnd) {
        return

    ; 타겟이 변경되었을 경우 새로 검색
    } else if (vars.target != vars._last_target) {
        vars._last_target := vars.target
        if (vars.target) {
            vars.target_hwnd := GetTargetHwnd(vars.target)
            return vars.target_hwnd
        } else {
            vars.target_hwnd := ""
            return
        }

    ; 타겟은 같은데 hwnd 가 없는 경우 → 재검색
    } else if (!vars.target_hwnd) {
        vars.target_hwnd := GetTargetHwnd(vars.target)
        return vars.target_hwnd

    ; 타겟 동일하고 hwnd 있음 → hwnd 유효성 검사 후 반환
    } else if (WinExist("ahk_id " . vars.target_hwnd)) {
        return vars.target_hwnd
    }

    ; hwnd 있었지만 창이 사라졌음 → 재검색 시도
    vars.target_hwnd := GetTargetHwnd(vars.target)
    return vars.target_hwnd
}

ResolveMarker(line, vars, allowedKey := "", excludedKey := "") {
    command := line
    pos := 1
    while (found := RegExMatch(line, "#([^#]+)#", m, pos)) {
        fullMatch := m
        inner := Trim(m1)

        ; Match key:val or key=val
        if RegExMatch(inner, "^\s*(\w+)\s*(([:=])\s*(.*))?$", m) {
            key := m1
            sep := m3
            rawVal := Trim(m4)

            ; If it's key:value → evaluate expression
            ; If it's key=value  → assign as literal
            val := (sep = ":") ? EvaluateExpr(rawVal, vars) : rawVal

            ; key 필터링 조건
            if ((!allowedKey || HasValue(allowedKey, key))
            && (!excludedKey || !HasValue(excludedKey, key))) {
                vars[key] := val
            }
        }

        ; Remove the #...# from command string
        command := StrReplace(command, fullMatch, "")
        pos := found + StrLen(fullMatch)
    }
    return Trim(command)
}

ResolveExpr(line, vars) {
    pos := 1
    while (found := RegExMatch(line, "%([^%]+)%", m, pos)) {
        fullMatch := m
        rawExpr := Trim(m1)
        result := EvaluateExpr(rawExpr, vars)
        line := StrReplace(line, fullMatch, result)
        pos := found + StrLen(result)
    }
    return line
}

EvaluateExpr(expr, vars) {
    ; 기본값 문법 처리
    hasDefault := false
    defaultVal := ""
    if (RegExMatch(expr, "^(.*[^|])?\|([^|].*)?$", m)) {
        expr := Trim(m1)
        defaultVal := Trim(m2)
        hasDefault := true
    }

    ; 새 방식으로 키 치환 (안전하게)
    isReplaced := false
    expr := ExplodeByKeys(expr, vars, isReplaced)

    ; 기본값에도 동일한 키 치환 적용
    defaultVal := ExplodeByKeys(defaultVal, vars, isReplacedDefault)

    ; 키 치환이 없었고, 기본값 문법이 있었다면 기본값 사용
    if (hasDefault && !isReplaced)
        expr := defaultVal

    return TryEval(expr, vars.dp_mode)
}

ExecSingleCommand(command, vars, line := "", index := "") {
    if RegExMatch(command, "i)^Click:(\w+),(.+)$", m) {
        if(vars.target && !vars.target_hwnd)
            return ShowTip("대상 창이 없습니다.`n" vars.target)

        btn := SubStr(m1,1,1), coords := Trim(m2)
        
        if(vars.HasKey(coords))
            coords := vars[coords]
        
        coords := ParseCoords(coords)
        if(coords)
            SmartClick(coords.x, coords.y, vars.target_hwnd, btn, vars.send_mode, vars.coord_mode, coords.type)
    }
    else if RegExMatch(command, "i)^(SendRaw|Send|Chat)\s*,?\s*(.*)$", m) {
        if(vars.target && !vars.target_hwnd)
            return ShowTip("대상 창이 없습니다." vars.target)

        cmdType := StrLower(m1), key := m2
        if(cmdType = "chat")
            Chat(key, vars.send_mode, vars.target_hwnd)
        else if(cmdType = "sendraw")
            SendKey(key, vars.send_mode . "R", vars.target_hwnd)
        else
            SendKey(key, vars.send_mode, vars.target_hwnd)
    }
    else if RegExMatch(command, "i)^(Sleep|Wait|Delay)\s*,?\s*(\d*)", m) {
        vars.delay := m2
    }
    else if RegExMatch(command, "^([a-zA-Z0-9_]+)\s*\((.*)\)\s*$", m) {
        WinActivateWait(vars.target_hwnd)
        ExecFunc(m1, m2)
    }
    else if RegExMatch(command, "i)^Exec,?\s*(.+?)$", m) {
        ExecMacroFile(m1, vars)
    }
    else if RegExMatch(command, "i)^Import,?\s*(.+?)$", m) {
        fullPath := ResolveMacroFilePath(m1, vars)
        if (fullPath)
            ImportVars(ReadFile(fullPath), vars)
    }
    else if RegExMatch(command, "i)^(Run|RunAs)\s*,?\s*(.*)$", m) {
        Run_(m1, m2)
    }
    else if (command && line && index) {
        ShowTip("올바른 명령문이 아님 (로그 확인 Alt+L)"
            . "`nPath: " StrReplace(vars.current_path, MACRO_DIR)
            . "`nLine: " index
            . "`nCmd : " line "`n`n", 5000, true)
    }
}

Run_(mode, path) {
    try {
        if (StrLen(mode) = 5) {
            Run *RunAs %path%
        } else {
            Run %path%
        }
    } catch e {
        MsgBox, 16, Run Failed, % "Failed to run:`n" path "`n`nError: " e.Message
    }
}


ExecFunc(fnName, argsStr) {
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

ExecMacroFile(macroFilePath, vars) {
    fullPath := ResolveMacroFilePath(macroFilePath, vars)
    if (fullPath)
        ExecMacro(ReadFile(fullPath), vars, fullPath)
}

ResolveMacroFilePath(macroFilePath, vars) {
    AppendExt(macroFilePath)
    macroFilePath := StrReplace(macroFilePath, "/", "\")

    if (IsAbsolutePath(macroFilePath))
        return macroFilePath

    try1 := GetContainingFolder(vars.current_path) . "\" . macroFilePath
    if (IsFile(try1))
        return try1

    try2 := GetContainingFolder(vars.base_path) . "\" . macroFilePath
    if (IsFile(try2))
        return try2    

    try3 := MACRO_DIR . "\" . macroFilePath
    if (IsFile(try3))
        return try3

    MsgBox, % "매크로 파일을 찾을 수 없습니다.`n" . try1 . "`n" . try2 . "`n" . try3
    return false
}

UpdateMacroState(delta) {
    runMacroCount += delta
    if (runMacroCount > 0) {
        GuiControl, macro:Text, execBtn, ■ Stop
    } else {
        GuiControl, macro:Text, execBtn, ▶ Run
        macroAbortRequested := false
    }
}

CheckAbortAndSleep(totalDelay) {
    endTime := A_TickCount + totalDelay
    while (A_TickCount < endTime) {
        if (macroAbortRequested) {
            ShowTip("매크로 중단 요청")
            return false
        }
        Sleep, % Min(100, totalDelay)
    }
    return !macroAbortRequested
}

ExplodeByKeys(expr, vars, ByRef isReplaced) {
    placeHolder := Chr(0xE000)
    result := []
    sorted := ToKeyLengthSortedArray(vars)

    ; Step 1: 키워드(길이 내림차순)를 찾아 dummy로 치환하며 값 저장
    for i, item in sorted {
        while (found := RegExMatch(expr, item.key, m)) {
            isReplaced := true
            result[found] := item.value
            expr := StrReplace(expr, m, Dummy(m, placeHolder), , 1)
        }
    }

    ; Step 2: 남은 일반 문자열 처리
    while (found := RegExMatch(expr, "[^" . placeHolder . "]+", m)) {
        result[found] := m
        expr := StrReplace(expr, m, Dummy(m, placeHolder), , 1)
    }

    return StrJoin(result,"")
}

