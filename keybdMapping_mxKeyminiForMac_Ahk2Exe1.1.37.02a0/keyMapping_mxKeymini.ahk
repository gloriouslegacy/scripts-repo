; Win (Right) 키를 IME Hangul 키로 변환
RWin::Send {vk15}

; Alt (Left) 키를 Win (Left) 키로 변환
LAlt::LWin

; Win (Left) 키를 Alt (Left) 키로 변환
LWin::LAlt


; 방법 1: 직접 한영 키 전송
; RWin::Send {vk15}

; 방법 2: Alt+한자 조합
; RWin::Send {RAlt down}{vk15}{RAlt up}

; 방법 3: vkFF 사용
; RWin::vkFF

; 방법 4: F24 키로 IME 토글 (일부 시스템에서 효과적)
; RWin::Send {F24}
