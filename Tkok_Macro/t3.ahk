ExecSingleCommand2(command, vars) {
    test(command, vars)
    if RegExMatch(command, "i)^Click:(\w+),\s*(\d+),\s*(\d+)$", m) {
        Click(m2,m3,m1)
        test("1")
    } else if RegExMatch(command, "i)^Click:(\w+),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)$", m) {
        ClickRatio(m2,m3,m1)
        test("2")
    } else if RegExMatch(command, "i)^Send\s*,\s*(.*)$", m) {
        Send, {Blind}%m1% 
    } else if RegExMatch(command, "i)^Chat\s*,\s*(.*)$", m) {
        Chat(m1)
    } else if RegExMatch(command, "i)^(Sleep|Wait)\s*,?\s*(\d*)", m) {
        if(isDigit(m2))
            vars.wait += m2
    } else if RegExMatch(command, "i)^(.+\.txt)$", m) {
        ExecMacroFile(m1, vars)
    } else if RegExMatch(command, "^([a-zA-Z0-9_]+)\s*\((.*)\)\s*$", m) {
        ExecFunc(m1, m2)
    } else {
        if(command != "")
            ShowTip("경고, 올바른 명령문이 아님 `nCmd: "command "`nLen: " StrLen(command), 4000)
    }
}
t:="Click:L, 0.229, 0.272"
t2:="Click:L, 1, 1"
vars := {}
ExecSingleCommand2(t2,vars)
#Include, lib/commonutils.ahk
#Include, src/macroexec.ahk
