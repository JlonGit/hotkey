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
+t::Send "^+t"   ; Shift+T -> Ctrl+Shift+T：截图翻译

; 新建文件
+f::Send "^n"    ; Shift+F -> Ctrl+N：新建文件

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

+b:: {  ; Shift+B：Joplin 窗口切换
    if WinExist("ahk_exe Joplin.exe") {
        if WinActive("ahk_exe Joplin.exe")
            WinMinimize  ; 如果当前窗口是 Joplin，则最小化
        else
            WinActivate  ; 如果 Joplin 已运行但不是当前窗口，则激活
    }
    else
        Run "C:\Program Files\Joplin\Joplin.exe"  ; 如果 Joplin 未运行，则启动
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