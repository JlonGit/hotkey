#Requires AutoHotkey v2.0  ; 确保使用 AHK v2
#SingleInstance Force      ; 确保脚本只运行一个实例
if !A_IsAdmin {           ; 如果不是管理员权限
    Run '*RunAs "' A_ScriptFullPath '"'  ; 以管理员权限重启脚本
    ExitApp
}
; ========== 全局快捷键 ==========
; Windows 剪贴板
#v::Send "^+#\"  ; Win+V -> Ctrl+Shift+Win+\

; 全局 Ctrl+W 映射为 Ctrl+Shift+W
^w::Send "^+w"  ; Ctrl+W -> Ctrl+Shift+W

; 全局 Alt+W 关闭窗口（仅排除Zen和Chrome浏览器）
#HotIf !WinActive("ahk_exe chrome.exe") and !WinActive("ahk_exe zen.exe")
!w::Send "!{F4}"  ; Alt+W -> Alt+F4：关闭窗口
#HotIf

; Alt+D 映射为 Ctrl+K
!d::Send "^k"    ; Alt+D -> Ctrl+K

; 显示桌面
!Escape::Send "#d"    ; Alt+Esc -> Win+D：显示桌面

; 截图翻译
+r::Send "^+r"   ; Shift+R -> Ctrl+Shift+R：截图翻译

; 新建文件
+f::Send "^n"    ; Shift+F -> Ctrl+N：新建文件

; 虚拟桌面快捷键、
!1::Send "^#{Left}"       ; Alt+1 -> Win+Ctrl+Left (切换到左侧桌面)
!3::Send "^#{Right}"      ; Alt+3 -> Win+Ctrl+Right (切换到右侧桌面)
!2::Send "^#d"           ; Alt+2 -> Win+Ctrl+D (新建桌面)
!4::Send "^#{F4}"         ; Alt+4 -> Win+Ctrl+F4 (关闭当前桌面)

; ========== 应用程序切换 ==========
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

+z:: {  ; Shift+Z：Zen 浏览器窗口切换
    if WinExist("ahk_exe zen.exe") {
        if WinActive("ahk_exe zen.exe")
            WinMinimize  ; 如果当前窗口是 Zen，则最小化
        else
            WinActivate  ; 如果 Zen 已运行但不是当前窗口，则激活
    }
    else
        Run "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Zen.lnk"  ; 如果 Zen 未运行，则启动
}

; ========== API声明 ==========
; 用于创建圆角窗口的API
CreateRoundRectRgn(x1, y1, x2, y2, w, h) {
    return DllCall("CreateRoundRectRgn", "Int", x1, "Int", y1, "Int", x2, "Int", y2, "Int", w, "Int", h, "Ptr")
}

SetWindowRgn(hwnd, hRgn, bRedraw := True) {
    return DllCall("SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "Int", bRedraw, "Int")
}

; 用于设置窗口样式的API
GetWindowLong(hwnd, nIndex) {
    return DllCall("GetWindowLong" (A_PtrSize=8?"Ptr":""), "Ptr", hwnd, "Int", nIndex, "Ptr")
}

SetWindowLong(hwnd, nIndex, dwNewLong) {
    return DllCall("SetWindowLong" (A_PtrSize=8?"Ptr":""), "Ptr", hwnd, "Int", nIndex, "Ptr", dwNewLong, "Ptr")
}

; 窗口样式常量
GWL_EXSTYLE := -20  ; 获取/设置窗口扩展样式
WS_EX_LAYERED := 0x00080000  ; 分层窗口
WS_EX_TRANSPARENT := 0x00000020  ; 鼠标点击穿透

; 窗口置顶
!`:: {  ; Alt+`：切换当前窗口置顶状态
    WinSetAlwaysOnTop -1, "A"  ; -1 表示切换状态
    
    ; 获取置顶状态
    isTopmost := WinGetExStyle("A") & 0x8  ; 0x8 是 WS_EX_TOPMOST 标志
    
    ; 获取当前鼠标位置
    MouseGetPos(&mouseX, &mouseY)
    
    ; 创建提示窗口（无标题栏和无边框）
    osd := Gui("-Caption +ToolWindow +AlwaysOnTop -Border")
    osd.MarginX := 1  ; 增加水平边距
    osd.MarginY := 3   ; 增加垂直边距
    osd.BackColor := "Silver"  ; 浅灰色背景
    
    ; 设置提示文本和样式
    if (isTopmost) {
        osd.AddText("c000000 w50 Center", "置顶")  ; 使用黑色文字
    } else {
        osd.AddText("c000000 w50 Center", "取消")  ; 使用黑色文字
    }
    
    ; 显示在鼠标位置旁边
    osd.Show("NoActivate x" (mouseX + 15) " y" (mouseY + 15) " AutoSize")
    
    ; 设置圆角
    hwnd := osd.Hwnd
    WinGetPos(,, &width, &height, "ahk_id " hwnd)
    hRgn := CreateRoundRectRgn(0, 0, width, height, 14, 14)  ; 14,14为圆角半径
    SetWindowRgn(hwnd, hRgn)
    
    ; 设置透明度 (0-255, 255为完全不透明)
    WinSetTransparent(225, osd)
    
    ; 设置自动消失
    SetTimer () => osd.Destroy(), -500
}

