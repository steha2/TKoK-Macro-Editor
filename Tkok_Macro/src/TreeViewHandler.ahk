BuildTreeView(rootPath, parentID := 0) {
    global g_PathMap
    Loop, Files, % rootPath "\*", D
    {
        folderName := A_LoopFileName
        fullPath := A_LoopFileFullPath
        folderID := TV_Add(folderName, parentID)
        g_PathMap[folderID] := fullPath
        BuildTreeView(fullPath, folderID)
    }
    Loop, Files, % rootPath "\*.txt"
    {
        fileName := A_LoopFileName
        displayName := RegExReplace(fileName, "\.txt$", "")  ; .txt 제거
        fullPath := A_LoopFileFullPath
        fileID := TV_Add(displayName, parentID)
        g_PathMap[fileID] := fullPath
    }
}

ReloadTreeView(path := "") {
    suspendTreeEvents := true
    TV_Delete()           ; 트리뷰 항목 초기화
    g_PathMap := {}       ; 경로 맵 초기화
    BuildTreeView(MACRO_DIR)  ; 트리 다시 만들기
    

    ; 트리 구축 후 경로 선택
    suspendTreeEvents := false
    Sleep, 250

    if(path = MACRO_DIR)
        path := ""
    if (path = "") {
        UpdatePathAndEdit("")
    } else {
        SelectTreeItemByPath(path)
    }
}

OnClickTreeItem() {
    if (suspendTreeEvents)
        return  ; 이벤트 무시
    path := g_PathMap[A_EventInfo]

    if (!path || !FileExist(path))
        return
    UpdatePathAndEdit(path)
}

SelectTreeItemByPath(path) {
    ; MsgBox, [입력 path]`n%path%
    path := RegExReplace(path, "/", "\")
    path := Trim(path, " \t`n`r")

    for id, fullPath in g_PathMap {
        normPath := Trim(RegExReplace(fullPath, "/", "\"), " \t`n`r")
        ; MsgBox, Testing ID: %id%`nPath: %normPath%`nCompare to: %path%
        if (StrCompare(normPath, path)) {
            UpdatePathAndEdit(path)
            TV_Modify(id, "Select Expand")
            return id
        }
    }

    MsgBox, 48, 경고, 지정한 경로의 항목을 찾을 수 없습니다.`n%path%
    UpdatePathAndEdit("")
    return false
}

;path가 "" 없으면 Edit지우기, 있으면 파일로드
UpdatePathAndEdit(path) {
    if IsMacroModified() {
        MsgBox, 4, 저장되지 않음, 변경 내용을 저장하지 않고 진행합니까?
        IfMsgBox, No
            return 
    }
    macroPath := path
    content := ""
    if (IsFile(path)) {
        FileRead, content, %path%
        StringReplace, content, content, `r,, All  ; CR 제거
    }
    origContent := content
    GuiControl,, EditMacro, %content%
    GuiControl,, MacroPath, % StrReplace(TrimLastToken(path,"."), MACRO_DIR . "\", "")
}

GetSelectedTreePath() {
    Gui, Submit, NoHide
    selectedID := TV_GetSelection()

    if (!selectedID)
        return ""  ; 아무 항목도 선택되지 않음

    return g_PathMap[selectedID]
}

SelectTreeItemByName(target) {
    global g_PathMap
    rootID := TV_GetChild(0)
    LoopTree(rootID, target)
}

LoopTree(itemID, target) {
    while (itemID) {
        TV_GetText(text, itemID)
        fullPath := g_PathMap[itemID]
        nameNoExt := RegExReplace(text, "\.[^.]*$")

        if (text = target || nameNoExt = target) {
            TV_Modify(itemID, "Select")
            return true
        }

        childID := TV_GetChild(itemID)
        if (childID) {
            if (LoopTree(childID, target))  ; 재귀
                return true
        }
        itemID := TV_GetNext(itemID)
    }
    return false
}
