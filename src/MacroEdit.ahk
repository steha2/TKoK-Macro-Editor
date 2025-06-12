LogKey() {
    Critical
    vksc := SubStr(A_ThisHotkey, 3)
    k := GetKeyName(vksc)
    k := StrReplace(k, "Control", "Ctrl")
    r := SubStr(k, 2)

    if r in Alt,Ctrl,Shift,Win
        LogKeyControl(k)
    else if k in LButton,RButton,MButton
        LogMouseClick(k)
    else {
        if (k = "NumpadLeft" or k = "NumpadRight") and !GetKeyState(k, "P")
            return
        k := StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}"
        LogToEdit("Send, " . k, k)
    }
}

LogKeyControl(key) {
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  LogToEdit("Send, {" . k . " down}", k, true)
  Critical, Off
  KeyWait, %key%
  Critical
  LogToEdit("Send, {" . k . " up}" , k, true)
} 

LogMouseClick(key) {
    MouseGetPos,,, hwnd
    if (!isRecording || IsTargetWindow("Macro Editor", hwnd) || !GetAdjustedCoords(xStr, yStr))
        return
    
    btn := SubStr(key, 1, 1)
    LogToEdit("Click:" . btn . ", " . xStr . ", " . yStr, key)
}

LogToEdit(line, k := "", isModifier := false) {
    static lastKey := ""

    currTime := A_TickCount
    elapsed := currTime - lastTime
    if (k = lastKey && elapsed < 100 && !isModifier) {
        return
    } else 
        lastKey := k

    GuiControlGet, isTimeGaps, macro:, TimeGapsCheck
    if (isTimeGaps && lastTime) {
        line .= " #wait:" . Format("{:4}", elapsed) . "#"
    }
    lastTime := currTime

    GuiControlGet, scriptText, macro:, EditMacro
    GuiControlGet, isAutoMerge, macro:, AutoMerge
    
    if(isAutoMerge && !isModifier){
        trimmedScript := RTrim(scriptText, "`n`t ")
        lastLine := GetLastPart(trimmedScript, "`n")
        if(IsSameMacroLine(line, lastLine)){
            scriptText := TrimLastToken(trimmedScript, "`n")
            line := MergeLine(lastLine, 2)
        }
    }
    if (scriptText != "" && SubStr(scriptText, 0) != "`n")
        scriptText .= "`n"  ; 줄바꿈 보정
    scriptText .= line
    GuiControl, macro:, EditMacro, %scriptText%
    GuiControl, macro:, LatestRec, %line%
}

; 🔁 핫키 등록/해제
SetHotkey(enable := false) {
    excludedKeys := "MButton,WheelDown,WheelUp,WheelLeft,WheelRight,Pause,ScrollLock,PrintScreen"
    mode := enable ? "On" : "Off"

    Loop, 254 {
        vk := Format("vk{:X}", A_Index)
        key := GetKeyName(vk)
        if key not in ,%excludedKeys%
            Hotkey, ~*%vk%, LogKey, %mode% UseErrorLevel
    }

    ; 추가 키 (방향키 등 SC 기반)
    extraKeys := "NumpadEnter|Home|End|PgUp|PgDn|Left|Right|Up|Down|Delete"
    For i, key in StrSplit(extraKeys, "|") {
        sc := Format("sc{:03X}", GetKeySC(key))
        if key not in ,%excludedKeys%
            Hotkey, ~*%sc%, LogKey, %mode% UseErrorLevel
    }
}

MergeMacro(content) {
    mergedLines := []
    lastLine := ""
    count := 0

    Loop, Parse, content, `n, `r 
    {
        line := Trim(A_LoopField)
        
        if (line = "") {
            if (count > 0)
                mergedLines.Push(MergeLine(lastLine, count))
            mergedLines.Push("")
            count := 0
            lastLine := ""
            continue
        }
        if (IsSameMacroLine(line, lastLine)) {
            count++
        } else {
            if (lastLine != "")
                mergedLines.Push(MergeLine(lastLine, count))
            lastLine := line
            count := 1
        }
    }

    if (count > 0)
        mergedLines.Push(MergeLine(lastLine, count))

    return StrJoin(mergedLines, "`n")
}

MergeLine(line, count) {
    if (count > 1) {
        if (RegExMatch(line, "#rep[:=](\d+)#", m)) {
            count += m1 - 1
        }
        ; 기존 #rep:X 또는 #rep=X 제거
        line := RegExReplace(line, "\s*#rep[:=]\d+#\s*", " ")
        ; 항상 = 형식으로 붙이기
        line := RTrim(line) . " #rep=" . count . "#"
    }
    return line
}