; 全局变量用于记录当前半透明穿透窗口的状态
global transparentWinHwnd := 0  ; 当前半透明穿透窗口的句柄
global transparentWinTransValue := 180  ; 半透明窗口的透明度值

!t:: {  ; Alt+T：切换当前窗口半透明穿透状态
    global transparentWinHwnd, transparentWinTransValue
    static isTransparentMode := false
    
    ; 获取当前活动窗口句柄
    hwnd := WinExist("A")
    
    ; 如果已经有一个窗口处于半透明穿透状态
    if (transparentWinHwnd) {
        ; 恢复原窗口样式
        exStyle := GetWindowLong(transparentWinHwnd, GWL_EXSTYLE)
        exStyle := exStyle & ~WS_EX_LAYERED & ~WS_EX_TRANSPARENT
        SetWindowLong(transparentWinHwnd, GWL_EXSTYLE, exStyle)
        
        ; 重绘窗口
        DllCall("RedrawWindow", "Ptr", transparentWinHwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0001|0x0004)
        
        ; 取消窗口置顶
        WinSetAlwaysOnTop(0, "ahk_id " transparentWinHwnd)
        
        ; 重置半透明窗口状态
        transparentWinHwnd := 0
        isTransparentMode := false
        
        ; 显示提示
        ShowOSD("恢复正常")
        return  ; 直接返回，不对当前窗口做任何操作
    }
    
    ; 设置新窗口为半透明穿透状态
    exStyle := GetWindowLong(hwnd, GWL_EXSTYLE)
    exStyle := exStyle | WS_EX_LAYERED | WS_EX_TRANSPARENT
    SetWindowLong(hwnd, GWL_EXSTYLE, exStyle)
    
    ; 设置窗口透明度
    WinSetTransparent(transparentWinTransValue, "ahk_id " hwnd)
    
    ; 置顶窗口
    WinSetAlwaysOnTop(1, "ahk_id " hwnd)
    
    ; 记录当前半透明穿透窗口句柄
    transparentWinHwnd := hwnd
    isTransparentMode := true
    
    ; 显示提示
    ShowOSD("半透明穿透")
}

; 增加透明窗口的透明度（使窗口更不透明）
!+Up:: {  ; Alt+Shift+Up：增加透明度
    global transparentWinHwnd, transparentWinTransValue
    if (transparentWinHwnd) {
        ; 增加透明度值（使窗口更不透明）
        transparentWinTransValue := Min(transparentWinTransValue + 15, 255)
        
        ; 应用新的透明度
        WinSetTransparent(transparentWinTransValue, "ahk_id " transparentWinHwnd)
        
        ; 显示当前透明度
        ShowOSD("透明度: " transparentWinTransValue)
    }
}

; 减少透明窗口的透明度（使窗口更透明）
!+Down:: {  ; Alt+Shift+Down：减少透明度
    global transparentWinHwnd, transparentWinTransValue
    if (transparentWinHwnd) {
        ; 减少透明度值（使窗口更透明）
        transparentWinTransValue := Max(transparentWinTransValue - 15, 50)
        
        ; 应用新的透明度
        WinSetTransparent(transparentWinTransValue, "ahk_id " transparentWinHwnd)
        
        ; 显示当前透明度
        ShowOSD("透明度: " transparentWinTransValue)
    }
}

; 显示操作提示OSD
ShowOSD(text) {
    ; 获取当前鼠标位置
    MouseGetPos(&mouseX, &mouseY)
    
    ; 创建提示窗口（无标题栏和无边框）
    osd := Gui("-Caption +ToolWindow +AlwaysOnTop -Border")
    osd.MarginX := 1  ; 增加水平边距
    osd.MarginY := 3   ; 增加垂直边距
    osd.BackColor := "Silver"  ; 浅灰色背景
    
    ; 设置提示文本和样式
    osd.AddText("c000000 w80 Center", text)  ; 使用黑色文字
    
    ; 显示在鼠标位置旁边
    osd.Show("NoActivate x" (mouseX + 15) " y" (mouseY + 15) " AutoSize")
    
    ; 设置圆角
    hwnd := osd.Hwnd
    WinGetPos(,, &width, &height, "ahk_id " hwnd)
    hRgn := CreateRoundRectRgn(0, 0, width, height, 14, 14)  ; 14,14为圆角半径
    SetWindowRgn(hwnd, hRgn)
    
    ; 设置透明度 (0-255, 255为完全不透明)
    WinSetTransparent(225, osd)
    
    ; 设置自动消失
    SetTimer () => osd.Destroy(), -800
}

