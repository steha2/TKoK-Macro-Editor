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

RestoreW3Pos() {
    savedX := GetIniValue("W3Window","X")
    savedY := GetIniValue("W3Window","Y")
    savedW := GetIniValue("W3Window","W")
    savedH := GetIniValue("W3Window","H")
    mainW3Hwnd := ""
    activeHwnd := WinExist("A")
    if (activeHwnd) {
        WinGetClass, winClass, ahk_id %activeHwnd%
        if (winClass = W3_WINTITLE) {
            mainW3Hwnd := activeHwnd
            WinMove, ahk_id %mainW3Hwnd%, , %savedX%, %savedY%, %savedW%, %savedH%
            ;ShowTip("현재 창을 mainW3Hwnd : " mainW3Hwnd "`nX:" savedX " Y:" savedY " W:" savedW " H:" savedH)
        }
    }
}

;큰 W3 창으로 이동한다
SwitchToMainW3(isClip := true) {
    WinGet, war3List, List, %W3_WINTITLE%
    WinGet, prevHwnd, ID, A  ; 현재 활성 창 핸들 얻기
    
    Loop, %war3List%
    {
        hwnd := war3List%A_Index%

        ; 최소화 여부 확인
        WinGet, MinMax, MinMax, ahk_id %hwnd%
        if (MinMax = 1) {
            WinRestore, ahk_id %hwnd%
            Sleep, 100
        }

        WinGetPos,,, , height, ahk_id %hwnd%
        if (hwnd = mainW3Hwnd || height >= 800) {
            WinActivate, ahk_id %hwnd%
            Sleep, 100
            ;이전창이 현재창과 같으면 마우스 가두기 토글, 아니면 마우스 가두기 실행
            if(isClip)
                ClipWindow(prevHwnd != hwnd) 
            return
        }
    }
    ShowTip("적절한 Warcraft III 창을 찾을 수 없습니다.")
}

SwitchW3(isClip := true) {
    ; 현재 열린 모든 Warcraft III 창을 가져오기
    WinGet, idList, List, %W3_WINTITLE%
    lastHwnd := idList%idList%
    if(lastHwnd){
        WinActivate, ahk_id %lastHwnd%
        if(isClip)
            ClipWindow()
    }
    switchRunning := 0
}

TrySwitchW3() {
    if (switchRunning >= 3)
        return
    SetTimer, SwitchW3, % (-200 * switchRunning) - 1
    switchRunning++
}

ShareUnit() {
    Sleep, 500
    SendKey("{F11}", 700)
    Click(0.599,0.204)
    SendKey("{Enter}")
}

ExecHostW3(){
    ExecW3(W3_LAUNCH_DELAY)
    IfWinNotActive, %W3_WINTITLE%
    {
        MsgBox, 현재 활성화된 창이 Warcraft III가 아닙니다. 실행을 중단합니다.
        return
    }
    SendKey("L",3000)
    RestoreW3Pos()
    SendKey("c",3000)

    speed := GetIniValue("Settings","speed")
    if(speed = 0) {
        Click(0.053, 0.160)
    } else if (speed = 1) {
        Click(0.192, 0.160)
    }
    SendKey("c")
}

ExecMultiW3(num := 0) {
    IfWinExist, ahk_class Warcraft III 
    {
        MsgBox, Warcraft III가 이미 실행 중입니다.
        return
    }
    if(num > 0){
        numW3 := num
    } else {
        numW3 := GetIniValue("Settings","NUM_W3", 3)
        if !isNatural(numW3) {
            GuiControlGet, squad, main:, SquadField
            StringSplit, squadArray, squad, `,
            numW3 := squadArray0
        }
    }
    Loop, % numW3
    {
        if (A_Index = 1) {
            ExecHostW3()
            IfWinNotActive, ahk_class Warcraft III    
            {
                MsgBox, 현재 활성화된 창이 Warcraft III가 아닙니다. 실행을 중단합니다.
                return
            }
        } else {
            ExecW3()
            SendKey("L", 3100)
            Click(0.4, 0.3)
            SendKey("J")
        }
    }

    if(numW3 > 0)
        SwitchToMainW3(false)
    else 
        Sleep, 2000
    Sleep, 1000
    SendKey("!s")
}

ExecW3(delay := 3000) {
    Run, *RunAs %W3_LNK%

    if (W3_LNK = "" || !FileExist(W3_LNK)) {
        MsgBox, 16, 오류, 실행할 W3_LNK 경로를 찾지 못했습니다.`nconfig.ini 를 수정하세요.
        return false
    }

    WinWait, ahk_class Warcraft III
    WinActivate, ahk_class Warcraft III
    WinWaitActive, ahk_class Warcraft III
    Sleep, delay
}