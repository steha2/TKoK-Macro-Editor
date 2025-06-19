global isLaunchedByMain := true
; Start gdi+
if !pToken := Gdip_Startup() {
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit

global load_with := ""

;CaptureImage(100, 100, 200, 200, "c:\capture.png")

#Include %A_ScriptDir%\src\CommonSetting.ahk 

#Include %A_ScriptDir%\src\Gui_CodeLoader.ahk 
#Include %A_ScriptDir%\MacroEditor.ahk

#Include %A_ScriptDir%\src\Input_Sender.ahk
#Include %A_ScriptDir%\src\Events_CodeLoader.ahk
#Include %A_ScriptDir%\src\TKoK_Funcs.ahk
#Include %A_ScriptDir%\src\War3Funcs.ahk
#Include %A_ScriptDir%\src\ExtractHeroName.ahk
#Include %A_ScriptDir%\src\CoordConverter.ahk 

#Include %A_ScriptDir%\lib\LibIncludes.ahk

#Include %A_ScriptDir%\lib\Gdip_All.ahk

Exit:
; gdi+ may now be shutdown on exiting the program
Gdip_Shutdown(pToken)
ExitApp