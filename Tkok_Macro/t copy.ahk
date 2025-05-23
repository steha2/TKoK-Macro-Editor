IsSameMacroLine(line1, line2, epsilon:= 0.005) {
    if (StrLen(line1) != StrLen(line2) || InStr(line1, "#") || InStr(line1, ";") || InStr(line1, "%"))
        return false
    pattern := "i)^Click:(\w),\s*([\d.]+),\s*([\d.]+)"
    if (RegExMatch(line1, pattern , am) && RegExMatch(line2, pattern , bm)) {
        x1 := am2 + 0, y1 := am3 + 0
        x2 := bm2 + 0, y2 := bm3 + 0
        ;test(x1,y1,x2,y2)
        dist := Sqrt((x1 - x2)**2 + (y1 - y2)**2)
        test(dist)
        return am1 = bm1 && dist <= epsilon
    } else {
        return (line1 = line2)
    }
}
t1:="Click:L, 0.350, 0.603"
t2:="Click:L, 0.350, 0.608"

test(t1,t2,IsSameMacroLine(t1,t2))


        #Include, lib/commonfuncs.ahk