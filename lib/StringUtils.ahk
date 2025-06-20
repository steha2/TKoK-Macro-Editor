﻿; --------------------------------- 문자 함수 ---------------------------------

RemoveChars(text, chars) {
    Loop, Parse, chars
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

ExtractQuotedStrings(ByRef str) {
    placeholder := Chr(0xE100)
    map := {}
    pos := 1
    while (found := RegExMatch(str, """([^""]*)""", m, pos)) {
        key := placeholder . pos
        map[key] := m1
        pos := found
        str := SubStr(str, 1, pos-2) . key . SubStr(str, pos + StrLen(m))
    }
    return map
}

RestoreQuotedStrings(str, map) {
    for k, v in map
        str := StrReplace(str, k, v)
    return str
}

IsInArray(arr, val) {
    for each, item in arr
        if (item = val)
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

UnescapeLiteral(str) {
    ; AHK escape 문자 처리
    str := StrReplace(str, placeHolder, ",")  ; 줄바꿈
    str := StrReplace(str, "``n", "`n")  ; 줄바꿈
    str := StrReplace(str, "``r", "`r")  ; 캐리지리턴
    str := StrReplace(str, "``t", "`t")  ; 탭
    str := StrReplace(str, "``", "`")   ; 백틱 자체
    return str
}

RemoveExtension(str) {
    ; 마지막 점 위치 찾기 (확장자 시작 지점)
    lastDotPos := InStr(str, ".", false, 0)
    if (lastDotPos && lastDotPos > InStr(str, "\", false, 0)) ; 마지막 \ 이후에 점이 있는 경우만
        return SubStr(str, 1, lastDotPos - 1)
    else
        return str  ; 점이 없거나 디렉토리 경로에 있는 점만 있을 경우 원본 반환
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

TryStringLogic(expr, vars) {
    expr := Trim(expr)
    flip := false

    ; 논리 반전 (!)
    if (SubStr(expr, 1, 1) = "!") {
        expr := SubStr(expr, 2)
        flip := true
    }

    result := ""

      ; 사용자 정의 함수: has()
    if RegExMatch(expr, "^has\[(.+)\]$", m) {
        key := Trim(m1)
        result := vars.HasKey(key)
    } else if InStr(expr, "!=") {
        parts := StrSplit(expr, "!=", , 2)
        result := (Trim(parts[1]) != Trim(parts[2]))
    } else if InStr(expr, "~=") {
        parts := StrSplit(expr, "~=", , 2)
        result := (Trim(parts[1]) ~= Trim(parts[2]))
    } else if InStr(expr, " in ") {
        parts := StrSplit(expr, " in ", , 2)
        result := InStr(Trim(parts[2]), Trim(parts[1]), true)
    } else if InStr(expr, "=") {
        parts := StrSplit(expr, "=", , 2)
        result := (Trim(parts[1]) = Trim(parts[2]))
    } else {
        result := (expr != "")
    }
    result := flip ? !result : result
    Log("TryStringLogic() expr: " expr " result: " result)
    return result
}

in(val, list, delim := " ") {
    if (delim != "")
        return inlist(val, list, delim)
    else
        return contains(val, list) || contains(list, val)
}

MergeMaps(map1, map2) {
    result := {}
    for k, v in map1
        result[k] := v
    for k, v in map2
        result[k] := v
    return result
}

inlist(val, list, delim := " ") {
    items := StrSplit(list, delim)
    for _, item in items
        if (val = Trim(item))
            return true
    return false
}

contains(a, b) {
    return InStr(a, b) > 0
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

ShouldProcessKey(key, allowed := "", excluded := "") {
    if (key = "")
        return false
    if (excluded && MatchKey(key, excluded))
        return false
    if (allowed && !MatchKey(key, allowed))
        return false
    return true
}

MatchKey(key, matcher) {
    if !matcher
        return false
    if IsFunc(matcher)
        return matcher.Call(key)
    if IsObject(matcher) {
        return matcher.HasKey(key) || HasValue(matcher, key)
    }
    if (InStr(matcher, ",")) {
        Loop, Parse, matcher, `,
            if (Trim(A_LoopField) = key)
                return true
    } else {
        return key = matcher
    }
    return false
}


StrInsert(str, pos, insertStr := "") {
    return SubStr(str, 1, pos - 1) . insertStr . SubStr(str, pos)
}

StrReplaceAt(str, pos, len, newStr) {
    return StrInsert(StrRemove(str, pos, len), pos, newStr)
}

StrRemove(str, pos, len := 1) {
    return SubStr(str, 1, pos - 1) . SubStr(str, pos + len)
}