; 连续退格
$+d::Send "{Backspace}"  ; Shift+D -> Backspace：连续退格

; 连续回车
$+e::Send "{Enter}"  ; Shift+E -> Enter：连续回车

; ; 鼠标前进后退键映射
; XButton2::Send "{Enter}"  ; 鼠标前进键 -> Enter
; XButton1::Send "{Backspace}"  ; 鼠标后退键 -> Backspace

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

; ========== Zen 浏览器快捷键 ==========
#HotIf WinActive("ahk_exe zen.exe")
+b::Send "^!b"   ; Shift+B -> Ctrl+Alt+B
!a::Send "^!a"   ; Alt+A -> Ctrl+Alt+A
!q::Send "^!q"   ; Alt+Q -> Ctrl+Alt+Q
!w::Send "^!w"   ; Alt+W -> Ctrl+Alt+W
!d::Send "^!d"   ; Alt+D -> Ctrl+Alt+D
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

; ========== 任务栏控制 ==========
; 声明全局变量保存原始鼠标位置
global originalTaskbarX := 0
global originalTaskbarY := 0
global isTaskbarKeyDown := false

; !r 按下时触发任务栏显示并保持 (Alt+R)
!r:: {
    global originalTaskbarX, originalTaskbarY, isTaskbarKeyDown
    
    ; 只在首次按下时保存位置
    if (!isTaskbarKeyDown) {
        ; 保存当前鼠标位置
        MouseGetPos(&originalTaskbarX, &originalTaskbarY)
        isTaskbarKeyDown := true
        
        ; 获取主屏幕尺寸
        screenHeight := A_ScreenHeight
        
        ; 移动到屏幕底部触发任务栏显示
        MouseMove(originalTaskbarX, screenHeight - 2, 0)
    }
    return  ; 阻止继续处理此按键
}

; !r 释放时恢复鼠标位置
!r Up:: {
    global originalTaskbarX, originalTaskbarY, isTaskbarKeyDown
    
    if (isTaskbarKeyDown) {
        ; 恢复到原始位置
        MouseMove(originalTaskbarX, originalTaskbarY, 0)
        isTaskbarKeyDown := false
    }
}

; ========== 模拟键盘输入剪贴板内容 ==========
; 使用 Alt+v 触发模拟键盘输入剪贴板内容
!v:: {
    ; 获取剪贴板内容
    clipText := A_Clipboard
    
    if (clipText != "") {
        ; 短暂延迟，以便用户可以准备好
        Sleep 500
        
        ; 逐字符输入剪贴板内容
        Loop Parse, clipText {
            Send "{Text}" A_LoopField
            ; 添加少量延迟使输入更自然，避免过快触发防护措施
            Sleep 10
        }
    }
}

; 使用 Ctrl+Alt+v 触发慢速模拟键盘输入剪贴板内容（更加安全但速度较慢）
^!v:: {
    ; 获取剪贴板内容
    clipText := A_Clipboard
    
    if (clipText != "") {
        ; 短暂延迟，以便用户可以准备好
        Sleep 500
        
        ; 逐字符输入剪贴板内容（较慢模式）
        Loop Parse, clipText {
            Send "{Text}" A_LoopField
            ; 使用较长延迟，更好地模拟人工输入
            Sleep 50
        }
    }
}


; ==========Spotify 全局快捷键==========

; 播放/暂停
^!Space:: { ; Ctrl + Alt + Space
    Send "{Media_Play_Pause}"
}

; 下一首
^!Right:: { ; Ctrl + Alt + 右箭头
    Send "{Media_Next}"
}

; 上一首
^!Left:: { ; Ctrl + Alt + 左箭头
    Send "{Media_Prev}"
}

; 音量增加
^!Up:: { ; Ctrl + Alt + 上箭头
    Send "{Volume_Up}"
}

; 音量减小
^!Down:: { ; Ctrl + Alt + 下箭头
    Send "{Volume_Down}"
}

; 静音/取消静音
^!M:: { ; Ctrl + Alt + M
    Send "{Volume_Mute}"
}
