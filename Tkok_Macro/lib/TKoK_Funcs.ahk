
SendCodeToW3() {
    if(pl1 != "" && pl2 != "") {
        Chat(pl1)
        Chat(pl2)
        SendAptToW3()
    } else {
        MsgBox, 코드를 입력하지 못했습니다.
    }
}

SendAptToW3() {
    ReadAptFile()
    Chat(la)
}


; Account 파일 중 가장 최신 것에서 -la 코드 추출
ReadAptFile() {
    result := GetLatestFile(saveDir,"Account*.txt")
    
    if (result.path != "") {
        FileRead, content, % result.path
        if RegExMatch(content, "Code:\s*-la\s+([^\r\n]+)", match) {
            la := "-la " match1
            return result
            ShowTip(la)
        } else
            MsgBox, -la 코드를 찾을수 없습니다.
    } else
        MsgBox, Account*.txt 파일을 찾을수 없습니다.
}

LoadHero(selectedHero) {
    UpdateHeroInfo(selectedHero)
    SendCodeToW3()
}

UpdateHeroInfo(selectedHero) {
    Gui, Submit, NoHide
    pl1 := ""
    pl2 := ""

    heroFolder := saveDir . "\" . selectedHero
    if !FileExist(heroFolder) {
        GuiControl,, ResultOutput, 해당 클래스 폴더가 존재하지 않습니다.
        return
    }
    latest := GetLatestFile(heroFolder, selectedHero . "*.txt")

    if (latest.path != "") {
        FileRead, content, % latest.path
        RegExMatch(content, "Hero:\s*([A-Za-z\s]+)", heroMatch)
        RegExMatch(content, "Level:\s*(\d+)", levelMatch)
        RegExMatch(content, "EXP:\s*(\d+)", expMatch)
        RegExMatch(content, "Gold:\s*(\d+)", goldMatch)
        RegExMatch(content, "Star Glass:\s*(\d+)", starGlassMatch)

        ; 코드 추출
        RegExMatch(content, "Code:\s*(-l[^\r\n""]+)", codeMatch1)
        RegExMatch(content, "-l2\s+([^\r\n""]+)", codeMatch2)
        pl1 := codeMatch11
        pl2 := "-l2 " . codeMatch21

        t := latest.time
        FormatTime, fileDateTime, %t%, yyyy-MM-dd HH:mm:ss

        outputText := fileDateTime . "`n"
        outputText .= "Hero: " . heroMatch1 . "`n"
        outputText .= "Level: " . levelMatch1 . "`n"
        outputText .= "Exp: " . expMatch1 . "`n"
        outputText .= "Gold: " . goldMatch1 . "`n"
        outputText .= "Star Glass: " . starGlassMatch1 . "`n"
        outputText .= pl1 . "`n" . pl2

        GuiControl,, ResultOutput, %outputText%
    } else {
        GuiControl,, ResultOutput, 해당 클래스에 Hero:%selectedHero% 가 포함된 최신 파일이 없습니다.
    }
}

LoadSquad(champ := false) {
    SwitchToMainW3()

    IfWinNotActive, %w3Win%
    {
        MsgBox, 현재 활성화된 창이 Warcraft III가 아닙니다. 실행을 중단합니다.
        return
    }

    GuiControlGet, squadText, %hMain%:, SquadField
    StringSplit, squad, squadText, `,

    WinGet, w3List, List, Warcraft III
    maxWindowCount := w3List

    ; squad0 값과 창 수 중 작은 쪽으로 루프 돌리기
    loopCount := (squad0 < maxWindowCount) ? squad0 : maxWindowCount

    Loop, %loopCount%
    {
        if (A_Index > 1)
            ShareUnit()
        if(!champ) {
            thisHero := squad%A_Index%
            LoadHero(thisHero)
        }
            
        if (thisHero = "Shadowblade")
            Click2(0.906, 0.879, 10, "R")

        if (thisHero = "Barbarian")
            Click2(0.801, 0.953, 10, "R")
 
        if (loopCount > 1)
            SwitchW3()
    }

    if(squad0 > 1)
        SendKey("^s {F3} ^3 {F2} ^2 {F1} ^1", 0, true)

    if(champ)
        ChampChat() ;!dr -fog -cdist 
    else
        Chat("!dr 10")
}

LastSaveTimes() {
    GuiControlGet, squad, %hMain%:, SquadField ; GUI에서 squad 문자열 얻기
    heroTimes := {} ; 클래스명 => 최신 파일 수정시간
    
    ; squad 파싱 (쉼표 구분)
    Loop, Parse, squad, `,
    {
        heroName := Trim(A_LoopField)
        heroFolder := saveDir "\" heroName
        if !FileExist(heroFolder)
            continue
    
        latestTime := 0

        ; 클래스 폴더 내 .txt 파일 탐색
        latest := GetLatestFile(heroFolder,heroName . "*.txt")
        ;MsgBox, % latest.time latest.name
        if (latest.time)
            heroTimes[heroName] := latest.time
    }
    msg := ""
    ; 각 squad 클래스 시간 차이 출력
    for heroName, fileTime in heroTimes
    {
        diff := A_Now
        EnvSub, diff, %fileTime%, Seconds
        msg := heroName ": " . FormatTimeDiff(diff) . "`n" . msg
    }
    
    ; account 파일 시간 차이
    accDiff := A_Now
    EnvSub, accDiff, ReadAptFile().time, Seconds
    msg := "Account: " . FormatTimeDiff(accDiff) . "`n" . msg

    MsgBox, %msg%
}

SwapItems() {
    Click2(0.187, 0.221)
    Click2(0.155, 0.374)
    Click2(0.155, 0.263)
    Click2(0.192, 0.374)
    Click2(0.289, 0.270)
    Click2(0.225, 0.379)
}


MoveOldSaves() {
    Loop, Files, %saveDir%\*, D
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
    latest := GetLatestFile(saveDir, "Account*.txt")
    if (latest.path != "") {
        oldAccountDir := saveDir . "\old_Account"
        if !FileExist(oldAccountDir)
            FileCreateDir, %oldAccountDir%

        Loop, Files, %saveDir%\Account*.txt
        {
            if (A_LoopFileFullPath = latest.path)
                continue
            FileMove, %A_LoopFileFullPath%, % oldAccountDir . "\" . A_LoopFileName, 1
        }
    }
    MsgBox, 최신 파일 1개를 제외한 나머지 txt 파일을 old_폴더로 이동했습니다.
}