;-------------------------------- 마우스 함수 --------------------------------

ClipWindow(force := false) {
    if (!force && IsMouseClipped()) {
        DllCall("ClipCursor", "Ptr", 0)
        isMouseClipped := false
        return
    }

    WinGet, hwnd, ID, A
    ; 클라이언트 좌표 및 크기 구하기
    VarSetCapacity(rect, 16, 0)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
    DllCall("ClientToScreen", "ptr", hwnd, "ptr", &rect)

    x1 := NumGet(rect, 0, "Int")
    y1 := NumGet(rect, 4, "Int")
    x2 := x1 + NumGet(rect, 8, "Int")  ; width
    y2 := y1 + NumGet(rect, 12, "Int") ; height

    ClipCursor(x1, y1, x2, y2)
    isMouseClipped := true
}

ClipCursor(x1 := "", y1 := "", x2 := "", y2 := "") {
    if (x1 = "") {
        DllCall("ClipCursor", "Ptr", 0)  ; 해제
    } else {
        VarSetCapacity(rect, 16, 0)
        args := x1 . "|" . y1 . "|" . x2 . "|" . y2
        Loop, Parse, args, |
            NumPut(A_LoopField, &rect, (a_index - 1) * 4)
        DllCall("ClipCursor", "Str", rect)
	}
}

IsMouseClipped() {
    VarSetCapacity(rc, 16, 0)
    success := DllCall("GetClipCursor", "Ptr", &rc)

    ; 데스크톱 전체 영역 구하기
    SysGet, VirtualScreenLeft, 76
    SysGet, VirtualScreenTop, 77
    SysGet, VirtualScreenRight, 78
    SysGet, VirtualScreenBottom, 79

    screenLeft := VirtualScreenLeft
    screenTop := VirtualScreenTop
    screenRight := VirtualScreenRight
    screenBottom := VirtualScreenBottom

    ; 클립 영역이 전체 화면이면, 클립되지 않은 상태
    left   := NumGet(rc, 0, "Int")
    top    := NumGet(rc, 4, "Int")
    right  := NumGet(rc, 8, "Int")
    bottom := NumGet(rc, 12, "Int")

    if (left = screenLeft && top = screenTop && right = screenRight && bottom = screenBottom)
        return false
    else
        return true
}

