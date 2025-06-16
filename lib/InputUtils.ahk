PhysClick(x, y, btn := "L") {
    PhysMouseInput(x, y, btn)
}

PhysMouseInput(x, y, btn := "L") {
    MouseMove, %x%, %y%, 100
    if(!btn)
        return

    baseBtn := SubStr(btn, 1, 1)   ; L or R
    isDown  := InStr(btn, "D")
    isUp    := InStr(btn, "U")
    isClick := !(isDown || isUp)  ; 기본 클릭

    Sleep(60)
    if (baseBtn = "R") {
        if (isDown || isClick)
            DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
        if (isUp || isClick) {
            Sleep(45)
            DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
        }
    } else { ; Left
        if (isDown || isClick)
            DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
        if (isUp || isClick) {
            Sleep(45)
            DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
        }
    }
}
