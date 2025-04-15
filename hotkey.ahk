#Requires AutoHotkey v2.0  ; 确保使用 AHK v2
#SingleInstance Force      ; 确保脚本只运行一个实例
if !A_IsAdmin {           ; 如果不是管理员权限
    Run '*RunAs "' A_ScriptFullPath '"'  ; 以管理员权限重启脚本
    ExitApp
}

; ========== 全局快捷键 ==========
; Windows 剪贴板
#v::Send "^+#\"  ; Win+V -> Ctrl+Shift+Win+\

; Alt+D 映射为 Ctrl+K
!d::Send "^k"    ; Alt+D -> Ctrl+K

; 截图翻译
+r::Send "^+r"   ; Shift+R -> Ctrl+Shift+R：截图翻译

; 新建文件
+f::Send "^n"    ; Shift+F -> Ctrl+N：新建文件

; 虚拟桌面快捷键、
!1::Send "^#{Left}"       ; Alt+1 -> Win+Ctrl+Left (切换到左侧桌面)
!3::Send "^#{Right}"      ; Alt+3 -> Win+Ctrl+Right (切换到右侧桌面)
!2::Send "^#d"           ; Alt+2 -> Win+Ctrl+D (新建桌面)
!4::Send "^#{F4}"         ; Alt+4 -> Win+Ctrl+F4 (关闭当前桌面)

; 应用程序切换
+g:: {  ; Shift+G：Chrome 窗口切换
    if WinExist("ahk_exe chrome.exe") {
        if WinActive("ahk_exe chrome.exe")
            WinMinimize
        else
            WinActivate
    }
    else
        Run "chrome.exe"
}

+t:: {  ; Shift+T：Telegram 窗口切换
    if WinExist("ahk_exe Telegram.exe") {
        if WinActive("ahk_exe Telegram.exe")
            WinMinimize  ; 如果当前窗口是 Telegram，则最小化
        else
            WinActivate  ; 如果 Telegram 已运行但不是当前窗口，则激活
    }
    else
        Run "D:\Telegram Desktop\Telegram.exe"  ; 如果 Telegram 未运行，则启动
}

+n:: {  ; Shift+N：Notion 窗口切换
    if WinExist("ahk_exe Notion.exe") {
        if WinActive("ahk_exe Notion.exe")
            WinMinimize  ; 如果当前窗口是 Notion，则最小化
        else
            WinActivate  ; 如果 Notion 已运行但不是当前窗口，则激活
    }
    else
        Run "C:\Users\JJJ\AppData\Local\Programs\Notion\Notion.exe"  ; 如果 Notion 未运行，则启动
}

; 窗口置顶
!`:: {  ; Alt+`：切换当前窗口置顶状态
    WinSetAlwaysOnTop -1, "A"  ; -1 表示切换状态
    ; 获取置顶状态并播放对应音效
    if WinGetExStyle("A") & 0x8  ; 0x8 是 WS_EX_TOPMOST 标志
        SoundBeep 1000, 200  ; 置顶时的提示音（较高音）
    else
        SoundBeep 800, 200   ; 取消置顶时的提示音（较低音）
}

; 连续退格
$+d::Send "{Backspace}"  ; Shift+D -> Backspace：连续退格

; 连续回车
$+e::Send "{Enter}"  ; Shift+E -> Enter：连续回车

; 鼠标前进后退键映射
XButton2::Send "{Enter}"  ; 鼠标前进键 -> Enter
XButton1::Send "{Backspace}"  ; 鼠标后退键 -> Backspace

; ========== Chrome 快捷键 ==========
#HotIf WinActive("ahk_exe chrome.exe")
+a::Send "^+a"  ; Shift+B：打开最近关闭的标签页
!q::Send "^t"   ; Alt+Q：新建标签页
!a::Send "^+b"  ; Alt+A：打开标签栏
!w::Send "^w"  ; Alt+W：关闭标签页
#HotIf

