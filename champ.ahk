
^p::
ShowPanel("rb")
return

panels := {
    "rb": {x: 0.915, y: 0.875, rows: 3, cols: 4, width: 0.25, height: 0.20},
    "shop": {x: 0.705, y: 0.28, rows: 9, cols: 6, width: 0.3, height: 0.5}
}

ShowPanel(panelName){
 체스판처럼해서 칸 구분해서 띄우기 토글
}

PackMacro(content) {
    cleanedLines := []
    lastLine := ""
    count := 0

    Loop, Parse, content, n, r
    {
        line := Trim(A_LoopField)
        if (line = "")
            continue

        if (line = lastLine) {
            count++
        } else {
            if (lastLine != "") {
                cleanedLines.Push(FormatLine(lastLine, count))
            }
            lastLine := line
            count := 1
        }
    }

    ; 마지막 줄 처리
    if (lastLine != "") {
        cleanedLines.Push(FormatLine(lastLine, count))
    }

    return StrJoin(cleanedLines, "n")
}
