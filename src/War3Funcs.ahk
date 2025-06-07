SaveW3Pos() {
    WinGetTitle, winTitle, A
    WinGetPos, x, y, w, h, A
    
    MsgBox, 4, 창 위치를 저장합니까?, 예/아니오를 선택해 주세요.
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
        activeHwnd := WinExist("A")
    if (activeHwnd) {
        WinMove, ahk_id %activeHwnd%, , %savedX%, %savedY%, %savedW%, %savedH%
        ;ShowTip("현재 창을 mainW3Hwnd : " mainW3Hwnd "`nX:" savedX " Y:" savedY " W:" savedW " H:" savedH)
    }
}

ActivateBottomW3() {
    WinActivateBottom, ahk_class Warcraft III
}

SwitchNextW3(isClip := true, minimizePrev := true) {
    currHwnd := WinExist("A")
    WinGetTitle, prevTitle, ahk_id %currHwnd%
    WinGetClass, prevClass, ahk_id %currHwnd%

    if (prevClass = W3_WINTITLE && InStr(prevTitle, CLIENT_TITLE)) {
        ; 현재 창의 클라이언트 넘버 추출
        clientNum := StrReplace(prevTitle, CLIENT_TITLE) -1
        
        if (clientNum < 1) {
            WinGet, w3Count, List, ahk_class Warcraft III
            clientNum := w3Count
        }
        SwitchW3(clientNum, isClip, minimizePrev)
    } else {
        ActivateBottomW3()
    }
    ; 타이머 관리
    switchRunning--
    if (switchRunning < 0)
        switchRunning := 0
}

SwitchW3(clientNum := 1, isClip := true, minimizePrev := true) {
    currHwnd := WinExist("A")
    nextHwnd := WinExist(CLIENT_TITLE . clientNum)
    WinGetClass, prevClass, ahk_id %currHwnd%
    currIsW3 := prevClass = W3_WINTITLE
    if(currHwnd = nexthwnd) {
        ; 같은 창 호출시 창 전환 안하고 토글 마우스 가두기
        if (isClip)
            ToggleClipMouse(nextHwnd) 
    } else if (nextHwnd) { ; 전환 할 창이 있는 경우
        WinActivate, ahk_id %nextHwnd%
        if (minimizePrev && currHwnd && WinExist("ahk_id " currHwnd) && currIsW3)
            WinMinimize, ahk_id %currHwnd%
        if (isClip)
            ClipMouse(nextHwnd)
    } else if (currIsW3) { ; 현재 창이 Wacraft III 기본 타이틀 인 경우
        WinSetTitle, ahk_id %currHwnd%,,% CLIENT_TITLE . clientNum
    } else {
        ActivateBottomW3()
    }
}

TrySwitchNextW3() {
    if (switchRunning >= 3)
        return
    SetTimer, SwitchNextW3, % (-200 * switchRunning) - 1
    switchRunning++
}

ShareUnit(hwnd := "") {
    if(hwnd) {
        SendKeyI("{F11}", hwnd, 700)
        ClickBack(0.599,0.204, hwnd)
        SendKeyI("{Enter}", hwnd)
    } else {
        Sleep, 500
        SendKey("{F11}", 700)
        ClickA(0.599,0.204)
        SendKey("{Enter}")
    }
}

ExecW3(roleTitle := "", mini := false) {
    if (W3_LNK = "" || !FileExist(W3_LNK))
        return Alert("실행할 W3_LNK 경로를 찾지 못했습니다.`nconfig.ini 에서 경로를 수정하세요.")
    
    origHwnd := Win_Exist("A")
    ;실행 후 hwnd 을 찾을대까지 기다림
    hwnd := RunGetHwnd(W3_LNK, "Warcraft III")
    if (!hwnd)
        return Alert("Warcraft III 창을 찾을 수 없습니다.")
    WinSet, AlwaysOnTop, On, ahk_id %hwnd%
    success := WaitUntilNotWhiteOrBlack(hwnd, 5000)
    WinActivate, ahk_id %origHwnd%
    WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
    if (success) {
        if (roleTitle)
            WinSetTitle, ahk_id %hwnd%, , %roleTitle%
        if (mini)
            WinMinimize, ahk_id %hwnd%
        
        Sleep, 2000 ;UI 로딩 대기
        return hwnd
    } else {
        return Alert("UI 로딩 감지 실패 (흰/검 배경에서 벗어나지 않음")
    }
}