; ========== Typora 快捷键 ==========
#HotIf WinActive("ahk_exe Typora.exe")
!q::Send "^+m"  ; Alt+Q：插入数学公式
!w::Send "^+k"  ; Alt+W：插入代码块

; 标题级别（Alt+数字）
!1::Send "^1"
!2::Send "^2"
!3::Send "^3"
!4::Send "^4"
!5::Send "^5"
!6::Send "^6"
#HotIf

; ========== Word 快捷键 ==========
#HotIf WinActive("ahk_exe WINWORD.exe")
+s::Send "^!+s"  ; Shift+S -> Ctrl+Alt+Shift+S：打开样式面板
+c::Send "^!c"   ; Shift+C -> Ctrl+Alt+C：复制格式
+v::Send "^!v"   ; Shift+V -> Ctrl+Alt+V：粘贴格式
#HotIf

; ========== PyCharm 快捷键 ==========
#HotIf WinActive("ahk_exe pycharm64.exe")
!r::Send "^+{F10}"  ; Alt+R -> Ctrl+Shift+F10：运行当前配置
#HotIf

; ========== 连点器 ==========

; 设置坐标模式为屏幕绝对坐标
CoordMode "Mouse", "Screen"  ; 使用屏幕坐标
CoordMode "Pixel", "Screen"  ; 使用屏幕坐标

global isClicking := false  ; 连点器状态
global clickPositions := []  ; 存储所有点击位置
global isRecording := false  ; 记录状态
global maxPositions := 10  ; 最大记录点数
global isActive := false  ; 连点器激活状态

^+d:: {  ; Ctrl+Shift+D：开始记录模式
    global isRecording, clickPositions, isActive
    if (!isRecording && !isActive) {  ; 开始记录模式
        isRecording := true
        clickPositions := []  ; 清空之前的记录 
        SoundBeep 2000, 200  ; 开始记录提示音
        
        ; 记录当前窗口信息
        WinGetPos(&winX, &winY, &winWidth, &winHeight, "A")
        clickPositions.Push(["window", winX, winY, winWidth, winHeight])
    }
}

; Alt键按下时启用点击记录
~!LButton:: {  ; 组合Alt+左键点击
    global isRecording, clickPositions, maxPositions
    if (isRecording && clickPositions.Length < maxPositions + 1) {
        MouseGetPos(&x, &y, &windowID) 
        ; 计算相对于窗口的位置
        WinGetPos(&winX, &winY,,, windowID)
        relativeX := x - winX
        relativeY := y - winY
        clickPositions.Push(["click", relativeX, relativeY, windowID]) 
        SoundBeep 1000, 100  ; 记录点位提示音
    }
}

; 在记录模式下，松开Alt键时自动启动连点器
~Alt Up:: {
    global isRecording, clickPositions, isClicking, isActive
    if (isRecording) {  ; 如果正在记录，启动连点器
        isRecording := false
        if (clickPositions.Length > 1) {
            isActive := true   ; 标记连点器为激活状态
            isClicking := true
            SoundBeep 1500, 200  ; 开启提示音
            SetTimer ClickLoop, 50
        } else {
            SoundBeep 500, 200  ; 未记录任何点提示音
            clickPositions := [] 
        }
    }
}

#HotIf isActive  ; 只要连点器激活就启用空格键
~Space Up:: {  ; 空格键释放时触发
    global isClicking
    isClicking := !isClicking
    if (isClicking) {
        SoundBeep 1500, 200  ; 开启提示音
        SetTimer ClickLoop, 50
    } else {
        SoundBeep 800, 200   ; 关闭提示音
        SetTimer ClickLoop, 0
    }
}
#HotIf

#HotIf isActive || isRecording  ; 只在连点器激活或记录时启用ESC键
Esc:: {  ; Esc：紧急停止
    global isClicking, isRecording, isActive
    isClicking := false
    isRecording := false
    isActive := false    ; 完全退出连点器
    SetTimer ClickLoop, 0
    SoundBeep 500, 300   ; 停止提示音
}
#HotIf

