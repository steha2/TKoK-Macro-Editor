
GetIniValue(section, key, default := "") {
    IniRead, val, % CONFIG_FILE, %section%, %key%, %default%
    val := Trim(val)
    return val
}

SetIniValue(section, key, value) {
    IniWrite, % value, % CONFIG_FILE, %section%, %key%
}

;return latest := {path: "", name: "", time: 0}
GetLatestFile(folderPath, filePattern := "*", nameRegex := "") {
    latest := {path: "", name: "", time: 0}

    Loop, Files, %folderPath%\%filePattern%
    {
        ; 정규식 필터 조건이 있으면 검사
        if (nameRegex != "" && !RegExMatch(A_LoopFileName, nameRegex))
            continue

        ; 가장 최근 수정 시간의 파일 갱신
        if (A_LoopFileTimeModified > latest.time) {
            latest := {path: A_LoopFileFullPath, name: A_LoopFileName, time: A_LoopFileTimeModified}
        }
    }
    return latest
}


SaveJSON(path, data) {
    FileDelete, %A_ScriptDir%\%path%
    FileAppend, %data%, %A_ScriptDir%\%path%, UTF-8
}


IsFile(path, ext := "") {
    if !(FileExist(path) && !InStr(FileExist(path), "D"))
        return false

    if (ext = "")
        return true  ; 확장자 검사 없이 존재하는 파일이면 true

    SplitPath, path,,, fileExt
    return (LTrim(StrLower(ext), ".") = StrLower(fileExt))
}

IsDirectory(path) {
    return FileExist(path) && InStr(FileExist(path), "D")
}

; 파일명에서 확장자 제거하는 도우미
GetFileNameNoExt(filename) {
    SplitPath, filename,,,, nameNoExt
    return nameNoExt
}

; 파일 또는 폴더 삭제 함수 (비어있는 폴더만 삭제 가능)
; 성공 시 true, 실패 시 false 반환
DeleteItem(path, force := false) {
    if (!FileExist(path))
        return false

    isDir := InStr(FileExist(path), "D")

    if (isDir) {
        ; force가 true면 재귀적으로 폴더 삭제
        if (force) {
            FileRemoveDir, %path%, 1  ; 1 = 내용 포함 삭제
        } else {
            FileRemoveDir, %path%
        }
        return (ErrorLevel = 0)
    } else {
        FileDelete, %path%
        return !FileExist(path)
    }
}


GetContainingFolder(path) {
    if (FileExist(path) ~= "D")  ; Directory
        return RTrim(path, "\")
    else {
        SplitPath, path,, dir
        return dir
    }
}

IsAbsolutePath(path) {
    return RegExMatch(path, "i)^[a-z]:\\|^\\\\")  ; C:\ or \\network\
}


ReadFile(path) {
    FileRead, content, %path%
    if (ErrorLevel) {
        return false
    }
    return content
}