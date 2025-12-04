; Windows 11 Style Key Monitor (English)
#NoEnv
#SingleInstance Force
SetBatchLines, -1

; Install keyboard hook
#InstallKeybdHook

; Create GUI with Windows 11 style
Gui, +AlwaysOnTop -Caption +Border
Gui, Color, F3F3F3
Gui, Font, s10, Segoe UI

; Title bar
Gui, Add, Progress, x0 y0 w600 h40 BackgroundFFFFFF Disabled
Gui, Add, Text, x15 y10 w500 h20 BackgroundTrans cBlack, Keyboard Monitor
Gui, Add, Text, x560 y10 w30 h20 BackgroundTrans cBlack Center gGuiClose, X

; Info section
Gui, Add, Text, x20 y50 w560 h20 c666666, Press any key. Last 10 key presses will be displayed.

; Header
Gui, Font, s9 Bold
Gui, Add, Text, x20 y80 w80 h25 c333333 Border Center 0x200, VK
Gui, Add, Text, x100 y80 w80 h25 c333333 Border Center 0x200, SC
Gui, Add, Text, x180 y80 w100 h25 c333333 Border Center 0x200, Type
Gui, Add, Text, x280 y80 w80 h25 c333333 Border Center 0x200, Up/Down
Gui, Add, Text, x360 y80 w220 h25 c333333 Border Center 0x200, Key Name

; Data rows
Gui, Font, s9 Normal, Consolas
Loop, 10
{
    yPos := 105 + (A_Index - 1) * 30
    Gui, Add, Text, x20 y%yPos% w80 h25 vVK%A_Index% Border Center 0x200, -
    Gui, Add, Text, x100 y%yPos% w80 h25 vSC%A_Index% Border Center 0x200, -
    Gui, Add, Text, x180 y%yPos% w100 h25 vType%A_Index% Border Center 0x200, -
    Gui, Add, Text, x280 y%yPos% w80 h25 vUpDown%A_Index% Border Center 0x200, -
    Gui, Add, Text, x360 y%yPos% w220 h25 vKeyName%A_Index% Border Center 0x200, -
}

; Footer info
Gui, Font, s8, Segoe UI
Gui, Add, Text, x20 y430 w560 h30 c666666 Center, Tip: RWin = Right Windows Key | LWin = Left Windows Key | vkFF = IME Hangul

; Show GUI
Gui, Show, w600 h470, Key Monitor
return

; Hotkey to capture all keys
~*a::
~*b::
~*c::
~*d::
~*e::
~*f::
~*g::
~*h::
~*i::
~*j::
~*k::
~*l::
~*m::
~*n::
~*o::
~*p::
~*q::
~*r::
~*s::
~*t::
~*u::
~*v::
~*w::
~*x::
~*y::
~*z::
~*0::
~*1::
~*2::
~*3::
~*4::
~*5::
~*6::
~*7::
~*8::
~*9::
~*F1::
~*F2::
~*F3::
~*F4::
~*F5::
~*F6::
~*F7::
~*F8::
~*F9::
~*F10::
~*F11::
~*F12::
~*Space::
~*Enter::
~*Tab::
~*Esc::
~*BackSpace::
~*Delete::
~*Insert::
~*Home::
~*End::
~*PgUp::
~*PgDn::
~*Up::
~*Down::
~*Left::
~*Right::
~*LShift::
~*RShift::
~*LCtrl::
~*RCtrl::
~*LAlt::
~*RAlt::
~*LWin::
~*RWin::
~*CapsLock::
~*NumLock::
~*ScrollLock::
~*PrintScreen::
~*Pause::
    LogKey()
return

LogKey()
{
    static keyLog := []
    
    ; Get key info
    key := SubStr(A_ThisHotkey, 3)
    vk := Format("{:02X}", GetKeyVK(key))
    sc := Format("{:03X}", GetKeySC(key))
    upDown := GetKeyState(key, "P") ? "Down" : "Up"
    
    ; Add to log (keep last 10)
    keyLog.InsertAt(1, {vk: vk, sc: sc, type: "h", upDown: upDown, key: key})
    if (keyLog.Length() > 10)
        keyLog.Pop()
    
    ; Update GUI
    Loop, % keyLog.Length()
    {
        GuiControl,, VK%A_Index%, % keyLog[A_Index].vk
        GuiControl,, SC%A_Index%, % keyLog[A_Index].sc
        GuiControl,, Type%A_Index%, % keyLog[A_Index].type
        GuiControl,, UpDown%A_Index%, % keyLog[A_Index].upDown
        GuiControl,, KeyName%A_Index%, % keyLog[A_Index].key
    }
}

GuiClose:
ExitApp
