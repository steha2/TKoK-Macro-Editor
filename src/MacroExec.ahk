ExecMacro(scriptText, vars, current_path) {
    if (scriptText = "")
        return
    if (runMacroCount > 10) {
        MsgBox, 실행 중인 매크로 수가 10을 초과 합니다.
        return
    }

    UpdateMacroState(+1)
    lines := StrSplit(scriptText, ["`r`n", "`n", "`r"])
    limit := BASE_LIMIT
    
    if !IsObject(vars) {
        ShowTip("Warning! : vars is not an object")
        vars := {}
    }
    vars.current_path := current_path
    for index, line in lines {
        if(macroAbortRequested)
            break

        ExtractVar(vars, "start_line", start_line, "natural")

        ; tempVars에는 조건용 if/force만 추출
        tempVars := Clone(vars)
        ResolveMarker(line, tempVars, ["if","force"])
        vars.if := tempVars.if
        
        ;test(!tempVars.HasKey("force"),InStr(vars.skip_mode, "vars") ,A_Index < start_line, tempVars.if != "" , !Eval(tempVars.if), tempVars.if)
        if (!tempVars.HasKey("force")) {
            if(InStr(vars.skip_mode, "vars") && A_Index < start_line)
                continue
            if(vars.if != "" && !Eval(tempVars.if))
                continue
        }
        line := StripComments(line)
        if (line = "")
            continue

        ; 변수 초기화
        vars.rep := 1
        vars.wait := 0
        vars.dp_mode := "trim"
        vars.delay := isDigit(vars.base_delay) ? vars.base_delay : BASE_DELAY

        ; 명령어 처리 (vars에서 실제 파싱)
        cmd := ResolveMarker(line, vars, "", ["if","force"])
        cmd := ResolveExpr(cmd, vars)
        ;test(line, vars)
        ExtractVar(vars, "limit", limit, "nat0")

        ; 조건 2: 실행 전 제어 흐름
        if (!CheckAbortAndSleep(vars.wait) || vars.HasKey("break")
           || (!PrepareTargetWindow(vars)) || limit <= 0)
            break
        
        ; 윈도우 핸들 준비
        hwnd := WinExist("A")
        if (vars.target_hwnd) {
            if (vars.send_mode != "inactive" && hwnd != vars.target_hwnd)
                WinActivateWait(vars.target_hwnd)
            hwnd := vars.target_hwnd
        }

        ; 조건 3: start_line 이후만 실행 (강제 실행 아닌 경우)
        if(!tempVars.HasKey("force") && A_Index < start_line)
            continue

        Loop, % vars.rep
        {
            ExecSingleCommand(cmd, vars, hwnd)
            if(cmd != "") {
                if(A_Index = 1 || vars.limit_mode != "line")
                    limit--
            }
            if(!CheckAbortAndSleep(vars.delay) || limit <= 0 || vars.HasKey("break"))
                break
        }
    }
    UpdateMacroState(-1)
    ; ShowTip("--- Macro End ---`n,실행중인 매크로 수 : " runMacroCount)
}

PrepareTargetWindow(vars) {
    if (vars.HasKey("target") && vars.target) {
        vars.target_hwnd := WinExist(GetTargetWin(vars.target))
        if (!vars.target_hwnd) {
            MsgBox, targetHwnd not found
            return false
        }
        vars.Delete("target")
        return true
    }
    return true  ; target 지정 안 되어 있으면 그대로 통과
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
        ; test(line, fullMatch, result, pos)
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

ExecSingleCommand(command, vars, hwnd := "") {
    if RegExMatch(command, "i)^Click:(\w+),\s*(\d+),\s*(\d+)$", m) {
        SmartClick(m2, m3, hwnd, m1, vars.send_mode, vars.coord_mode, "fixed")
    } else if RegExMatch(command, "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)$", m) {
        SmartClick(m2, m3, hwnd, m1, vars.send_mode, vars.coord_mode, "ratio")
    } else if RegExMatch(command, "i)^SendRaw\s*,?\s*(.*)$", m) {
        SendRaw, %m1% 
    } else if RegExMatch(command, "i)^Send\s*,?\s*(.*)$", m) {
        SmartSendKey(m1, hwnd, 0, vars.send_mode)
    } else if RegExMatch(command, "i)^Chat\s*,?\s*(.*)$", m) {
        Chat(m1, hwnd, vars.send_mode)
    } else if RegExMatch(command, "i)^(Sleep|Wait|Delay)\s*,?\s*(\d*)", m) {
        if(isDigit(m2))
            vars.delay := m2
    } else if RegExMatch(command, "i)^Exec,?\s*(.+?)(?:\.txt)?$", m) {
        ExecMacroFile(m1, vars)
    } else if RegExMatch(command, "i)^(Run|RunAs)\s*,?\s*(.*)$", m) {
        Run_(m1,m2)
    } else if RegExMatch(command, "^([a-zA-Z0-9_]+)\s*\((.*)\)\s*$", m) {
        ExecFunc(m1, m2)
    } else {
        if(command != "")
            ShowTip("경고, 올바른 명령문이 아님 `nCmd: "command "`nLen: " StrLen(command), 4000)
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
    AppendExt(macroFilePath)
    macroFilePath := StrReplace(macroFilePath, "/", "\")

    if (IsAbsolutePath(macroFilePath)) {
        fullPath := macroFilePath
    } else {
        try1 := GetContainingFolder(vars.current_path) . "\" . macroFilePath
        try2 := GetContainingFolder(vars.base_path) . "\" . macroFilePath
        try3 := MACRO_DIR . "\" . macroFilePath

        ;test(macroFilePath,try1,try2,try3,vars)

        if (IsFile(try1))
            fullPath := try1
        else if (IsFile(try2))
            fullPath := try2
        else if (IsFile(try3))
            fullPath := try3
        else {
            MsgBox, % "매크로 파일을 찾을 수 없습니다.`n" . try1 . "`n" . try2 . "`n" . try3
            return
        }
    }

    FileRead, scriptText, %fullPath%
    if (ErrorLevel) {
        MsgBox, % "파일을 불러오는 데 실패했습니다: " . %fullPath%
        return
    }
    ExecMacro(scriptText, vars, fullPath)
}

UpdateMacroState(delta) {
    runMacroCount += delta
    ;MsgBox, update state : %runMacroCount%  %delta%
    if (runMacroCount > 0) {
        ;GuiControl, macro:Disable, RecordBtn
        GuiControl, macro:Text, execBtn, ■ Stop
    } else {
        ;GuiControl, macro:Enable, RecordBtn
        GuiControl, macro:Text, execBtn, ▶ Run
        macroAbortRequested := false
    }
}

TryEval(expr, dp_mode) {
    if RegExMatch(expr, "^[\d+\-*/.() <>=!&|^~]+$") && RegExMatch(expr, "\d") {
        ;test("EVAL!",expr,mode,FormatDecimal(Eval(expr), mode))
        return FormatDecimal(Eval(expr), dp_mode)
    } else {
        return expr
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

Dummy(str, placeHolder) {
    dummy := ""
    Loop, % StrLen(str)
        dummy .= placeHolder
    return dummy
}

