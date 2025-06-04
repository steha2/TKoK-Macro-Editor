ExecMacro(scriptText, vars) {
    if (scriptText = "")
        return

    UpdateMacroState(+1)
    lines := StrSplit(scriptText, ["`r`n", "`n", "`r"])
    limit := BASE_LIMIT
    
    if !IsObject(vars)
        vars := {}

    for index, line in lines {
        vars.rep := 1
        vars.wait := 0
        vars.Delete("force")
        vars.Delete("dp_mode")
        vars.delay := isDigit(vars.base_delay) ? vars.base_delay : BASE_DELAY
     
        ; ----------- 임시 검사 블록 -----------
        tempVars := Clone(vars)
        ResolveMarker(line, tempVars)
        if (!tempVars.HasKey("force") && tempVars.HasKey("if") && tempVars.if = 0)
            continue
        ; -------------------------------------
      
        line := StripComments(line)
        line := ResolveMarker(line, vars)
        line := ResolveExpr(line, vars)
        
        if (line = "")
            continue
        
        if isDigit(vars.limit) {
            limit := Floor(vars.limit)
            vars.limit := ""
        }
        if (limit <= 0 || !IsAllowedWindow(vars.target) || !CheckAbortAndSleep(vars.wait))
            break
        ; 실행 성공했으면 반복 횟수 감소
        Loop, % vars.rep {
            ExecSingleCommand(line, vars)
            
            if(!CheckAbortAndSleep(vars.delay))
                break
            if(line != "") {
                if(A_Index = vars.rep || InStr(vars.limit_mode,"repeat"))
                    limit--
            }
        }
    }
    UpdateMacroState(-1)
    ; ShowTip("--- Macro End ---`n,실행중인 매크로 수 : " runMacroCount)
}

ResolveMarker(line, vars) {
    command := line
    pos := 1
    while (found := RegExMatch(line, "#([^#]+)#", m, pos)) {
        fullMatch := m
        inner := Trim(m1)
        if RegExMatch(inner, "^\s*(\w+)\s*(:(.*))?$", m) {
            key := m1
            rawVal := m3
            if (rawVal != "") {
                val := EvaluateExpr(rawVal, vars)
            }
            vars[key] := Trim(val)
        }
        command := StrReplace(command, fullMatch, "")
        pos := found + StrLen(fullMatch)
    }
    ; test2(line,command,vars)
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

    ; vars 객체의 키들을 치환
    isReplaced := false
    array := ToKeyLengthSortedArray(vars)
    Loop % array.Length() {
        item := array[A_Index]
        if (InStr(expr, item.key)) {
            expr := StrReplace(expr, item.key, item.value)
            isReplaced := true
        }
        if (InStr(defaultVal, item.key)) {
            defaultVal := StrReplace(defaultVal, item.key, item.value)
        }
    }

    ; 키 치환이 없었고, 기본값 문법이 있었다면 기본값 사용
    if (hasDefault && !isReplaced)
        expr := defaultVal

    return TryEval(expr, vars)
}


ExecSingleCommand(command, vars) {
    if RegExMatch(command, "i)^Click:(\w+),\s*(\d+),\s*(\d+)$", m) {
        Click(m2,m3,m1,"fixed")
    } else if RegExMatch(command, "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)$", m) {
        Click(m2,m3,m1)
    } else if RegExMatch(command, "i)^SendRaw\s*,?\s*(.*)$", m) {
        SendRaw, %m1% 
    } else if RegExMatch(command, "i)^Send\s*,?\s*(.*)$", m) {
        Send, {Blind}%m1% 
    } else if RegExMatch(command, "i)^Chat\s*,?\s*(.*)$", m) {
        Chat(m1)
    } else if RegExMatch(command, "i)^(Sleep|Wait)\s*,?\s*(\d*)", m) {
        if(isDigit(m2))
            vars.wait += m2
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

ExecMacroFile(macroRelPath, vars := "") {
    AppendExt(macroRelPath)
    FileRead, scriptText, %MACRO_DIR%\%macroRelPath%
    if (ErrorLevel) {
        MsgBox, % "파일을 불러오는 데 실패했습니다: " . macroRelPath
        return
    }
    ExecMacro(scriptText, vars)
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

TryEval(expr, vars) {
    if RegExMatch(expr, "^[\d+\-*/.() <>=!&|^~]+$") && RegExMatch(expr, "\d") {
        ;test("EVAL!",expr,mode,FormatDecimal(Eval(expr), mode))
        return FormatDecimal(Eval(expr), vars.dp_mode)
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
    return true
}
