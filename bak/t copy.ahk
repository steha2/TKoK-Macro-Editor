Note(newText := "") {
    static isCreated := false
    static NoteEdit
    ; GUI 없으면 생성
    if (!isCreated) {
        Gui, SingleNote:New
        Gui, SingleNote:Default
        Gui, SingleNote: +Resize +AlwaysOnTop
        Gui, SingleNote: Margin, 10, 10
        Gui, SingleNote: Add, Edit, vNoteEdit w400 h300 WantTab
        isCreated := true
    }

    Gui, SingleNote:Default
    existingText := ""
    GuiControlGet, existingText,, NoteEdit
    updatedText := existingText . (existingText != "" ? "`n" : "") . newText
    GuiControl,, NoteEdit, %updatedText%

    ; 창이 이미 떠 있지 않다면 띄우기
    WinGet, existingID, ID, ahk_gui SingleNote
    if (!existingID) {
        Gui, Show,, AHK 메모장
    }

    return

    ; 닫기 버튼 핸들러
    SingleNoteGuiClose:
        Gui, SingleNote:Destroy
        isCreated := false
    return
}

Note("aaa")