#SingleInstance
global vars := {}

testCases1 := ["3", "7*2", "5+5", "hello", "9-", "3.5", "a+b", ""]

testCases := ["3*+*3", "7*2", ""]
for index, val in testCases {
    vars.abc := val
    ;test(vars.abc ,val)
    input := "chat, %abc+2|10%"
    output := ResolveExpr(input, vars)
    ;MsgBox, 64, Test #%index%, abc := "%val%"`nResult := %output%
}
; MsgBox, %a%

t1 := "test2.txt #a:1# #abc:1000# #c:2# #d:3#"

t2:=ParseLine(t1,vars)

t3 := "chat, test2 %abc+d|10%"

t4 := ResolveExpr(t3,vars)

test(t1,t2,t3,t4,vars)

; 정렬 함수 정의 (내림차순)
#Include, resources/commonfuncs.ahk
#Include, resources/MacroExecFuncs.ahk

vars := { "short": "1a", "longerKey": "2a", "veryVeryLongKeyName": "3a" }

vars := ToKeyLengthSortedArray(vars)

Loop, % vars.Length() {
    item := vars[A_Index]
    ; msgbox, % item.key " " item.value
}