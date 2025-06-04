#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
GetLeafDir(path) {
    if (FileExist(path) ~= "D")  ; Directory
        return RTrim(path, "\")
    else {
        SplitPath, path,, dir
        return dir
    }
}

a := "C:\ahk\c.txt"

MsgBox, % GetLeafDir(a)
