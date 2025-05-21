
SaveW3Pos() {
    WinGetTitle, winTitle, A
    WinGetPos, x, y, w, h, A
    
    MsgBox, 4, 창 위치를 저장합니까?, 예/아니오를 선택해 주세요.
    IfMsgBox, No
        return
    
    if (winTitle != "") {
        IniWrite, %x%, %configFile%, W3Window, X
        IniWrite, %y%, %configFile%, W3Window, Y
        IniWrite, %w%, %configFile%, W3Window, W
        IniWrite, %h%, %configFile%, W3Window, H
        ShowTip("저장 완료 : X: " x " Y:" y " W:" w " H:" h)
    }
    else
        MsgBox, 활성 창 정보를 불러올 수 없습니다.
    return
}

RestoreW3Pos() {
    IniRead, savedX, %configFile%, W3Window, X
    IniRead, savedY, %configFile%, W3Window, Y
    IniRead, savedW, %configFile%, W3Window, W
    IniRead, savedH, %configFile%, W3Window, H

    mainW3Hwnd := ""
    activeHwnd := WinExist("A")
    if (activeHwnd) {
        WinGetClass, winClass, ahk_id %activeHwnd%
        if (winClass = w3Win) {
            mainW3Hwnd := activeHwnd
            WinMove, ahk_id %mainW3Hwnd%, , %savedX%, %savedY%, %savedW%, %savedH%
            ShowTip("현재 창을 mainW3Hwnd 로 사용`nX:" savedX " Y:" savedY " W:" savedW " H:" savedH)
        }
    }
}

;큰 W3 창으로 이동한다
SwitchToMainW3() {
    WinGet, war3List, List, %w3Win%
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
            ClipWindow(prevHwnd != hwnd) 
            return
        }
    }
    ShowTip("적절한 Warcraft III 창을 찾을 수 없습니다.")
}

SwitchW3() {
    ; 현재 열린 모든 Warcraft III 창을 가져오기
    WinGet, idList, List, %w3Win%
    lastHwnd := idList%idList%
    if(lastHwnd){
        WinActivate, ahk_id %lastHwnd%
        ClipWindow()
    }
    ;ShowTip("SwitchW3`n" lastHwnd)
}

TrySwitchW3() {
    if (switchRunning >= 2)  ; 동시에 2개 이상 실행 중이면 무시
        return
    if (switchRunning > 0) {
        SetTimer, SwitchW3, -300
    } else {
        SetTimer, SwitchW3, -1
    }
}

ShareUnit() {
    SendKey("{F11}", 500)
    Click2(0.599,0.204)
    SendKey("{Enter}")
}



ExecHostW3(){
    ExecW3(W3_LAUNCH_DELAY)
    IfWinNotActive, %w3Win%
    {
        MsgBox, 현재 활성화된 창이 Warcraft III가 아닙니다. 실행을 중단합니다.
        return
    }
    SendKey("L",3000)
    RestoreW3Pos()
    SendKey("c",3000)

    IniRead, speed, %configFile%, Settings, speed, 2
    if(speed = 0) {
        Click2(0.053, 0.160)
    } else if (speed = 1) {
        Click2(0.192, 0.160)
    }
    SendKey("c")
}

ExecMultiW3() {
    IfWinExist, ahk_class Warcraft III 
    {
        MsgBox, Warcraft III가 이미 실행 중입니다.
        return
    }

    ExecHostW3()
    IfWinNotActive, ahk_class Warcraft III
    {
        MsgBox, 현재 활성화된 창이 Warcraft III가 아닙니다. 실행을 중단합니다.
        return
    }

    IniRead, count, %configFile%, Settings, count, 2
    if !isNatural(count) {
        GuiControlGet, squad,, SquadField
        StringSplit, squadArray, squad, `,
        count := squadArray0
    }

    Loop, %count% {
        ExecW3()
        SendKey("L", 3000)
        Click2(0.4, 0.3)
        SendKey("J")
    }

    SwitchToMainW3()
    Sleep, 1000
    SendKey("!s")
}

ExecW3(delay := 3000) {
    Run, *RunAs %w3lnk%

    if (w3lnk = "" || !FileExist(w3lnk)) {
        MsgBox, 16, 오류, 실행할 W3_LNK 경로를 찾지 못했습니다.`nconfig.ini 를 수정하세요.
        return false
    }

    WinWait, ahk_class Warcraft III
    WinActivate, ahk_class Warcraft III
    WinWaitActive, ahk_class Warcraft III
    Sleep, delay
}
