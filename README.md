# TKoK_Code_Loader, Macro Editor

## CodeLoader.ahk
TKoK ORPG 코드 관리 및 Warcraft III 제어 도구입니다.

클래식 Warcraft III 환경에 최적화된 다양한 내장 함수 포함

W3 멀티 로더를 통해서 다수의 클라이언트를 실행시키고 클릭 한번에 게임 준비를 완료하세요.


## MacroEditor.ahk
범용 매크로 기록/실행기입니다.

기본적인 키보드 / 마우스 매크로 기록과

텍스트 기반의 스크립트를 실행할 수 있는 고급 기능을 제공합니다.

📜 매크로 실행: .txt 파일에 명령을 작성해 순차 실행

🔁 조건문 분기: #if:조건#, #else#, #end_if#로 유동적인 흐름 제어 가능

🧠 변수 및 수식 치환: %x%, %x+1% 등의 표현 가능

📌 다중 매크로 합성: Exec: | Read: other_macro 로 분리된 매크로 조합 가능

자세한 사용 방법은 Macro Editor 내 도움말을 참고하세요.

## 설치 방법
1. **AutoHotkey 1.1**을 설치하세요.  
https://www.autohotkey.com
2. 이 프로젝트를 다운로드한 후 `config.ini` 파일을 열고 경로를 알맞게 수정하세요<br>
[Settings]<br>
;이 바로가기는 W3 멀티로더 (Universal kLoader 등)로 지정해야 동시 실행이 가능합니다.<br>
W3_LNK=C:\Warcraft III\kloader_w3.lnk <br><br>
SAVE_DIR=C:\Warcraft III\TKoK_Save_Files\TKoK_3.5.15<br>
3. `CodeLoader.ahk`를 실행하세요.
