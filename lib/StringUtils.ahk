; --------------------------------- 문자 함수 ---------------------------------

RemoveChars(text, chars) {
    Loop, Parse, text
        text := StrReplace(text, A_LoopField)
    return text
}


StrCompare(a, b) {
    StringLower, aLower, a
    StringLower, bLower, b
    return aLower = bLower
}
;주석제거
StripComments(line) {
    commentPos := InStr(line, ";")
    if (commentPos)
        line := SubStr(line, 1, commentPos - 1)

    line := Trim(line, "`r`n`t ")
    return line
}

Dummy(str, placeHolder) {
    dummy := ""
    Loop, % StrLen(str)
        dummy .= placeHolder
    return dummy
}

HasValue(arr, val) {
    if (!IsObject(arr))
        return (arr = val)
    for _, v in arr
        if (v = val)
            return true
    return false
}

TrimLastToken(str, delim) {
    ; 마지막 구분자 위치 찾기 (뒤에서부터)
    lastDelimPos := InStr(str, delim, false, 0)
    if (lastDelimPos)
        return SubStr(str, 1, lastDelimPos - 1)
    else
        return ""  ; 구분자가 없으면 빈 문자열
}

GetLastPart(str, delim) {
    parts := StrSplit(str, delim)
    return parts[parts.MaxIndex()]
}

AppendExt(ByRef path, ext := "txt") {
    if !RegExMatch(path, "i)\." . ext . "$")
        path .= "." . ext
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

SplitLine(scriptText) {
    return StrSplit(scriptText, ["`r`n", "`n", "`r"])
}

TryStringLogic(expr) {
    expr := Trim(expr)
    ; 논리 반전 (!)
    flip := false
    if (SubStr(expr, 1, 1) = "!") {
        expr := SubStr(expr, 2)
        flip := true
    }
    ; 비교 연산
    result := ""
    if InStr(expr, "!=") {
        parts := StrSplit(expr, "!=", , 2)
        result := (Trim(parts[1]) != Trim(parts[2]))
    } else if InStr(expr, "~=") {
        parts := StrSplit(expr, "~=", , 2)
        result := (Trim(parts[1]) ~= Trim(parts[2]))
    } else if InStr(expr, "=") {
        parts := StrSplit(expr, "=", , 2)
        result := (Trim(parts[1]) = Trim(parts[2]))
    } else {
        ; 일반 문자열 존재 여부
        result := (expr != "")
    }
    return flip ? !result : result
}

JoinLines(arr) {
    return arr.Length() ? arr.Join("`r`n") . "`r`n" : ""
}

ExtractVar(vars, key, ByRef outVar, type := "") {
    if (!vars.HasKey(key))
        return

    val := vars[key]
    vars.Delete(key)
    switch type {
        case "integer":
            outVar := Floor(val + 0)
        case "natural":
            val := Floor(val + 0)
            outVar := (val > 0) ? val : 1
        case "nat0", "whole":
            val := Floor(val + 0)
            outVar := (val >= 0) ? val : 0
        case "number":
            outVar := val + 0
        case "string":
            outVar := val . ""
        case "boolean":
            outVar := (val = "true" || val = 1 || val = "1") ? true : false
        default:
            outVar := val
    }
}

StrLower(text) {
    StringLower, out, text
    return out
}

;----------------------------------------------객체 함수-----------------------------------------------

ToKeyLengthSortedArray(object, ascending := false) {
    arr := ObjectToArray(object)
    count := arr.Length()
    Loop, % count {
        Loop, % count - A_Index {
            i := A_Index
            len1 := StrLen(arr[i].key)
            len2 := StrLen(arr[i+1].key)
            if (ascending ? (len1 > len2) : (len1 < len2)) {
                temp := arr[i]
                arr[i] := arr[i+1]
                arr[i+1] := temp
            }
        }
    }
    return arr
}



ObjectToArray(obj) {
    arr := []
    for k, v in obj {
        arr.Push({key: k, value: v})
    }
    return arr
}

ArrayToObject(arr) {
    obj := {}
    for index, item in arr
        obj[item.key] := item.value
    return obj
}