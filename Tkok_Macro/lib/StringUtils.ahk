; --------------------------------- 문자 함수 ---------------------------------
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
    arr := ObjectToArray(object)
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