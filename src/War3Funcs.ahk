SaveW3Pos() {
    WinGetTitle, winTitle, A
    WinGetPos, x, y, w, h, A
    
    MsgBox, 4, 창 위치를 저장합니까?, SaveW3Position`n예/아니오를 선택해 주세요.
    IfMsgBox, No
        return
    
    if (winTitle = W3_WINTITLE) {
        SetIniValue("W3Window","X",x)
        SetIniValue("W3Window","Y",y)
        SetIniValue("W3Window","W",w)
        SetIniValue("W3Window","H",h)
        ShowTip("저장 완료 : X: " x " Y:" y " W:" w " H:" h)
    }
    else
        MsgBox, 활성 창 정보를 불러올 수 없습니다.
    return
}

RestoreW3Pos(hwnd := "") {
    savedX := GetIniValue("W3Window","X")
    savedY := GetIniValue("W3Window","Y")
    savedW := GetIniValue("W3Window","W")
    savedH := GetIniValue("W3Window","H")
    if(hwnd)
        activeHwnd := hwnd
    else
        activeHwnd := WinActive("A")
    if (activeHwnd) {
        WinMove, ahk_id %activeHwnd%, , %savedX%, %savedY%, %savedW%, %savedH%
        ;ShowTip("현재 창을 mainW3Hwnd : " mainW3Hwnd "`nX:" savedX " Y:" savedY " W:" savedW " H:" savedH)
    }
}

ActivateBottomW3() {
    WinActivateBottom, % "ahk_id " . GetTargetHwnd("Warcraft III")
}

SwitchNextW3(isClip := true, minimizePrev := false) {
    currHwnd := WinActive("A")
    currIndex := GetClientIndex(currHwnd)  ; 현재 창이 CLIENT_TITLE_N인 경우 N을 반환

    if (currIndex) {
        clients := GetClientHwndArray()
        maxIndex := clients.Length()
        nextIndex := ""
        Loop, %maxIndex% {
            i := Mod(currIndex + A_Index - 1, maxIndex) + 1
            if (clients.HasKey(i) && clients[i]) {
                nextIndex := i
                break
            }
        }
        if (nextIndex != "")
            SwitchW3(nextIndex, isClip, minimizePrev)
    } else {
        ActivateBottomW3()
    }
    ; 타이머 관리
    switchRunning--
    if (switchRunning < 0)
        switchRunning := 0
}

SwitchW3(clientNum := 1, isClip := false, minimizePrev := false, cursorToCenter := false) {
    currHwnd := WinActive("A")
    nextHwnd := WinExist(CLIENT_TITLE . clientNum)
    if(currHwnd = nexthwnd) {
        ; 같은 창 호출시 창 전환 안하고 토글 마우스 가두기
        if (isClip)
            ToggleClipMouse(nextHwnd) 
    } else if (nextHwnd) { ; 전환 할 창이 있는 경우
        WinActivate, ahk_id %nextHwnd%
        if (minimizePrev && currHwnd && WinExist("ahk_id " currHwnd) && IsW3(currHwnd))
            WinMinimize, ahk_id %currHwnd%
        if (isClip)
            ClipMouse(nextHwnd)
    } else if (IsW3(currHwnd) && !GetClientIndex(currHwnd)) { ; 창 제목이 Warcraft III 기본 인경우
        WinSetTitle, ahk_id %currHwnd%,,% CLIENT_TITLE . clientNum
    } else {
        ActivateBottomW3()
    }
    
    if(cursorToCenter) {
        MouseMove(0.5, 0.5)
    }
}


IsW3(hwnd := "") {
    hwnd := hwnd ? hwnd : WinActive("A")
    return IsTargetWindow("Warcraft III", hwnd)
}

IsReforged(target) {
    hwnd := GetTargetHwnd(target)
    
    if (!hwnd)
        return false

    WinGetClass, winClass, ahk_id %hwnd%
    WinGet, exe, ProcessName, ahk_id %hwnd%

    return (winClass = "OsWindow") && (exe = "Warcraft III.exe")
}

