ToggleMacroGui:
    ToggleMacroGui()
return

mainGuiClose:
    SaveCodeLoaderSettings()
    SaveMacroEditorSettings()
    ExitApp
return

MultiLoad:
    LoadSquad()
return

ExecMultiW3:
    ExecMultiW3()
return

HeroButtonClick:
    Gui, Submit, NoHide
    GuiControlGet, btnText, main:, %A_GuiControl% ; 버튼의 텍스트를 가져온다
    UpdateHeroInfo(btnText)
return

AddHero:
    GuiControlGet, resultText, main:, ResultOutput
    if(!resultText)
        return
    heroNames := ""

    Loop, Parse, resultText, `n, `r
    {
        if (RegExMatch(A_LoopField, "Hero:\s*(.+)", match))
            heroNames .= match1 . ","
    }

    ; 마지막 쉼표 제거
    StringTrimRight, heroNames, heroNames, 1
    GuiControlGet, oldSquad, main:, SquadField

    ; 일반 클릭 시 클래스 추가
    if (oldSquad != "")
        newSquad := oldSquad . "," . heroNames
    else
        newSquad := heroNames
    GuiControl, main:, SquadField, %newSquad%
    SetIniValue("Settings","SavedSquad",newSquad) 
return

RemoveHero:
    GuiControlGet, oldSquad, main:, SquadField
    if (oldSquad = "")
        return
    newSquad := TrimLastToken(oldSquad, ",")
    GuiControl, main:, SquadField, %newSquad%
    SetIniValue("Settings","SavedSquad",newSquad)
return

AptBtn:
    ReadAptFile()
    if(la != "" && WinExist(W3_WINTITLE) && !GetKeyState("Shift", "P")) {
        WinActivate, %W3_WINTITLE%
        Chat(la)
    }
return

LoadBtn:
    if(WinExist(W3_WINTITLE)) {
        WinActivate, %W3_WINTITLE%
        SendCodeToW3()
    }
return

#If (WinActive("ahk_class Warcraft III") and yMapped and !isRecording)
; Y → F (조합키 포함)
*F::SendMapped("y")
; F → Y (조합키 포함)
*Y::SendMapped("f")

; Ctrl+F 예외처리
; ^f::
;     if (yMapped)
;         Send ^f  ; yMapped 상태에서는 실제 f 키 전송
;     else
;         Send ^f  ; 그대로
; return

#IfWinActive ahk_class Warcraft III
^Y::ToggleYMapping(2)

; 키 매핑 토글
ToggleYMapping(force := 2) {
    if (force != 2)
        yMapped := !!force
    else
        yMapped := !yMapped
    ShowTip(yMapped ? "🟢 y↔f 매핑 켜짐" : "🔴 y↔f 매핑 꺼짐")
}

; 실제 전송 함수 (Shift, Ctrl 등 고려)
SendMapped(key) {
    mods := ""
    if (GetKeyState("Shift", "P"))
        mods .= "+"
    if (GetKeyState("Ctrl", "P"))
        mods .= "^"
    if (GetKeyState("Alt", "P"))
        mods .= "!"
    if(yMapped && mods = "^" && key = "y")
        mods := "", key := "f"
    Send, % mods key
}

;Interact
F4::
    SendKey("n",550)
    SendKey("{Numpad8}",100)
    SendKey("i",100)
    MouseClick,L
return

F5::Chat("-inv")
F6::Chat("-tt")

;마우스 가두기
F7::ClipWindow()

;아이템 교체
!X::
    KeyWait, Alt
    GuiControlGet, squadText, %hMain%:, SquadField
    StringSplit, squad, squadText, `,
    WinGet, w3List, List, %W3_WINTITLE%
    loopCount := Min(squad0,w3List)
    Loop, %loopCount%
    {
        SendKey("n",100)
        gosub, F5
        Sleep, 200
        SwapItems()
        gosub, F5
        if (A_Index < loopCount)
            SwitchW3(false)
        else    
            SwitchToMainW3()
        Sleep, 300
        
    }
return

;Ctrl+Shift+C
^+N::ChampChat()
ChampChat() {
    Chat("!dr 10")
    Chat("-fog")
    Chat("-cdist 2300")
    Chat("-music")
    Chat("-spsi 4")
    SendAptToW3()
}

!+W::SaveW3Pos()

#If !isRecording

;Alt
!E::RestoreW3Pos()
!3::SwitchToMainW3()
!2::TrySwitchW3()
!U::MoveOldSaves()
!T::LoadSquad()
!H::LoadSquad(true) ;Champion Mode


;Ctrl+Shift
^+K::ExecW3()
^+A::SendAptToW3()
^+W::ExecMultiW3()
^+H::ExecHostW3()
^+C::LastSaveTimes()
^+I:: Run, notepad.exe "%CONFIG_FILE%"
^+O:: Run, %A_ScriptDir%
^+P:: Run, %SAVE_DIR%

#If
;매크로 재시작
^+R::
    SaveCodeLoaderSettings()
    SaveMacroEditorSettings()
    reload
return