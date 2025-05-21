#SingleInstance
ParseCommandLine(line, vars, ByRef command, ByRef cfg) {
    cfg := {rep: 1, delay: 30} ; 기본값 설정
    cleanedLine := line        ; command 문자열이 될 것

    ;MsgBox, % line
    pos := 1
    while (found := RegExMatch(line, "i)#\s*([^#]+?)\s*#", m, pos)) {
        fullMatch := m       ; 전체: "# ... #"
        inner := Trim(m1)     ; 내부 내용

        ;MsgBox,  % "aaaa---`n"  inner "`n" fullMatch
        ; 비휘발성: g:key:value
        if RegExMatch(inner, "i)^g\s*:\s*(\w+)\s*:\s*(.+)$", gm) {
            key := gm1
            val := gm2
            vars[key] := val
        }
        ; 휘발성: key:value
        else if RegExMatch(inner, "i)^(\w+)\s*:\s*(.+)$", cm) {
            key := cm1
            val := cm2
            cfg[key] := val
        }
        ; 일치하지 않으면 무시

        ; 원래 라인에서 제거
        ;MsgBox, % cleanedLine "`n" fullMatch
        cleanedLine := StrReplace(cleanedLine, fullMatch, "")
        pos := found + StrLen(fullMatch)
    }

    command := Trim(cleanedLine)
}

vars := {aaa:33}

ParseCommandLine("Send, Hello #rep:3# #g:name/:lice# #delay:50#", vars, command, cfg)


; 결과:
MsgBox, % command "`n" cfg.rep "`n" vars.name/

;msgbox, % ResolveExpr("Send, Hello %aaa|3% %bbb|c%", vars)


ExitApp

F5::ExitApp


ResolveExpr(line, vars) {
    pos := 1
    while (found := RegExMatch(line, "i)(%([^%]+)%)", m, pos)) {
        fullMatch := m1    ; "%...%"
        expr := m2         ; 내부 내용 예: "count|5" 또는 "count"
        
        defaultVal := ""
        ; 기본값 문법 처리: 변수명|기본값 분리
        if (InStr(expr, "|")) {
            parts := StrSplit(expr, "|")
            expr := Trim(parts[1])
            defaultVal := Trim(parts[2])
        }
        ; vars 객체의 키들을 치환
        isReplaced := false
        for k, v in vars {
            if(InStr(expr,k)) {
                expr := StrReplace(expr, k, v)
                isReplaced := true
            }
        }
        ;MsgBox, % "defualt :" defaultVal "       " isReplaced

        if(!isReplaced)
            expr := defaultVal

        ; 산술 계산 가능한지 검사
        if RegExMatch(expr, "^[\d+\-*/.() ]+$") {
            result := Eval(expr)
        } else {
            result := expr
        }

        line := StrReplace(line, fullMatch, result)
        pos := found + StrLen(result) - 1
    }
    return line
}

#Include %A_scriptDir%/resources/CommonFuncs.ahk