;비활성 명령으로 실행
ExecMultiW3(num := 0) {
    if WinExist("ahk_class Warcraft III") {
        msg := "[Y] 종료 후 다시 실행   [N] 종료만   [Cancel] 취소"
        MsgBox, % 3 | 4096, Warcraft III가 이미 실행 중입니다, %msg%
        IfMsgBox Cancel
            return false
        IfMsgBox No 
        {
            CloseAllW3()
            Sleep, 300
            return true
        }
        ; IfMsgBox Yes (또는 아무 처리 없이 아래로 흐름 유지)
        CloseAllW3()
        Sleep, 300
    }

    if(num > 0){
        numW3 := num
    } else {
        numW3 := GetIniValue("Settings","NUM_W3", 3)
        if !isNatural(numW3) {
            GuiControlGet, squad, main:, SquadField
            StringSplit, squadArray, squad, `,
            numW3 := squadArray0, 1
        }
    }

    Loop, % Max(numW3,1)
    {
        if (A_Index = 1) {
            hostHwnd := ExecHostW3()
        } else {
            ExecJoinW3(A_Index)
        }
    }

    Sleep, numW3 = 1 ? 3000 : 1000
    SendKeyI("{alt down}s{alt up}", hostHwnd)
}

;비활성 명령으로 실행
ExecHostW3() {
    hwnd := ExecW3(CLIENT_TITLE . "1")
    if(!hwnd)
        return
    RestoreW3Pos(hwnd)
    SendKeyI("l", hwnd, 3000)
    SendKeyI("c", hwnd, 3000)

    speed := GetIniValue("Settings","speed")
    if(speed = 0) {
        ClickBack(0.053, 0.160, hwnd)
    } else if (speed = 1) {
        ClickBack(0.192, 0.160, hwnd)
    }
    SendKeyI("c", hwnd)
    return hwnd
}

ExecJoinW3(num := "") {
    hwnd := ExecW3(CLIENT_TITLE . num)
    SendKeyI("l", hwnd, 3000)
    ;ClickBack(0.4, 0.3, hwnd)
    Loop, 4
        SendKeyI("{tab}", hwnd, 100)
    SendKeyI("j", hwnd)
}

CloseAllW3() {
    WinGet, list, List, ahk_class Warcraft III
    Loop, %list%
    {
        hwnd := list%A_Index%
        if(hwnd)
            WinClose, ahk_id %hwnd%
    }
    Sleep, 300
    Loop, %list%
    {
        hwnd := list%A_Index%
        if(hwnd)
            SendKeyI("x",hwnd)
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
        Sleep, 100
    }
}

GetClientHwndArray() {
    WinGet, w3List, List, ahk_class Warcraft III
    clients := []

    Loop, %w3List%
    {
        hwnd := w3List%A_Index%
        WinGetTitle, title, ahk_id %hwnd%

        ; CLIENT_TITLE로 시작하면 숫자 추출
        if (SubStr(title, 1, StrLen(CLIENT_TITLE)) = CLIENT_TITLE) {
            indexStr := SubStr(title, StrLen(CLIENT_TITLE) + 1)
            if (indexStr ~= "^\d+$") {
                index := indexStr + 0  ; 문자열을 숫자로
                clients[index] := hwnd
            }
        }
    }
    return clients
}

!Numpad5::ExecHostW3()
!Numpad6::ExecJoinW3()
!Numpad7::SendKeyI("s", WinExist("ahk_class Warcraft III"))
!Numpad8::
SendKeyI("{Enter}", WinExist("ahk_class Warcraft III"),100)
SendKeyI("asdf", WinExist("ahk_class Warcraft III"),100)
SendKeyI("{ctrl down}v{ctrl up}", WinExist("ahk_class Warcraft III"),100)
SendKeyI("{Enter}", WinExist("ahk_class Warcraft III"))
return