ClickLoop() {
    global clickPositions
    static currentIndex := 2
    
    MouseGetPos(&originalX, &originalY)
    BlockInput true
    
    ; 获取目标位置信息
    if (clickPositions[currentIndex][1] == "click") {
        relativeX := clickPositions[currentIndex][2]
        relativeY := clickPositions[currentIndex][3]
        targetWindow := clickPositions[currentIndex][4]
        
        ; 获取当前窗口位置
        if (WinExist("ahk_id " targetWindow)) {
            WinGetPos(&winX, &winY,,, targetWindow)
            targetX := winX + relativeX
            targetY := winY + relativeY
            
            MouseMove(targetX, targetY, 2)  ; 加快移动速度
            Sleep(20)  ; 缩短等待时间
            
            Loop 2 {  ; 减少重试次数
                MouseMove(targetX, targetY, 2)
                Sleep(10)  ; 缩短等待时间
                
                MouseGetPos(&x1, &y1, &currentWindow)
                if (currentWindow == targetWindow) {
                    Sleep(10)  ; 缩短等待时间
                    SendEvent "{Click}"
                    break
                }
            }
        }
    }
    
    currentIndex := currentIndex == clickPositions.Length ? 2 : currentIndex + 1
    
    MouseMove(originalX, originalY, 2)  ; 加快返回速度
    BlockInput false
    Sleep(10)  ; 缩短等待时间
}

; ======================= CapsLock + 字母 = 大写  =======================
; 按住 CapsLock 再按字母键，输入对应的大写字母，但不影响 Shift+字母 热键
; 并且，单独按 CapsLock 键仍然切换大小写锁定状态

CapsLock & a::Send "{Text}A"
CapsLock & b::Send "{Text}B"
CapsLock & c::Send "{Text}C"
CapsLock & d::Send "{Text}D"
CapsLock & e::Send "{Text}E"
CapsLock & f::Send "{Text}F"
CapsLock & g::Send "{Text}G"
CapsLock & h::Send "{Text}H"
CapsLock & i::Send "{Text}I"
CapsLock & j::Send "{Text}J"
CapsLock & k::Send "{Text}K"
CapsLock & l::Send "{Text}L"
CapsLock & m::Send "{Text}M"
CapsLock & n::Send "{Text}N"
CapsLock & o::Send "{Text}O"
CapsLock & p::Send "{Text}P"
CapsLock & q::Send "{Text}Q"
CapsLock & r::Send "{Text}R"
CapsLock & s::Send "{Text}S"
CapsLock & t::Send "{Text}T"
CapsLock & u::Send "{Text}U"
CapsLock & v::Send "{Text}V"
CapsLock & w::Send "{Text}W"
CapsLock & x::Send "{Text}X"
CapsLock & y::Send "{Text}Y"
CapsLock & z::Send "{Text}Z"

; 可选: 如果需要，可以添加数字或其他符号
; CapsLock & 1::Send "{Text}!"
; CapsLock & 2::Send "{Text}@"

; 处理单独按下 CapsLock 的情况
CapsLock:: {
    KeyWait "CapsLock" ; 等待 CapsLock 键被释放
    ; 检查在 CapsLock 按下期间是否有其他按键被按下 (A_PriorKey 会记录最后按下的键)
    ; 如果 A_PriorKey 仍然是 CapsLock，说明没有其他键被按下
    if (A_PriorKey == "CapsLock") {
        SetCapsLockState !GetKeyState("CapsLock", "T") ; 切换大小写状态
    }
    ; 如果期间按了其他键 (比如 'a')，则 CapsLock & a 热键已经处理了，这里什么都不做
}

; 定义一个热键，例如 Ctrl+Alt+V
^!v::
{
    ; 获取剪贴板内容
    clipboardContent := A_Clipboard
    
    ; 如果剪贴板为空，则不执行任何操作
    if (clipboardContent == "")
        return

    ; 使用 SendText 模拟键盘输入
    SendText clipboardContent
}

; Keep script running
Return