GetW3_Ver(target) {
    hwnd := GetTargetHwnd(target)
    if (!IsW3(hwnd))
        return ""  ; 찾기 실패

    if(!IsReforged(hwnd))
        return "classic"

    GetClientSize(hwnd, cw, ch)

    ; 16:9 비율 체크 (0.5625 ± 0.02 허용 오차)
    ratio := ch / cw
    tolerance := 0.02
    is16by9 := (ratio > 0.5625 - tolerance) && (ratio < 0.5625 + tolerance)

    if (is16by9)
        return "reforged"
    else
        return "custom"
}

ShareUnit(hwnd := "") {
    if(hwnd) {
        SendKey("{F11}", "C", hwnd, 300)
        ClickBack(0.599,0.204, hwnd)
        SendKey("{Enter}", "C", hwnd)
    } else {
        SendA("{F11}", 350)
        ClickA(0.599,0.204)
        SendA("{Enter}")
    }
}

ExecW3(roleTitle := "", mini := false) {
    if (W3_LNK = "" || !FileExist(W3_LNK))
        return ShowTip("실행할 W3_LNK 경로를 찾지 못했습니다.`nconfig.ini 에서 경로를 수정하세요.")
    
    origHwnd := WinActive("A")
    ;실행 후 hwnd 을 찾을대까지 기다림
    hwnd := RunGetHwnd(W3_LNK, "Warcraft III")
    if (!hwnd)
        return Alert("Warcraft III 창을 찾을 수 없습니다.")
    WinSet, AlwaysOnTop, On, ahk_id %hwnd%
    success := WaitUntilNotWhiteOrBlack(hwnd, 5000)
    WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
    if(origHwnd)
        WinActivate, ahk_id %origHwnd%
    if (success) {
        if (roleTitle)
            WinSetTitle, ahk_id %hwnd%, , %roleTitle%
        if (mini)
            WinMinimize, ahk_id %hwnd%
        
        Sleep(W3_LAUNCH_DELAY)
        return hwnd
    } else {
        return Alert("UI 로딩 감지 실패 (흰/검 배경에서 벗어나지 않음")
    }
}

