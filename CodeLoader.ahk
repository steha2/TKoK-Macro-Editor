global isLaunchedByMain := true

#Include %A_ScriptDir%\src\CommonSetting.ahk 

#Include %A_ScriptDir%\src\InitCodeLoader.ahk 
#Include %A_ScriptDir%\MacroEditor.ahk

#Include %A_ScriptDir%\src\CodeLoaderEvents.ahk
#Include %A_ScriptDir%\src\TKoK_Funcs.ahk
#Include %A_ScriptDir%\src\War3Funcs.ahk

#Include %A_ScriptDir%\lib\LibIncludes.ahk

#Include %A_ScriptDir%\lib\Gdip_All.ahk

ExitRoutine:
Gdip_Shutdown(pToken)
ExitApp