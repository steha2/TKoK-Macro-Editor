IsSameClickLine(line1, line2, epsilon) {
    if(StrLen(line1) != StrLen(line2))
        return false
    if !RegExMatch(line1, "^Click:L, (\d+\.\d+), (\d+\.\d+)", am)
        return false
    if !RegExMatch(line2, "^Click:L, (\d+\.\d+), (\d+\.\d+)", bm)
        return false    
    x1 := am1, y1 := am2
    x2 := bm1, y2 := bm2
    return (Abs(x1 - x2) <= epsilon && Abs(y1 - y2) <= epsilon)
}

t1 := "Click:L, 0.277, 0.213"
t2 := "Click:L, 0.350, 0.217"
t3 := "Click:L, 0.278, 0.321"
t4 := "Click:L, 0.565, 0.306"
t5 := "Click:L, 0.565, 0.304"

r := IsSameClickLine(t4,t5, 0.003) 

test(t4,t5,r)

        

        #Include, lib/commonfuncs.ahk