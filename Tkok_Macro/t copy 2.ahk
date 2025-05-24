GetMonitorSize(hwnd, ByRef w, ByRef h) {
    MONITOR_DEFAULTTONEAREST := 2
    hMonitor := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", MONITOR_DEFAULTTONEAREST, "Ptr")

    VarSetCapacity(mi, 40)
    NumPut(40, mi, 0, "UInt")
    DllCall("GetMonitorInfo", "Ptr", hMonitor, "Ptr", &mi)

    left   := NumGet(mi, 4, "Int")
    top    := NumGet(mi, 8, "Int")
    right  := NumGet(mi, 12, "Int")
    bottom := NumGet(mi, 16, "Int")

    w := right - left
    h := bottom - top
}

m := WinExist("ahk_exe notepad.exe")
GetMonitorSize(m,w,h)
test(m,w,h)

#Include, lib/commonUtils.ahk