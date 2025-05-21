global proc := "msedge.exe"

F1::
Run, %proc%
WinWait, ahk_exe %proc%, , 5
WinWaitActive, ahk_exe %proc%
;WinMaximize, ahk_exe %proc%

return
F2::
    WinRestore, ahk_exe msedge.exe
    WinActivate, ahk_exe %proc%
    WinMove, ahk_exe %proc%,, 400, 200
    WinMaximize, ahk_exe %proc% 
Return


F3::
    WinActivate, ahk_exe %proc%
    WinMaximize, ahk_exe %proc% 
Return

F4::
    WinActivate, ahk_exe %proc%
    WinRestore, ahk_exe msedge.exe
Return