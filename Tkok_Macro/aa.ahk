
JoinLines(arr) {
    return arr.Length() ? arr.Join("`r`n") . "`r`n" : ""
}

a := ["a","","","b"]
str := JoinLines(a)

MsgBox, %str%