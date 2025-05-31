Gui, Add, Text,, 그룹 1:
Gui, Add, Radio, vRadioA gRadioChanged, A
Gui, Add, Radio, vRadioB gRadioChanged, B

Gui, Add, Text,, 그룹 2:
Gui, Add, Radio, vRadioC, C
Gui, Add, Radio, vRadioD, D

Gui, Show,, 라디오 버튼 예제
Return

RadioChanged:
    Gui, Submit, NoHide
    if (RadioA) {
        GuiControl,, RadioC, 1
        GuiControl,, RadioD, 0
    } else if (RadioB) {
        GuiControl,, RadioC, 0
        GuiControl,, RadioD, 1
    }
Return

GuiClose:
ExitApp