ExecMultiW3(num := 0, speed := 0, skipIfRunning := true) {
    if WinExist("ahk_id " . GetTargetHwnd(W3_WINTITLE)) {
        if(skipIfRunning)
            return false

        msg := "[Y] Exit and restart   [N] Exit   [Cancel] Cancel"
        MsgBox, 4099, Warcraft III가 이미 실행 중입니다, %msg%
        IfMsgBox Cancel
            return false
        IfMsgBox No 
            return CloseAllW3()
        
        CloseAllW3()
        Sleep(3000)
    }

    if(!num) {
        numW3 := GetIniValue("Settings","NUM_W3", 3)
        if !isNatural(numW3) {
            GuiControlGet, squad, main:, SquadField
            StringSplit, squadArray, squad, `,
            num := squadArray0
        }
    }
    if(!num)
        return

    Loop, %num% {
        if (A_Index = 1) {
            hostHwnd := ExecHostW3(speed)
        } else {
            ExecJoinW3(A_Index)
        }
    }

    ; currHwnd := WinExist("A")
    ; WinActivate, ahk_id %hostHwnd%
    ; WinActivate, ahk_id %currhwnd%
    Sleep(numW3 = 1 ? 2500 : 1000)
    SendKey("{alt down}s{alt up}", "C", hostHwnd)
    return TrueTip("ExecMultiW3():Game Start`nClientNum: " num)
}

;비활성 명령으로 실행
ExecHostW3(speed := 0) {
    hwnd := ExecW3(CLIENT_TITLE . "1")
    if(!hwnd)
        return
    RestoreW3Pos(hwnd)
    SendKey("l", "C", hwnd, 2500)
    SendKey("c", "C", hwnd, 2500)

    if (!speed)
        speed := GetIniValue("Settings", "speed")
    if (speed = 1)
        ClickBack(0.053, 0.160, hwnd)
    else if (speed = 2)
        ClickBack(0.192, 0.160, hwnd)
    
    SendKey("c", "C", hwnd)
    return hwnd
}

ExecJoinW3(num := "") {
    hwnd := ExecW3(CLIENT_TITLE . num)
    SendKey("l", "C", hwnd, 2500)
    ;ClickBack(0.4, 0.3, hwnd)
    Loop, 4
        SendKey("{Tab}", "C", hwnd, 100)
    SendKey("j", "C", hwnd)
    ;WinMinimize, ahk_id %hwnd%
}

CloseAllW3() {
    sortedList := []
    ; 정렬: client index가 1인 것은 앞에, 나머지는 뒤에
    for _, hwnd in GetW3Array() {
        if (WinExist("ahk_id " . hwnd) && IsW3(hwnd)) {
            if (GetClientIndex(hwnd) = 1)
                sortedList.InsertAt(1, hwnd) ; 맨 앞에 삽입 (AHK 1.1에선 Insert로 가능)
            else
                sortedList.Push(hwnd)
        }
    }

    ; 일반 종료 시도
    for _, hwnd in sortedList 
        WinClose, ahk_id %hwnd%

    Sleep(300)
    ; 여전히 안 닫힌 창 강제 종료
    for _, hwnd in sortedList {
        if (WinExist("ahk_id " . hwnd)) {
            SendKey("x", "C", hwnd)  ; 강제 종료 시도
            Sleep(300)
        }
    }
}

WaitUntilNotWhiteOrBlack(hwnd, timeout := 8000) {
    start := A_TickCount
    px := 50, py := 50  ; 감시 좌표 (게임 로딩 중 정중앙/좌상단 같은 고정 위치 추천)

    VarSetCapacity(pt, 8, 0)
    NumPut(px, pt, 0, "Int")
    NumPut(py, pt, 4, "Int")
    DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", &pt)
    sx := NumGet(pt, 0, "Int")
    sy := NumGet(pt, 4, "Int")

    Loop {
        hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
        color := DllCall("GetPixel", "Ptr", hdc, "Int", sx, "Int", sy, "UInt")
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)

        r := color & 0xFF
        g := (color >> 8) & 0xFF
        b := (color >> 16) & 0xFF

        ; 흰색(255,255,255) 또는 검정(0,0,0) 이면 아직 준비 전
        if !(r = 255 && g = 255 && b = 255) && !(r = 0 && g = 0 && b = 0) {
            return true  ; 준비됨
        }

        if (A_TickCount - start > timeout)
            return false  ; 타임아웃
        Sleep(100)
    }
}

GetClientIndex(hwnd) {
    WinGetTitle, title, ahk_id %hwnd%
    if (SubStr(title, 1, StrLen(CLIENT_TITLE)) = CLIENT_TITLE) {
        indexStr := SubStr(title, StrLen(CLIENT_TITLE) + 1)
        if (indexStr ~= "^\d+$")
            return indexStr + 0
    }
    return ""
}

GetClientHwndArray() {
    WinGet, w3List, List, ahk_class Warcraft III
    clients := []

    Loop, %w3List%
    {
        hwnd := w3List%A_Index%
        index := GetClientIndex(hwnd)
        if (index != "")
            clients[index] := hwnd
    }
    return clients
}
return

GetW3Array() {
    w3Array := []

    WinGet, w3List, List, ahk_class Warcraft III
    Loop % w3List {
        hwnd := w3List%A_Index%
        if (!IsInArray(w3Array, hwnd))
            w3Array.Push(hwnd)
    }

    WinGet, w3List, List, ahk_exe Warcraft III.exe
    Loop % w3List {
        hwnd := w3List%A_Index%
        if (!IsInArray(w3Array, hwnd))
            w3Array.Push(hwnd)
    }
    return w3Array
}