#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
a:=0
while(i<3) {
    i++
    a++
    MsgBox, % i " " a
}

MsgBox, % a
ExitApp