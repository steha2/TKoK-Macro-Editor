﻿
SendCodeToW3(hwnd := "", delay := 1000) {
    if(pl1 != "" && pl2 != "") {
        if(hwnd) {
            Chat(pl1, "C", hwnd)
            Chat(pl2, "C", hwnd)
        } else {
            if(load_with)
                Chat("-loadwith " . load_with)

            Chat(pl1)
            Chat(pl2)
        }
        Sleep(delay)
        LoadApt(hwnd)
    } else {
        MsgBox, 코드를 입력하지 못했습니다.
    }
}

LoadApt(hwnd := "") {
    ReadAptFile()
    if(hwnd)
        Chat(la, "C", hwnd)
    else
        Chat(la)
}

; Account 파일 중 가장 최신 것에서 -la 코드 추출
ReadAptFile() {
    aptFile := GetLatestFile(SAVE_DIR, "Account*.txt")
    if (aptFile.path != "") {
        FileRead, content, % aptFile.path

        apt := {}  ; APT 정보 객체

        if RegExMatch(content, "Code:\s*-la\s+([^\r\n]+)", match)
            la := "-la " match1
        if RegExMatch(content, "APT:\s*(\d+)", a)
            apt.apt := a1
        if RegExMatch(content, "DEDI PTS:\s*(\d+)", d)
            apt.dedi := d1

        ; GUI에 표시
        GuiControl, main:, AptText, % "APT: " apt.apt "`nDEDI: " apt.dedi

        ; 필요한 경우 함께 반환
        apt.file := aptFile
        apt.time := aptFile.time
        return apt
    } else {
        MsgBox, Account*.txt 파일을 찾을 수 없습니다.
        return {}  ; 빈 객체 반환
    }
}

LoadHero(selectedHero := "", hwnd := "", delay := 1000) {
    if(selectedHero = ""){
        GuiControlGet, squadText, main:, SquadField
        StringSplit, squad, squadText, `,
        selectedHero := squad1
    }
    if(selectedHero = ""){
        ShowTip("선택된 영웅이 없습니다.")
        return
    }
    UpdateHeroInfo(selectedHero)
    SendCodeToW3(hwnd, delay)
}

UpdateHeroInfo(selectedHero, level := 0) {
    selectedHero := GetFullName(selectedHero)
    heroFolder := SAVE_DIR . "\" . selectedHero
    if !FileExist(heroFolder) {
        GuiControl, main:, ResultOutput, 해당 클래스 폴더가 존재하지 않습니다. `n%heroFolder%
        return
    }

    latest := GetLatestFile(heroFolder, selectedHero . "*.txt")
    if (latest.path != "") {
        FileRead, content, % latest.path
        info := ParseHeroFileContent(content)
        info.time := latest.time
        outputText := HeroInfoToText(info)
        pl1 := info.pl1
        pl2 := info.pl2
        GuiControl, main:, ResultOutput, %outputText%
    } else {
        GuiControl, main:, ResultOutput, 해당 클래스에 Hero:%selectedHero% 가 포함된 최신 파일이 없습니다.
    }
}

ParseHeroFileContent(content) {
    info := {}
    RegExMatch(content, "Hero:\s*([A-Za-z\s]+)", m), info.hero := m1
    RegExMatch(content, "Level:\s*(\d+)", m), info.level := m1
    RegExMatch(content, "EXP:\s*(\d+)", m), info.exp := m1
    RegExMatch(content, "Gold:\s*(\d+)", m), info.gold := m1
    RegExMatch(content, "Star Glass:\s*(\d+)", m), info.starGlass := m1
    RegExMatch(content, "Code:\s*(-l[^\r\n""]+)", m), info.pl1 := m1
    RegExMatch(content, "-l2\s+([^\r\n""]+)", m), info.pl2 := "-l2 " . m1
    return info
}

HeroInfoToText(info) {
    FormatTime, fileDateTime, % info.time, yyyy-MM-dd HH:mm:ss
    txt := fileDateTime . "`n"
    txt .= "Hero: " . info.hero . "`n"
    txt .= "Level: " . info.level . "`n"
    txt .= "Exp: " . info.exp . "`n"
    txt .= "Gold: " . info.gold . "`n"
    txt .= "Star Glass: " . info.starGlass . "`n"
    txt .= info.pl1 . "`n" . info.pl2
    return txt
}

LastSaveTimes() {
    GuiControlGet, squad, main:, SquadField ; GUI에서 squad 문자열 얻기
    heroInfo := {} ; 클래스명 => { time: ..., exp: ... }
    ; squad 파싱 (쉼표 구분)
    Loop, Parse, squad, `,
    {
        heroName := GetFullName(Trim(A_LoopField))
        heroFolder := SAVE_DIR "\" heroName
        if !FileExist(heroFolder)
            continue

        latest := GetLatestFile(heroFolder, heroName . "*.txt")
        if (latest.time) {
            FileRead, content, % latest.path
            info := ParseHeroFileContent(content)
            info.time := latest.time
            heroInfo[heroName] := info
        }
    }

    msg := ""
    ; 각 squad 클래스 시간 차이 + EXP 출력
    for heroName, info in heroInfo {
        diff := A_Now
        EnvSub, diff, % info.time, Seconds
        msg .= heroName ": " . FormatTimeDiff(diff) . "   Exp: " . info.exp . "   Gold: " . info.gold . "`n"
    }

    ; account 파일 시간 차이
    accDiff := A_Now
    apt := ReadAptFile()
    EnvSub, accDiff, apt.time, Seconds
    msg := "Account: " . FormatTimeDiff(accDiff) . "   APT: " . apt.apt . "`n" . msg

    MsgBox, 4096, LastSaveTimes, %msg%
}

