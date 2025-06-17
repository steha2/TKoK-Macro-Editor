GenerateNamePlateSamples() {
    ShowTip("Start - GenerateNamePlateSamples()")
    WinActivateWait(W3_WINTITLE)
    if !GetNamePlatePos(ix, iy, ix2, iy2, iw, ih, imgDir)
        return Alert("Warcraft III 창이 아닙니다.")

    w3_ver := GetW3_Ver(WinActive("A"))
    
    msg := "w3_ver: " w3_ver "`n`nsampleDir:`n" imgDir
         . "`n`nPress the arrow keys to select [ Arcanist ]"
         . "`nthen press [ Yes ] to generate the sample."
    MsgBox, 4100, GenerateNamePlateSamples, %msg%  ; 4 = Yes/No 버튼
    IfMsgBox, No
        return

    if(!IsDirectory(imgDir))
        FileCreateDir, %imgDir%

    for index, hero in heroArr {
        Sleep( NEW_HERO_DELAY + 100)
        file := imgDir . "\" . hero . ".png"
        
        if(!CaptureImage(ix, iy, iw, ih, file)) {
            FileRemoveDir, %imgDir%, 1  ; 1 = 삭제 재귀적으로
            return FalseTip("이미지 캡처 실패`n" ix "," iy "," iw "," ih "`n" file)
        }
        SendA("{Right}")
    }
    return TrueTip("Hero sample image Saved: " imgDir)
}

CaptureImage(x, y, w, h, fileOut := "capture.png") {
    pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
    if (!pBitmap)
        return FalseTip("캡처 실패: pBitmap 없음")

    result := Gdip_SaveBitmapToFile(pBitmap, fileOut)
    Gdip_DisposeImage(pBitmap)

    if (result != 0)
        return FalseTip("저장 실패: 오류 코드 " . result)

    return TrueTip("capture: " . fileOut)
}


ResolveHeroIndex(name) {
    static heroMap := {}, heroPrefixMap := {}

    ; 초기화: 한 번만 수행
    if (!heroMap.Count()) {
        for index, hero in heroArr {
            nameTrimmed := Trim(hero)
            initials := ""
            Loop, Parse, nameTrimmed, %A_Space%
                initials .= SubStr(A_LoopField, 1, 1)

            nameLower := StrLower(nameTrimmed)
            heroMap[nameTrimmed] := index
            heroMap[nameLower] := index
            heroMap[StrLower(initials)] := index

            ; 앞에서부터 최소 3글자 이상 매핑
            Loop, % StrLen(nameLower) - 2 {
                prefix := SubStr(nameLower, 1, A_Index + 2)
                if (!heroPrefixMap.HasKey(prefix))
                    heroPrefixMap[prefix] := index
            }
        }

        ; 커스텀 약어
        heroMap["sb"] := 9
        heroMap["eq"] := 17
        heroMap["panda"] := 6
        heroMap["shaman"] := 18
    }

    normName := StrLower(name)
    index := heroMap[normName]
    if (!index && heroPrefixMap.HasKey(normName))
        index := heroPrefixMap[normName]

    return index
}

GetFullName(shortName) {
    return heroArr[ResolveHeroIndex(StrLower(shortName))]
}

FindHeroPath(currName, targetName) {
    currIndex := ResolveHeroIndex(currName)
    if (!currIndex)
        return FalseTip("FindHeroPath`n영웅을 찾을 수 없습니다: " . currName)

    targetIndex := ResolveHeroIndex(targetName)
    if (!targetIndex)
        return FalseTip("FindHeroPath`n영웅을 찾을 수 없습니다: " . targetName)

    if (currIndex = targetIndex)
        return

    total := heroArr.Length()
    rightDist := Mod((targetIndex - currIndex + total), total)
    leftDist  := Mod((currIndex - targetIndex + total), total)

    Log("FindHeroPath(): curr: " currName "  target:" targetName "  dir: " dir " " count)
    if (rightDist <= leftDist)
        return {dir: "{right}", count: rightDist}
    else
        return {dir: "{left}", count: leftDist}
}

