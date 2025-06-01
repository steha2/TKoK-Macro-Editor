#SingleInstance
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

tempVarsList := []
tempVarsList.Push({})                              ; 아무 키도 없음
tempVarsList.Push({if: ""})                        ; 빈 문자열
tempVarsList.Push({if: 0})                         ; 숫자 0
tempVarsList.Push({if: "0"})                       ; 문자열 "0"
tempVarsList.Push({if: 1})                         ; 숫자 1
tempVarsList.Push({if: "abc"})                     ; 문자열
tempVarsList.Push({if: false})                     ; 불리언 false
tempVarsList.Push({if: true})                      ; 불리언 true
tempVarsList.Push({if: "false"})                   ; 문자열 "false"
tempVarsList.Push({if: " "})                       ; 공백 문자열
tempVarsList.Push({if: "   "})                     ; 공백만 있는 문자열

for index, tempVars in tempVarsList {
    ; 조건 검사
    if (!tempVars.HasKey("force") && tempVars.HasKey("if") && tempVars.if = 0) {
        result := "CONTINUE"
    } else {
        result := "EXECUTE"
    }

    MsgBox % "Test " index "`n" 
            . "if: [" tempVars["if"] "]`n"
            . "Result: " result
}

F2::
return

#Include, LibIncludes.ahk

^r:: reload
