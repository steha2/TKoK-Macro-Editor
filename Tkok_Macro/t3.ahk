if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

^u::
Click(0.976, 0.879, "R")
return

#Include, LibIncludes.ahk
