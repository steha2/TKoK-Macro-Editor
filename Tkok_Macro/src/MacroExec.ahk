ExecMacro(scriptText, vars) {
    if (scriptText = "")
        return
    UpdateMacroState(+1)
    lines := StrSplit(scriptText, ["`r`n", "`n", "`r"])
    limit := MACRO_LIMIT
    
    if !IsObject(vars)
        vars := {}
    ; if(!vars.HasKey("target"))
        ; vars.target := DEFAULT_TARGET
    for index, line in lines {
        line := StripComments(line)
        if (line = "")
            continue
        line := ResolveExpr(line, vars)
        
        vars.rep := 1
        vars.wait := 0
        vars.delay := isDigit(vars.base_delay) ? vars.base_delay : BASE_DELAY
        command := ParseLine(line, vars)
        if isDigit(vars.limit) {
            limit := Floor(vars.limit)
            vars.limit := ""
        }
        if (limit <= 0 || !IsAllowedWindow(vars.target))
            break
        ; 실행 성공했으면 반복 횟수 감소
        Loop, % vars.rep {
            ExecSingleCommand(command, vars)
            if(!CheckAbortAndSleep(vars.delay))
                break
            if(command != "") {
                if(A_Index = vars.rep || InStr(vars.limit_mode,"repeat"))
                    limit--
            }
        }
        if (!CheckAbortAndSleep(vars.wait))
            break
    }
    UpdateMacroState(-1)
    ;test2(command, vars, runMacroCount)
    ShowTip("--- Macro End ---`n,실행중인 매크로 수 : " runMacroCount)
}

;명령줄의 %key% 사이의 매크로내의 전역변수 vars 에 key:value로 치환한다
ResolveExpr(line, vars) {
    pos := 1
    while (found := RegExMatch(line, "i)(%([^%]+)%)", m, pos)) {
        fullMatch := m1    ; "%...%"
        expr := Trim(m2)         ; 내부 내용 예: "count|5" 또는 "count"
        defaultVal := ""
        ; 기본값 문법 처리: 변수명|기본값 분리
        if (InStr(expr, "|")) {
            parts := StrSplit(expr, "|")
            expr := Trim(parts[1])
            defaultVal := Trim(parts[2])
        }
        ; vars 객체의 키들을 치환
        isReplaced := false
        array := ToKeyLengthSortedArray(vars)
        Loop % array.Length()
        {
            item := array[A_Index]
            if(InStr(expr,item.key)) {
                expr := StrReplace(expr, item.key, item.value)
                isReplaced := true
            }
        }
        if(!isReplaced)
            expr := defaultVal

        ; 산술 계산 가능한지 검사
        result := TryEval(expr, vars)
        
        line := StrReplace(line, fullMatch, result)
        pos := found + StrLen(result) - 1
    }
    return line
}

ParseLine(line, vars) {
    ;각 명령줄마다 아래 변수들은 초기화한다 
    command := line        ; command 문자열이 될 것

    ;MsgBox, % line
    pos := 1
    while (found := RegExMatch(line, "#\s*([^#]+?)\s*#", m, pos)) {
        fullMatch := m       ; 전체: "# ... #"
        inner := Trim(m1)     ; 내부 내용

        ; key:val 또는 key: 형식 모두 지원
        if RegExMatch(inner, "^(\w+)\s*:(.*)$", cm) {
            key := cm1
            val := cm2

            if (Trim(val) = "") {
                vars.Delete(key)  ; 값이 비어 있으면 해당 변수 제거
            } else {
                array := ToKeyLengthSortedArray(vars)
                Loop % array.Length()
                {
                    item := array[A_Index]
                    val := StrReplace(val, item.key, item.value)
                }
                val := TryEval(val,vars)
                vars[key] := Trim(val)
            }
        }
        ; 원래 라인에서 제거
        command := StrReplace(command, fullMatch, "")
        pos := found + StrLen(fullMatch)
    }
    return Trim(command)
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
    } else if RegExMatch(command, "i)^(.+\.txt)$", m) {
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

ExecMacroFile(macroPath, vars := "") {
    if (!RegExMatch(macroPath, "\.txt$"))
        return

    FileRead, scriptText, %MACRO_DIR%\%macroPath%
    if (ErrorLevel) {
        MsgBox, % "파일을 불러오는 데 실패했습니다: " . macroPath
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
    if RegExMatch(expr, "^[\d+\-*/.() ]+$") && RegExMatch(expr, "\d\s*[\+\-\*/]\s*\d") {
        mode := "trim"
        if(vars.HasKey("dp_mode"))
            mode := vars.dp_mode
        ;test("EVAL!",expr,mode,FormatDecimal(Eval(expr), mode))
        return FormatDecimal(Eval(expr), mode)
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