Click(x, y, btn := "L", coordMode := "", delay := 10) {
    isClient := !InStr(coordMode,"screen")
    isRatio := !InStr(coordMode,"fixed")

    CoordMode, Mouse, % isClient ? "Client" : "Screen"
    
    if(isRatio){
        if(isClient) {
            GetClientSize("A", w, h)
        }
        x := Round(x * w)
        y := Round(y * h)
    }

    MouseMove, %x%, %y%
    Sleep, delay
    ; 우클릭일 경우
    if (btn == "R" || btn == false) {
        ; 우클릭: 0x08 (Down), 0x10 (Up)
        DllCall("mouse_event", "UInt", 0x08, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Down
        Sleep, delay
        DllCall("mouse_event", "UInt", 0x10, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Right Up
    } else {
        ; 좌클릭: 0x02 (Down), 0x04 (Up)
        DllCall("mouse_event", "UInt", 0x02, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Down
        Sleep, delay
        DllCall("mouse_event", "UInt", 0x04, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0) ; Left Up
    }
    Sleep, delay
}
; ------------------------------- 화면 함수 ---------------------------------

IsAllowedWindow(target) {
    if (target = "")  
        return true
    else if (IsTargetWindow(target))
        return true
    else 
        return ActivateWindow(target) 
}

IsTargetWindow(target, hwnd := "A") {
    if (target = "")
        return false

    hwnd := (hwnd = "A") ? WinExist("A") : hwnd
    if (!hwnd)
        return false

    WinGetTitle, title, ahk_id %hwnd%
    WinGetClass, class, ahk_id %hwnd%
    WinGet, exe, ProcessName, ahk_id %hwnd%

    return InStr(title, target, false) || InStr(class, target, false) || InStr(exe, target, false)
}

ActivateWindow(target) {
    if (target = "")
        return false

    targetClass := "ahk_class " . target
    ; 2. ahk_class 로 시도 
    if WinExist(targetClass) {
        WinActivate, %targetClass%
        return WinActive(targetClass)
    }

    targetExe := "ahk_exe" . target . ".exe"
    if WinExist(targetExe) {
        WinActivate, %targetExe%
        return WinActive(targetExe)
    }

    ; 4. 마지막으로 title에 포함된 창 찾기
    if WinExist(target) {
        WinActivate, %target%
        return WinActive(target)
    }

    ShowTip("대상 창을 활성화 할 수 없습니다.`n`nTarget : "  target)
    return false
}

GetClientSize(hwnd := "A", ByRef w := "", ByRef h := "") {
    if (!hwnd || hwnd = "A")
        WinGet, hwnd, ID, A

    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect)
    w := NumGet(rect, 8, "int")
    h := NumGet(rect, 12, "int")
}

GetMouseRatio(ByRef ratioX, ByRef ratioY, hwnd := "A") {
    ; hwnd 생략 시 활성 창 사용
    if (hwnd = "A")
        WinGet, hwnd, ID, A

    GetClientSize(hwnd, w, h)

    ; 유효성 검사
    if (!w || !h || w < 10 || h < 10) {
        ratioX := -1
        ratioY := -1
        Showtip("오류, 클라이언트 영역 크기를 가져오지 못했거나 유효하지 않습니다.`n창 크기: width : " w " height : " h)
        return false
    }

    ; 마우스 좌표 (클라이언트 기준)
    MouseGetPos, x, y, , , 2

    ; 비율 계산
    ratioX := Round(x / w, 3)
    ratioY := Round(y / h, 3)
    return true
}


; ----------- 입력 및 컨트롤 함수 -----------

Chat(text) {
    SendKey("{Enter}",100)
    Suspend, On
    SendRaw, %text%
    Suspend, Off
    SendKey("{Enter}")
}

;dealy :음/양수 선/후 딜레이
SendKey(key, delay := 0, ignoreSpace := false) {
    if (delay < 0)
        Sleep, -delay

    if (ignoreSpace)
        key := StrReplace(key, " ")

    Send, {Blind}%key%

    if (delay > 0)
        Sleep, delay
}

ShowTip(msg, duration := 1500) {
    Tooltip, %msg%
    SetTimer, RemoveToolTip, -%duration%
    return
}

RemoveToolTip() {
    ToolTip
}

; --------------------------- 파일 함수 -----------------------------------

GetIniValue(section, key, default := "") {
    IniRead, val, % CONFIG_FILE, %section%, %key%, %default%
    return Trim(val)
}

SetIniValue(section, key, value) {
    IniWrite, % value, % CONFIG_FILE, %section%, %key%
}

;return latest := {path: "", name: "", time: 0}
GetLatestFile(folderPath, filePattern := "*", nameRegex := "") {
    latest := {path: "", name: "", time: 0}

    Loop, Files, %folderPath%\%filePattern%
    {
        ; 정규식 필터 조건이 있으면 검사
        if (nameRegex != "" && !RegExMatch(A_LoopFileName, nameRegex))
            continue

        ; 가장 최근 수정 시간의 파일 갱신
        if (A_LoopFileTimeModified > latest.time) {
            latest := {path: A_LoopFileFullPath, name: A_LoopFileName, time: A_LoopFileTimeModified}
        }
    }
    return latest
}

IsFile(path) {
    return FileExist(path) && !InStr(FileExist(path), "D")
}

IsDirectory(path) {
    return FileExist(path) && InStr(FileExist(path), "D")
}

; 파일 또는 폴더 삭제 함수 (비어있는 폴더만 삭제 가능)
; 성공 시 true, 실패 시 false 반환
DeleteItem(path) {
    if (!FileExist(path))
        return false

    isDir := InStr(FileExist(path), "D")

    if (isDir) {
        ; 비어있는 폴더만 삭제
        FileRemoveDir, %path%
        return (ErrorLevel = 0)  ; 성공하면 0, 실패하면 1
    } else {
        FileDelete, %path%
        return !FileExist(path)  ; 삭제 성공 여부 반환
    }
}


; --------------------------------- 문자 함수 ---------------------------------
StrCompare(a, b) {
    StringLower, aLower, a
    StringLower, bLower, b
    return aLower = bLower
}

global logFilePath :=  A_Temp "\macro_test_log.txt"
test(a := "", b := "", c := "", d := "", e := "", f := "", isTip := false, writeLog := true) {
    args := [a, b, c, d, e, f]
    output := ""
    for index, value in args {
        if (value != "")  ; ← 수정: a가 아니라 value 기준 체크해야 함
            output .= "Arg" index " : " FormatValue(value) "`n`n"
    }
    
    if (writeLog) {
        FileAppend, % output, % logFilePath
    }

    if (isTip)
        ShowTip(output)
    else
        MsgBox, % output
}

FormatValue(val) {
    if IsObject(val) {
        out := "[Object] {"
        for k, v in val {
            out .= k ": " v ", "
        }
        return Trim(out, ", ") . "}"
    } else {
        return "[Value] " val
    }
}

OpenLogFile() {
    if FileExist(logFilePath)
        Run, notepad.exe "%logFilePath%"
    else
        MsgBox, 로그 파일이 없습니다.
}

test2(a="", b="", c="", d="", e="", f="",isTip:=true,isLog:=true) {
    test(a,b,c,d,e,f,isTip,isLog)
}

;주석제거
StripComments(line) {
    commentPos := InStr(line, ";")
    if (commentPos)
        line := SubStr(line, 1, commentPos - 1)

    line := Trim(line, "`r`n`t ")
    return line
}

TrimLastToken(str, delim) {
    ; 마지막 구분자 위치 찾기 (뒤에서부터)
    lastDelimPos := InStr(str, delim, false, 0)
    if (lastDelimPos)
        return SubStr(str, 1, lastDelimPos - 1)
    else
        return ""  ; 구분자가 없으면 빈 문자열
}

;배열을 구분자를 넣어 합친다
StrJoin(arr, delim := "`n") {
    out := ""
    for i, v in arr {
        if (i > 1)
            out .= delim
        out .= v
    }
    return out
}

;----------------------------------------------객체 함수-----------------------------------------------

ToKeyLengthSortedArray(object) {
    ; 복사본 생성
    copied := {}
    for k, v in object
        copied[k] := v

    arr := ObjectToArray(copied)
    count := arr.Length()
    Loop, % count {
        Loop, % count - A_Index {
            i := A_Index
            if (StrLen(arr[i].key) < StrLen(arr[i+1].key)) {
                temp := arr[i]
                arr[i] := arr[i+1]
                arr[i+1] := temp
            }
        }
    }
    return arr
}

ArrayToObject(arr) {
    obj := {}
    for index, item in arr
        obj[item.key] := item.value
    return obj
}

ObjectToArray(obj) {
    arr := []
    for k, v in obj {
        arr.Push({key: k, value: v})
    }
    return arr
}

;----------------------------------------------숫자 함수-----------------------------------------------
CleanFormat(num) {
    str := Format("{:0.3f}", num)
    str := RegExReplace(str, "0+$", "")
    str := RegExReplace(str, "\.$", "")
    return  str
}

FormatDecimal(num, mode) {
    if (mode = "trim") {
        return CleanFormat(num)
    } else if (mode = "fixed") {
        return Format("{:0.3f}", num)
    } else if (mode = "round") {
        return Round(num, 3)
    } else if (RegExMatch(mode, "^round(-?\d+)$", m)) {
        return Round(num, m1 + 0)
    } else if (mode = "floor") {
        return Floor(num)
    } else if (mode = "ceil") {
        return Ceil(num)
    } else if (mode = "none") {
        return num
    }
    return false
}

;a.delay += b
AddDelay(a, b) {
   ;msgBox, % isDigit(b) "  " (b + a)
    if isDigit(b) {
        a.delay += b
        ;MsgBox,  % a.delay
    }
}

; 숫자(정수 또는 소수)인지 검사

; 시간차를 h m s 형식으로 포맷
FormatTimeDiff(seconds) {
    hours := Floor(seconds / 3600)
    minutes := Floor(Mod(seconds, 3600) / 60)
    secs := Mod(seconds, 60)
    return Format("{:02d}h {:02d}m {:02d}s", hours, minutes, secs)
}

isDigit(val) {
    return !!RegExMatch(val, "^\s*-?\d+(\.\d+)?\s*$")
}
isNatural(n) {
    return RegExMatch(n, "^\d+$") && (n >= 1)
}
IsInteger(val) {
    return val is integer
}

Eval(x) {                              ; non-recursive PRE/POST PROCESSING: I/O forms, numbers, ops, ";"
   Local FORM, FormF, FormI, i, W, y, y1, y2, y3, y4
   FormI := A_FormatInteger, FormF := A_FormatFloat

   SetFormat Integer, D                ; decimal intermediate results!
   RegExMatch(x, "\$(b|h|x|)(\d*[eEgG]?)", y)
   FORM := y1, W := y2                 ; HeX, Bin, .{digits} output format
   SetFormat FLOAT, 0.16e              ; Full intermediate float precision
   StringReplace x, x, %y%             ; remove $..
   Loop
      If RegExMatch(x, "i)(.*)(0x[a-f\d]*)(.*)", y)
         x := y1 . y2+0 . y3           ; convert hex numbers to decimal
      Else Break
   Loop
      If RegExMatch(x, "(.*)'([01]*)(.*)", y)
         x := y1 . Eval_FromBin(y2) . y3    ; convert binary numbers to decimal: sign = first bit
      Else Break
   x := RegExReplace(x,"(^|[^.\d])(\d+)(e|E)","$1$2.$3") ; add missing '.' before E (1e3 -> 1.e3)
                                       ; literal scientific numbers between  and  chars
   x := RegExReplace(x,"(\d*\.\d*|\d)([eE][+-]?\d+)","$1$2")

   StringReplace x, x,`%, \, All       ; %  -> \ (= MOD)
   StringReplace x, x, **,@, All       ; ** -> @ for easier process
   StringReplace x, x, +, ą, All       ; ą is addition
   x := RegExReplace(x,"([^]*)ą","$1+") ; ...not inside literal numbers
   StringReplace x, x, -, Ź, All       ; Ź is subtraction
   x := RegExReplace(x,"([^]*)Ź","$1-") ; ...not inside literal numbers

   Loop Parse, x, `;
      y := Eval_1(A_LoopField)          ; work on pre-processed sub expressions
                                       ; return result of last sub-expression (numeric)
   If FORM = b                         ; convert output to binary
      y := W ? Eval_ToBinW(Round(y),W) : Eval_ToBin(Round(y))
   Else If (FORM="h" or FORM="x") {
      SetFormat Integer, Hex           ; convert output to hex
      y := Round(y) + 0
   }
   Else {
      W := W="" ? "0.6g" : "0." . W    ; Set output form, Default = 6 decimal places
      SetFormat FLOAT, %W%
      y += 0.0
   }
   SetFormat Integer, %FormI%          ; restore original formats
   SetFormat FLOAT,   %FormF%
   Return y
}

Eval_1(x) {                             ; recursive PREPROCESSING of :=, vars, (..) [decimal, no ";"]
   Local i, y, y1, y2, y3
                                       ; save function definition: f(x) := expr
   If RegExMatch(x, "(\S*?)\((.*?)\)\s*:=\s*(.*)", y) {
      f%y1%__X := y2, f%y1%__F := y3
      Return
   }
                                       ; execute leftmost ":=" operator of a := b := ...
   If RegExMatch(x, "(\S*?)\s*:=\s*(.*)", y) {
      y := "x" . y1                    ; user vars internally start with x to avoid name conflicts
      Return %y% := Eval_1(y2)
   }
                                       ; here: no variable to the left of last ":="
   x := RegExReplace(x,"([\).\w]\s+|[\)])([a-z_A-Z]+)","$1Ť$2ť")  ; op -> Ťopť

   x := RegExReplace(x,"\s+")          ; remove spaces, tabs, newlines

   x := RegExReplace(x,"([a-z_A-Z]\w*)\(","'$1'(") ; func( -> 'func'( to avoid atan|tan conflicts

   x := RegExReplace(x,"([a-z_A-Z]\w*)([^\w'ť]|$)","%x$1%$2") ; VAR -> %xVAR%
   x := RegExReplace(x,"([^]*)%x[eE]%","$1e") ; in numbers %xe% -> e
   x := RegExReplace(x,"|")          ; no more need for number markers
   Transform x, Deref, %x%             ; dereference all right-hand-side %var%-s

   Loop {                              ; find last innermost (..)
      If RegExMatch(x, "(.*)\(([^\(\)]*)\)(.*)", y)
         x := y1 . Eval_@(y2) . y3      ; replace (x) with value of x
      Else Break
   }
   Return Eval_@(x)
}

Eval_@(x) {                             ; EVALUATE PRE-PROCESSED EXPRESSIONS [decimal, NO space, vars, (..), ";", ":="]
   Local i, y, y1, y2, y3, y4

   If x is number                      ; no more operators left
      Return x
                                       ; execute rightmost ?,: operator
   RegExMatch(x, "(.*)(\?|:)(.*)", y)
   IfEqual y2,?,  Return Eval_@(y1) ? Eval_@(y3) : ""
   IfEqual y2,:,  Return ((y := Eval_@(y1)) = "" ? Eval_@(y3) : y)

   StringGetPos i, x, ||, R            ; execute rightmost || operator
   IfGreaterOrEqual i,0, Return Eval_@(SubStr(x,1,i)) || Eval_@(SubStr(x,3+i))
   StringGetPos i, x, &&, R            ; execute rightmost && operator
   IfGreaterOrEqual i,0, Return Eval_@(SubStr(x,1,i)) && Eval_@(SubStr(x,3+i))
                                       ; execute rightmost =, <> operator
   RegExMatch(x, "(.*)(?<![\<\>])(\<\>|=)(.*)", y)
   IfEqual y2,=,  Return Eval_@(y1) =  Eval_@(y3)
   IfEqual y2,<>, Return Eval_@(y1) <> Eval_@(y3)
                                       ; execute rightmost <,>,<=,>= operator
   RegExMatch(x, "(.*)(?<![\<\>])(\<=?|\>=?)(?![\<\>])(.*)", y)
   IfEqual y2,<,  Return Eval_@(y1) <  Eval_@(y3)
   IfEqual y2,>,  Return Eval_@(y1) >  Eval_@(y3)
   IfEqual y2,<=, Return Eval_@(y1) <= Eval_@(y3)
   IfEqual y2,>=, Return Eval_@(y1) >= Eval_@(y3)
                                       ; execute rightmost user operator (low precedence)
   RegExMatch(x, "i)(.*)Ť(.*?)ť(.*)", y)
   IfEqual y2,choose,Return Eval_Choose(Eval_@(y1),Eval_@(y3))
   IfEqual y2,Gcd,   Return Eval_GCD(   Eval_@(y1),Eval_@(y3))
   IfEqual y2,Min,   Return (y1:=Eval_@(y1)) < (y3:=Eval_@(y3)) ? y1 : y3
   IfEqual y2,Max,   Return (y1:=Eval_@(y1)) > (y3:=Eval_@(y3)) ? y1 : y3

   StringGetPos i, x, |, R             ; execute rightmost | operator
   IfGreaterOrEqual i,0, Return Eval_@(SubStr(x,1,i)) | Eval_@(SubStr(x,2+i))
   StringGetPos i, x, ^, R             ; execute rightmost ^ operator
   IfGreaterOrEqual i,0, Return Eval_@(SubStr(x,1,i)) ^ Eval_@(SubStr(x,2+i))
   StringGetPos i, x, &, R             ; execute rightmost & operator
   IfGreaterOrEqual i,0, Return Eval_@(SubStr(x,1,i)) & Eval_@(SubStr(x,2+i))
                                       ; execute rightmost <<, >> operator
   RegExMatch(x, "(.*)(\<\<|\>\>)(.*)", y)
   IfEqual y2,<<, Return Eval_@(y1) << Eval_@(y3)
   IfEqual y2,>>, Return Eval_@(y1) >> Eval_@(y3)
                                       ; execute rightmost +- (not unary) operator
   RegExMatch(x, "(.*[^!\~ąŹ\@\*/\\])(ą|Ź)(.*)", y) ; lower precedence ops already handled
   IfEqual y2,ą,  Return Eval_@(y1) + Eval_@(y3)
   IfEqual y2,Ź,  Return Eval_@(y1) - Eval_@(y3)
                                       ; execute rightmost */% operator
   RegExMatch(x, "(.*)(\*|/|\\)(.*)", y)
   IfEqual y2,*,  Return Eval_@(y1) * Eval_@(y3)
   IfEqual y2,/,  Return Eval_@(y1) / Eval_@(y3)
   IfEqual y2,\,  Return Mod(Eval_@(y1),Eval_@(y3))
                                       ; execute rightmost power
   StringGetPos i, x, @, R
   IfGreaterOrEqual i,0, Return Eval_@(SubStr(x,1,i)) ** Eval_@(SubStr(x,2+i))
                                       ; execute rightmost function, unary operator
   If !RegExMatch(x,"(.*)(!|ą|Ź|~|'(.*)')(.*)", y)
      Return x                         ; no more function (y1 <> "" only at multiple unaries: --+-)
   IfEqual y2,!,Return Eval_@(y1 . !y4) ; unary !
   IfEqual y2,ą,Return Eval_@(y1 .  y4) ; unary +
   IfEqual y2,Ź,Return Eval_@(y1 . -y4) ; unary - (they behave like functions)
   IfEqual y2,~,Return Eval_@(y1 . ~y4) ; unary ~
   If IsLabel(y3)
      GoTo %y3%                        ; built-in functions are executed last: y4 is number
   Return Eval_@(y1 . Eval_1(RegExReplace(f%y3%__F, f%y3%__X, y4))) ; user defined function
Abs:
   Return Eval_@(y1 . Abs(y4))
Ceil:
   Return Eval_@(y1 . Ceil(y4))
Exp:
   Return Eval_@(y1 . Exp(y4))
Floor:
   Return Eval_@(y1 . Floor(y4))
Log:
   Return Eval_@(y1 . Log(y4))
Ln:
   Return Eval_@(y1 . Ln(y4))
Round:
   Return Eval_@(y1 . Round(y4))
Sqrt:
   Return Eval_@(y1 . Sqrt(y4))
Sin:
   Return Eval_@(y1 . Sin(y4))
Cos:
   Return Eval_@(y1 . Cos(y4))
Tan:
   Return Eval_@(y1 . Tan(y4))
ASin:
   Return Eval_@(y1 . ASin(y4))
ACos:
   Return Eval_@(y1 . ACos(y4))
ATan:
   Return Eval_@(y1 . ATan(y4))
Sgn:
   Return Eval_@(y1 . (y4>0)) ; Sign of x = (x>0)-(x<0)
Fib:
   Return Eval_@(y1 . Eval_Fib(y4))
Fac:
   Return Eval_@(y1 . Eval_Fac(y4))
}

Eval_ToBin(n) {      ; Binary representation of n. 1st bit is SIGN: -8 -> 1000, -1 -> 1, 0 -> 0, 8 -> 01000
   Return n=0||n=-1 ? -n : Eval_ToBin(n>>1) . n&1
}
Eval_ToBinW(n,W=8) { ; LS W-bits of Binary representation of n
   Loop %W%     ; Recursive (slower): Return W=1 ? n&1 : ToBinW(n>>1,W-1) . n&1
      b := n&1 . b, n >>= 1
   Return b
}
Eval_FromBin(bits) { ; Number converted from the binary "bits" string, 1st bit is SIGN
   n = 0
   Loop Parse, bits
      n += n + A_LoopField
   Return n - (SubStr(bits,1,1)<<StrLen(bits))
}

Eval_GCD(a,b) {      ; Euclidean GCD
   Return b=0 ? Abs(a) : Eval_GCD(b, mod(a,b))
}
Eval_Choose(n,k) {   ; Binomial coefficient
   p := 1, i := 0, k := k < n-k ? k : n-k
   Loop %k%                   ; Recursive (slower): Return k = 0 ? 1 : Choose(n-1,k-1)*n//k
      p *= (n-i)/(k-i), i+=1  ; FOR INTEGERS: p *= n-i, p //= ++i
   Return Round(p)
}

Eval_Fib(n) {        ; n-th Fibonacci number (n < 0 OK, iterative to avoid globals)
   a := 0, b := 1
   Loop % abs(n)-1
      c := b, b += a, a := c
   Return n=0 ? 0 : n>0 || n&1 ? b : -b
}
Eval_fac(n) {        ; n!
   Return n<2 ? 1 : n*Eval_fac(n-1)
}
