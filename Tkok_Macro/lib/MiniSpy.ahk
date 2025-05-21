#NoEnv
#NoTrayIcon
#SingleInstance Ignore
SetBatchLines, -1
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"  ; 관리자 권한으로 재실행
    ExitApp
}

global hGui

Gui, New, hwndhGui AlwaysOnTop Resize MinSize
Gui, Font, s14, Consolas
Gui, Add, Text,, Mouse Position:
Gui, Add, Edit, w520 r3 ReadOnly vCtrl_MousePos
Gui, Add, Text,, Active Window Position:
Gui, Add, Edit, w520 r2 ReadOnly vCtrl_Pos
Gui, Add, Text,, Saved Client Ratios:`n(Shift+Space:save, Crtl+Space:clear)
Gui, Add, Edit, w520 h300 ReadOnly vCtrl_SavedRatio
Gui, Show, NoActivate, Minimal Window Spy

SetTimer, Update, 250
return

Update:
MouseGetPos, msX, msY, msWin, msCtrl
actWin := WinExist("A")

; Window Info
WinGetPos, wX, wY, wW, wH, ahk_id %actWin%
GetClientSize(actWin, wcW, wcH)

; Mouse Position (Client 기준)
CoordMode, Mouse, Client
MouseGetPos, mcX, mcY
CoordMode, Mouse, Screen

SysGet, screenW, 78
SysGet, screenH, 79
global ratioScreenX := Round(msX / screenW, 3)
global ratioScreenY := Round(msY / screenH, 3)
global ratioClientX := (wcW > 0) ? Round(mcX / wcW, 3) : 0
global ratioClientY := (wcH > 0) ? Round(mcY / wcH, 3) : 0

UpdateText("Ctrl_MousePos", "Screen:`t" msX ", " msY " (" ratioScreenX ", " ratioScreenY ")`n"
	. "Client:`t" mcX ", " mcY " (" ratioClientX ", " ratioClientY ")")

UpdateText("Ctrl_Pos", "Active:`tx: " wX "`ty: " wY "`tw: " wW "`th: " wH "`nClient:`tw: " wcW "`th: " wcH)
return

+Space::UpdateText("Ctrl_SavedRatio", ratioClientX . "," . ratioClientY, true)
^Space::UpdateText("Ctrl_SavedRatio","")

^+r::Reload

GuiClose:
ExitApp

UpdateText(ControlID, NewText, append := false)
{
	if (append)
	{
		GuiControlGet, prevText, %hGui%:, %ControlID%
		if (prevText = "")
			updatedText := NewText
		else
			updatedText := prevText . "`n" . NewText
		GuiControl, %hGui%:, %ControlID%, %updatedText%
	}
	else
	{
		GuiControl, %hGui%:, %ControlID%, %NewText%
	}
}


GetClientSize(hWnd, ByRef w := "", ByRef h := "")
{
	VarSetCapacity(rect, 16)
	DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
	w := NumGet(rect, 8, "int")
	h := NumGet(rect, 12, "int")
}
