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
    } else if (RegExMatch(mode, "^fixed(\d+)$", m)) {
        digits := m1 + 0
        return Format("{:0." digits "f}", num)
    } else if (mode = "floor") {
        return Floor(num)
    } else if (mode = "ceil") {
        return Ceil(num)
    } else {
        return num
    }
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

IsDigit(val) {
    return !!RegExMatch(val, "^\s*-?\d+(\.\d+)?\s*$")
}
IsNatural(n) {
    return RegExMatch(n, "^\d+$") && (n >= 1)
}
IsInteger(val) {
    return val is integer
}


TryEval(expr, dp_mode := "trim") {
    if RegExMatch(expr, "^[\d+\-*/.() <>=!&|^~]+$") && RegExMatch(expr, "\d") {
        ;test("EVAL!",expr,mode,FormatDecimal(Eval(expr), mode))
        return FormatDecimal(Eval(expr), dp_mode)
    } else {
        return expr
    }
}

ForceEval(expr, dp_mode := "trim") {
    ; 변수/심볼 제거: 알파벳으로 시작하는 단어를 제거
    ; 단, 숫자나 연산자 등은 유지
    expr := RegExReplace(expr, "\b[A-Za-z_]\w*\b", "")
    ; 공백 정리
    expr := RegExReplace(expr, "\s+", "")
    
    return TryEval(expr, dp_mode)
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