IsSameMacroLine(line1, line2) {
    if (RegExMatch(line1, "[;%]") || RegExMatch(line2, "[;%]"))
        return false

    vars1 := {}
    vars2 := {}
    cmd1 := ResolveMarker(line1, vars1)
    cmd2 := ResolveMarker(line2, vars2)

    allowed := { "wait": 1, "delay": 1, "rep": 1 }
    for k in vars1
        if (!allowed.HasKey(k))
            return false

    for k in vars2
        if (!allowed.HasKey(k))
            return false

    wait1 := vars1.wait ? vars1.wait : 0
    wait2 := vars2.wait ? vars2.wait : 0
    delay1 := vars1.delay ? vars1.delay : 0
    delay2 := vars2.delay ? vars2.delay : 0
    if (Abs(wait1 - wait2) > EPSILON_WAIT || delay1 != delay2)
        return false

    pattern := "i)^Click:(\w),\s*([\d.]+),\s*([\d.]+)"
    if (RegExMatch(cmd1, pattern , am) && RegExMatch(cmd2, pattern , bm)) {
        ; 문자열 기반 소수점 포함 여부로 정수/실수 판별
        isFloat1 := InStr(am2, ".") || InStr(am3, ".")
        isFloat2 := InStr(bm2, ".") || InStr(bm3, ".")

        x1 := am2 + 0, y1 := am3 + 0
        x2 := bm2 + 0, y2 := bm3 + 0
        dist := Sqrt((x1 - x2)**2 + (y1 - y2)**2)

        if (am1 != bm1)
            return false
        else if (!isFloat1 && !isFloat2) ; 둘 다 정수
            return dist <= EPSILON_FIXED
        else if (isFloat1 && isFloat2)   ; 둘 다 실수
            return dist <= EPSILON_RATIO
        else
            return false ; 정수/실수 혼합 → 다르다고 판단
    } else {
        return (cmd1 = cmd2)
    }
}

WriteMacroFile(content := "", macroFilePath := "") {
    if (macroFilePath  = "") {
        FormatTime, now,, MMdd_HHmmss
        macroFilePath := "Macro_" . now
    }
    AppendExt(macroFilePath)
    ; 절대경로인지 검사 (드라이브 문자 or \로 시작)
    if (IsAbsolutePath(macroFilePath)) {
        fullPath := macroFilePath
    } else {
        fullPath := MACRO_DIR . "\" . macroFilePath
    }

    ; 이미 파일 존재하면 메시지 후 리턴
    if FileExist(fullPath) {
        MsgBox, 이미 존재하는 파일이 있습니다.`n%fullPath%
        return
    }
    ; ✅ 디렉토리 자동 생성
    SplitPath, fullPath, , outDir
    if !FileExist(outDir) {
        FileCreateDir, %outDir%
    }

    ; 파일 쓰기
    FileAppend, %content%, %fullPath%
    ShowTip("매크로 파일 생성 완료`n" fullPath)
    ReloadTreeView(fullPath)
}

PreprocessMacroLines(lines, vars, isExec := false) {
    processedLines := []
    
    if(!IsObject(lines))
        lines := [lines]
    
    for index, line in lines {
        if(SubStr(line, 1, 1) = "@")
            line := SubStr(line, 2)
        else {
            line := ResolveExpr(line, vars)
            cmd := StripComments(line)
            cmd := ResolveMarker(cmd, vars)
        }

        if (vars.HasKey("force") && isExec) {
            vars.Delete("force")
            ExecSingleCommand(cmd, vars)
        } else {
            processedLines.Push(line)
        }
    }
    return processedLines
}

LoadPresetForMacro(fileName, vars) {
    presetDir := MACRO_DIR . "\preset"
    Loop, Files, %presetDir%\*.txt
    {
        SplitPath, A_LoopFileName,,,, noExt
        if InStr(fileName, noExt) {
            FileRead, presetContent, %A_LoopFileFullPath%

            ; fileName를 - 또는 _ 기준으로 분리하여 vars에 넣기
            i := 1
            Loop, Parse, fileName, -_ 
            {
                key := "part" . i
                vars[key] := A_LoopField
                i++
            }
            
            lines := StrSplit(presetContent, ["`r`n", "`n", "`r"])
            newContents := PreprocessMacroLines(lines, vars, true)
            return RTrim(StrJoin(newContents),"`t`n ")
        }
    }
}
