ToggleMacroGui:
    ToggleMacroGui()
return

mainGuiClose:
    SaveCodeLoaderSettings()
    SaveMacroEditorSettings()
    ExitApp
return

MultiLoad:
    MultiLoad()
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
return

RemoveHero:
    GuiControlGet, oldSquad, main:, SquadField
    if (oldSquad = "")
        return
    newSquad := TrimLastToken(oldSquad, ",")
    GuiControl, main:, SquadField, %newSquad%
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

; 키 매핑 토글
ToggleYMapping(force := 2) {
    if (force != 2)
        yMapped := !!force
    else
        yMapped := !yMapped
    ShowTip(yMapped ? "🟢 y↔f 매핑 켜짐" : "❌ y↔f 매핑 꺼짐", 1000, false)
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

#If IsW3() and yMapped and !isRecording
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

#If IsW3()
^Y::ToggleYMapping(2)

;Interact
F4::
    SendA("n",550)
    SendA("{Numpad8}",100)
    SendA("i",100)
    MouseClick,L
return

F5::Chat("-inv")
F6::Chat("-tt")

;아이템 교체
!X::
    KeyWait, Alt
    GuiControlGet, squadText, main:, SquadField
    StringSplit, squad, squadText, `,
    WinGet, w3List, List, %W3_WINTITLE%
    loopCount := Min(squad0,w3List)
    Loop, %loopCount%
    {
        SendKey("n",100)
        gosub, F5
        Sleep(200)
        SwapItems()
        gosub, F5
        SwitchNextW3(A_Index = loopCount)
        Sleep(300)
        
    }
return

;Ctrl+Shift+C
ChampChat() {
    Chat("!dr 10")
    Chat("-fog")
    Chat("-cdist 2300")
    Chat("-music")
    LoadApt()
}

#If WinActive("ahk_id " . hMain)
^S::
    GuiControlGet, squadText, main:, SquadField
    SetIniValue("Settings", "SavedSquad", squadText)
    ShowTip("Load hero list Saved")
return

#If !isRecording
^+N::ChampChat()
!+W::SaveW3Pos()

;Alt
!D::Win_Minimize("A")
!E::RestoreW3Pos()
!1::SwitchW3(1, true)
!2::SwitchW3(2, true)
!3::SwitchW3(3, true)
!W::SwitchNextW3()
!U::MoveOldSaves()
!T::
    KeyWait, Alt
    MultiLoad()
return
;!Y::LoadSquad3()
!H::PrepareChampMode() ;Champion Mode
!L::OpenLogFile()

;Ctrl+Shift
^+K::ExecW3()
^+A::LoadApt()
^+W::ExecMultiW3()
^+H::ExecHostW3()
^+C::LastSaveTimes()
^+I:: Run, notepad.exe "%CONFIG_FILE%"
^+O:: Run, %A_ScriptDir%
^+P:: Run, %SAVE_DIR%

F7::ToggleClipMouse()

#If
;매크로 재시작
^+R::
    SaveCodeLoaderSettings()
    SaveMacroEditorSettings()
    reload
return