SwapItems() {
    ClickA(0.187, 0.221)
    ClickA(0.155, 0.374)
    ClickA(0.155, 0.263)
    ClickA(0.192, 0.374)
    ClickA(0.289, 0.270)
    ClickA(0.225, 0.379)
}

MoveOldSaves() {
    MsgBox, 4100, MoveOldSaves, 세이브 파일을 이동하시겠습니까?
    IfMsgBox, No
        return

    Loop, Files, %SAVE_DIR%\*, D
    {
        folderName := A_LoopFileName
        if !RegExMatch(folderName, "^[A-Z]")
            Continue

        heroDir := A_LoopFileFullPath
        oldDir := heroDir . "\old_" . folderName
        if !FileExist(oldDir)
            FileCreateDir, %oldDir%

        ; 최신 파일 찾기
        latest := GetLatestFile(heroDir, "*.txt")
        if (latest.path = "")
            continue

        ; 이동할 파일들
        Loop, Files, %heroDir%\*.txt
        {
            if (A_LoopFileFullPath = latest.path)
                continue
            FileMove, %A_LoopFileFullPath%, % oldDir . "\" . A_LoopFileName, 1
        }
    }

    ; Account 파일 처리
    latest := GetLatestFile(SAVE_DIR, "Account*.txt")
    if (latest.path != "") {
        oldAccountDir := SAVE_DIR . "\old_Account"
        if !FileExist(oldAccountDir)
            FileCreateDir, %oldAccountDir%

        Loop, Files, %SAVE_DIR%\Account*.txt
        {
            if (A_LoopFileFullPath = latest.path)
                continue
            FileMove, %A_LoopFileFullPath%, % oldAccountDir . "\" . A_LoopFileName, 1
        }
    }
    MsgBox, 최신 파일 1개를 제외한 나머지 txt 파일을 old_폴더로 이동했습니다.
}




MultiLoad(squadText := "") {
    if(!squadText)
        GuiControlGet, squadText, main:, SquadField
    squadArr := StrSplit(squadText, ",")
    clientArr := GetClientHwndArray()
    
    ; 배열이 비어 있지 않으면 (== 클라이언트가 최소 1개 이상 존재하면)
    if (!clientArr.Length())
        clientArr := GetW3Array()

    if (!squadArr.Length() || !clientArr.Length()) {
        return ShowTip("로드 목록이나 클라이언트가 없습니다." 
            . "`nLoad list num: " . squadArr.Length() 
            . "`nClient Num 수: " . clientArr.Length())
    }

    if (squadArr.Length() != clientArr.Length()) {
        ShowTip("로드 목록과 클라이언트가 수가 다릅니다." 
            . "`nnLoad list num: " . squadArr.Length() 
            . "`nClient num: " . clientArr.Length())
    }

    LoadSquad(squadArr, clientArr)
    
    if(squadArr.Length() >= 2) {
        SwitchW3(1, true, false, true)
        Sleep(200)
        SendKey("^s {F3}^3 {F2}^2 {F1}^1 +{F2} +{F3}", "NS") ;IgnoreSpace
    } else 
        SendKey("{F1}^1")

    Chat("!dr 10", "R")
    Chat("-clear", "R")
    Chat("-apt", "R")
}

; 반전이 기본값임 클라이언트 3->2->1 순으로
PrepareChampMode(macroPath := "") {
    count := GetClientHwndArray().Length()
    Loop, %count% {
        idx := count - A_Index + 1
        SwitchW3(idx, false, false, true)
        if(idx != 1)
            ShareUnit()
        else
            ChampChat()
   }
}

LoadSquad(squadArr, clientArr) {
    count := squadArr.Length()
    for idx, client in clientArr {
        hero := squadArr[idx]

        WinActivateWait(client)
        if (idx != 1)
            ShareUnit()

        ; 가장 첫 로드는 약간의 딜레이를 더 준다
        LoadHero(hero, "", idx = 1 ? 1500 : 1000) 
        Chat("-qs", "R")

        ; 영웅별 특수 클릭 처리
        if (hero = "Shadowblade") {
            ClickA(0.976, 0.879, "R")
            ClickA(0.906, 0.879, "R")
        } else if (hero = "Barbarian") {
            ClickA(0.801, 0.953, "R")
        } else if (hero = "Chaotic Knight") {
            ;ClickA(0.797, 0.954, "R")
            ;Sleep(500)
        }
    }
}


