GetNamePlatePos(ByRef x1, ByRef y1, ByRef x2, ByRef y2, ByRef iw, ByRef ih, ByRef imgDir) {
    hwnd := GetTargetHwnd(W3_WINTITLE)
    w3_ver := GetW3_Ver(hwnd)
    
    if(!w3_ver)
        return FalseTip("GetNamePlatePos()`nWarcraft III 창이 아닙니다")

    nameplate := uiRegions[w3_ver]["nameplate"]
    x1 := nameplate.x1
    y1 := nameplate.y1
    x2 := nameplate.x2
    y2 := nameplate.y2
    
    CalcCoords(x1, y1, hwnd)
    CalcCoords(x2, y2, hwnd)
    
    ClientToScreen(hwnd, x1, y1)
    ClientToScreen(hwnd, x2, y2)
    
    iw := x2 - x1
    ih := y2 - y1

    GetClientSize(hwnd, cw, ch)
    imgDir := A_ScriptDir . "\res\" . w3_ver . "\W" . cw . "H" . ch

    return true
}

GetHeroNameByImg() {
    if !IsW3()
        return FalseTip("Warcraft III 창이 아닙니다")

    GetNamePlatePos(ix, iy, ix2, iy2, iw, ih, imgDir)

    if (!IsDirectory(imgDir)) {
        ShowTip("클라이언트 화면 크기에 맞는 폴더가 없습니다. `nThe folder does not exist: " imgDir)
        return -1
    }

    Loop, Files, %imgDir%\*.png  ; PNG 견본만 검사 (필요시 BMP 등 확장자 추가)
    {
        imageFile := A_LoopFileFullPath
        heroName := GetFileNameNoExt(A_LoopFileName)
        ImageSearch, outX, outY, %ix%, %iy%, %ix2%, %iy2%, *0 %imageFile%
        if (ErrorLevel = 0) {
            Log("찾은 영웅 : " heroName)
            return heroName
        }
    }

    return FalseTip("GetNameByImg(): 영웅 선택 화면이 아니거나. 영웅을 찾지 못했습니다."
                 . "`nThis is not the hero selection screen. The hero was not found."
                 . ix "  " iy "  " ix2 "  " iy2 "  " iw "  " ih "  " imgDir)
}

PickNewHero(targetHero) {
    MouseMove(0.5, 0.5)
    SendA("{right}", NEW_HERO_DELAY)

    currHero := GetHeroNameByImg()

    if (currHero = 0)
        return FalseTip("PickNewHero(): Fail to find hero : " targetHero)

    if (currHero = -1) {
        GenerateNamePlateSamples()
        Sleep(2000)
        currHero := GetHeroNameByImg()
    }

    path := FindHeroPath(currHero, targetHero)
    Loop, % path.count {
        SendA(path.dir)
        Sleep(NEW_HERO_DELAY)
    }
    
    currHero := GetHeroNameByImg()
    
    if (GetFullName(targetHero) = currHero) {
        SendA("{Esc}")
        Sleep(500)
        Log("영웅 선택 완료: " currHero)
        return true
    }
    return FalseTip("영웅 선택 실패 targetHero: " targetHero "  currHero: " currHero )
}

PickNewHeroC(targetHero, hwnd) {
    if(!hwnd)
        return FalseTip("PickNewHeroC(): hwnd not found")

    Critical
    WinActivateWait(hwnd)
    MouseMove(0.5, 0.5)
    SendKey("{right}", "C", hwnd, NEW_HERO_DELAY)
    currHero := GetHeroNameByImg()
    Critical, Off

    if (currHero <= 0)
        return FalseTip("PickNewHeroC(): Fail to find hero : " targetHero "  win_title: " Win_GetTitle(hwnd))

    path := FindHeroPath(currHero, targetHero)
    Loop, % path.count
        SendKey(path.dir, "C", hwnd, NEW_HERO_DELAY)
    
    SendKey("{Esc}", "C", hwnd, 500)

    Log("PickNewHeroC() 영웅 선택 완료: " currHero)
    return true
}



