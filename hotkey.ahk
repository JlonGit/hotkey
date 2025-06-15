#Requires AutoHotkey v2.0  ; 确保使用 AHK v2
#SingleInstance Force      ; 确保脚本只运行一个实例

; 设置热键限制
A_MaxHotkeysPerInterval := 200  ; 设置最大热键数量
A_HotkeyInterval := 2000        ; 设置时间间隔（毫秒）
if !A_IsAdmin {           ; 如果不是管理员权限
    Run '*RunAs "' A_ScriptFullPath '"'  ; 以管理员权限重启脚本
    ExitApp
}

; ========== 脚本初始化 ==========
; 启动时初始化自动主题切换功能
SetTimer(() => SunriseSunset.EnableAutoTheme(), -2000)  ; 延迟2秒启动，确保所有类都已加载

; 启动时初始化桌面时钟
SetTimer(() => DesktopClock.Initialize(), -3000)  ; 延迟3秒启动桌面时钟

; ========== 桌面时钟配置 ==========
class ClockConfig {
    static WINDOW_WIDTH := 95       ; 增加窗口宽度以完全显示时间
    static WINDOW_HEIGHT := 22      ; 更小的窗口高度
    static CORNER_RADIUS := 11      ; 圆角半径
    static UPDATE_INTERVAL := 1000  ; 更新间隔（毫秒）
    static FONT_SIZE_TIME := 9      ; 更小的字体
    static TRANSPARENCY := 220      ; 更高透明度，减少干扰
    static MARGIN_X := 4            ; 更小的边距
    static MARGIN_Y := 3            ; 更小的边距
    static ANIMATION_DURATION := 200 ; 更快的动画

    ; 简洁美观的主题颜色配置
    static LIGHT_THEME := {
        bg: 0xFAFAFA,           ; 极浅背景，几乎透明
        time: 0x333333,         ; 深灰色时间，清晰可读
        border: 0xE0E0E0       ; 极淡边框
    }

    static DARK_THEME := {
        bg: 0x1C1C1C,           ; 深色背景
        time: 0xE0E0E0,         ; 浅色时间
        border: 0x404040       ; 深色边框
    }
}

; ========== 配置管理类 ==========
class Config {
    static TRANSPARENCY_STEP := 15         ; 透明度调整步长
    static DEFAULT_TRANSPARENCY := 180     ; 默认透明度
    static OSD_DISPLAY_TIME := 800         ; OSD显示时间
    static DOUBLE_CLICK_THRESHOLD := 500   ; 双击检测阈值
    static TYPING_DELAY_FAST := 10         ; 快速输入延迟
    static TYPING_DELAY_SLOW := 50         ; 慢速输入延迟
    static OSD_FADE_TIME := 500            ; OSD淡出时间
}

; ========== 媒体控制类 ==========

class MediaControl {
    ; 播放/暂停
    static PlayPause() {
        try {
            Send "{Media_Play_Pause}"
        } catch Error as e {
            Logger.LogError("MediaControl.PlayPause", e.message)
        }
    }   
    ; 下一首
    static Next() {
        try {
            Send "{Media_Next}"
        } catch Error as e {
            Logger.LogError("MediaControl.Next", e.message)
        }
    }        
    ; 上一首
    static Previous() {
        try {
            Send "{Media_Prev}"
        } catch Error as e {
            Logger.LogError("MediaControl.Previous", e.message)
        }
    }    
    ; 音量增加
    static VolumeUp() {
        try {
            Send "{Volume_Up}"
        } catch Error as e {
            Logger.LogError("MediaControl.VolumeUp", e.message)
        }
    }    
    ; 音量减小
    static VolumeDown() {
        try {
            Send "{Volume_Down}"
        } catch Error as e {
            Logger.LogError("MediaControl.VolumeDown", e.message)
        }
    }  
    ; 静音切换
    static Mute() {
        try {
            Send "{Volume_Mute}"
        } catch Error as e {
            Logger.LogError("MediaControl.Mute", e.message)
        }
    }
}

; ========== 桌面时钟类 ==========
class DesktopClock {
    static gui := ""
    static timeText := ""
    static updateTimer := ""
    static isDarkTheme := false
    static isVisible := false  ; 初始化为false，这样Show()方法才能正常工作
    static currentTheme := ""

    ; 初始化时钟
    static Initialize() {
        try {
            ; 检测系统主题
            this.DetectSystemTheme()

            ; 创建GUI
            this.CreateGUI()

            ; 开始更新时间
            this.StartTimer()

            ; 显示时钟
            this.Show()

            Logger.LogInfo("DesktopClock.Initialize", "桌面时钟初始化成功")
        } catch Error as e {
            Logger.LogError("DesktopClock.Initialize", "桌面时钟初始化失败: " e.message)
        }
    }

    ; 检测并设置系统主题
    static DetectSystemTheme() {
        try {
            this.isDarkTheme := (RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme") = 0)
        } catch {
            this.isDarkTheme := false
        }
        this.currentTheme := this.isDarkTheme ? ClockConfig.DARK_THEME : ClockConfig.LIGHT_THEME
    }

    ; 创建GUI界面
    static CreateGUI() {
        this.gui := Gui("-Caption +ToolWindow -Border +LastFound", "Desktop Clock")
        this.gui.MarginX := 0
        this.gui.MarginY := 0
        this.gui.BackColor := Format("{:06X}", this.currentTheme.bg)

        ; 创建时间显示 - VCenter上下居中，减少左边距让右边完全显示
        this.timeText := this.gui.AddText("VCenter x5 y0 w" (ClockConfig.WINDOW_WIDTH - 0) " h" ClockConfig.WINDOW_HEIGHT
                                        " c" Format("{:06X}", this.currentTheme.time), "00:00:00")
        this.timeText.SetFont("s" ClockConfig.FONT_SIZE_TIME, "Consolas")
        this.gui.OnEvent("Close", (*) => this.Hide())
        this.ApplyWindowStyle()
    }

    ; 应用窗口样式
    static ApplyWindowStyle() {
        this.gui.Show("w" ClockConfig.WINDOW_WIDTH " h" ClockConfig.WINDOW_HEIGHT " Hide")
        WinSetTransparent(ClockConfig.TRANSPARENCY, this.gui)
    }

    ; 应用圆角效果
    static ApplyRoundedCorners() {
        try {
            Sleep(50)
            hRgn := CreateRoundRectRgn(0, 0, ClockConfig.WINDOW_WIDTH, ClockConfig.WINDOW_HEIGHT, ClockConfig.CORNER_RADIUS, ClockConfig.CORNER_RADIUS)
            if (hRgn) {
                SetWindowRgn(this.gui.Hwnd, hRgn)
            }
        } catch {
            ; 圆角失败时静默处理
        }
    }

    ; 开始定时器
    static StartTimer() {
        this.UpdateTime()
        this.updateTimer := () => this.UpdateTime()
        SetTimer(this.updateTimer, ClockConfig.UPDATE_INTERVAL)
    }

    ; 更新时间显示
    static UpdateTime() {
        try {
            this.timeText.Text := FormatTime(, "HH:mm:ss")
            this.CheckThemeChange()
        } catch {
            ; 更新失败时静默处理
        }
    }

    ; 检查主题变化
    static CheckThemeChange() {
        try {
            newIsDarkTheme := (RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme") = 0)
            if (newIsDarkTheme != this.isDarkTheme) {
                this.isDarkTheme := newIsDarkTheme
                this.UpdateTheme()
            }
        } catch {
            ; 忽略主题检测错误
        }
    }

    ; 更新主题
    static UpdateTheme() {
        try {
            this.currentTheme := this.isDarkTheme ? ClockConfig.DARK_THEME : ClockConfig.LIGHT_THEME
            this.gui.BackColor := Format("{:06X}", this.currentTheme.bg)
            this.timeText.Opt("c" Format("{:06X}", this.currentTheme.time))
            DllCall("RedrawWindow", "Ptr", this.gui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0001|0x0004)
        } catch {
            ; 主题更新失败时静默处理
        }
    }

    ; 显示时钟
    static Show() {
        if (!this.isVisible) {
            this.gui.Show("NoActivate x1069 y0")
            WinSetAlwaysOnTop(true, this.gui)
            this.ApplyRoundedCorners()
            this.Fade(true)
            this.isVisible := true
        }
    }

    ; 淡化动画
    static Fade(fadeIn := true) {
        try {
            steps := fadeIn ? 10 : 8
            stepDelay := ClockConfig.ANIMATION_DURATION // steps
            Loop steps {
                alpha := fadeIn ? Round(ClockConfig.TRANSPARENCY * A_Index / steps) : Round(ClockConfig.TRANSPARENCY * (steps - A_Index) / steps)
                WinSetTransparent(alpha, this.gui)
                Sleep(stepDelay)
            }
        } catch {
            ; 动画失败时静默处理
        }
    }

    ; 隐藏时钟
    static Hide() {
        if (this.isVisible) {
            this.Fade(false)
            this.gui.Hide()
            this.isVisible := false
        }
    }

    ; 切换显示状态
    static Toggle() {
        if (this.isVisible) {
            this.Hide()
        } else {
            this.Show()
        }
    }

    ; 销毁时钟
    static Destroy() {
        try {
            if (this.updateTimer) {
                SetTimer(this.updateTimer, 0)
                this.updateTimer := ""
            }
            if (this.gui) {
                this.gui.Destroy()
                this.gui := ""
            }
            this.timeText := ""
            this.isVisible := false
        } catch {
            ; 销毁失败时静默处理
        }
    }
}

; ========== 日志管理类 ==========
class Logger {
    static KEEP_DAYS := 3  ; 保留最近3天的日志
    static lastCleanupDate := ""

    static LogError(funcName, errorMsg) {
        try {
            Logger.CleanupOldLogs()
            logFile := A_ScriptDir "\hotkey_errors.log"
            FileAppend(A_Now " [ERROR] " funcName ": " errorMsg "`n", logFile)
        } catch {
            ; 如果日志写入失败，静默处理
        }
    }

    static LogInfo(funcName, infoMsg) {
        try {
            Logger.CleanupOldLogs()
            logFile := A_ScriptDir "\hotkey_info.log"
            FileAppend(A_Now " [INFO] " funcName ": " infoMsg "`n", logFile)
        } catch {
            ; 如果日志写入失败，静默处理
        }
    }

    ; 清理旧日志（每天只执行一次）
    static CleanupOldLogs() {
        try {
            currentDate := FormatTime(, "yyyyMMdd")

            ; 如果今天已经清理过，则跳过
            if (Logger.lastCleanupDate = currentDate) {
                return
            }

            Logger.lastCleanupDate := currentDate

            ; 计算3天前的日期
            threeDaysAgo := DateAdd(A_Now, -Logger.KEEP_DAYS, "Days")
            cutoffDate := FormatTime(threeDaysAgo, "yyyyMMdd")

            ; 清理错误日志
            Logger.CleanupLogFile(A_ScriptDir "\hotkey_errors.log", cutoffDate)

            ; 清理信息日志
            Logger.CleanupLogFile(A_ScriptDir "\hotkey_info.log", cutoffDate)

        } catch {
            ; 清理失败时静默处理
        }
    }

    ; 清理指定日志文件中的旧记录
    static CleanupLogFile(logFile, cutoffDate) {
        try {
            if (!FileExist(logFile)) {
                return
            }

            ; 读取现有日志内容
            logContent := FileRead(logFile)
            lines := StrSplit(logContent, "`n")

            ; 过滤保留最近3天的日志
            newLines := []
            for line in lines {
                if (line = "") {
                    continue
                }

                ; 提取日志行的日期部分（前8位：yyyyMMdd）
                if (StrLen(line) >= 8) {
                    logDate := SubStr(line, 1, 8)
                    if (logDate >= cutoffDate) {
                        newLines.Push(line)
                    }
                }
            }

            ; 如果有变化，重写文件
            if (newLines.Length < lines.Length) {
                newContent := ""
                for line in newLines {
                    newContent .= line . "`n"
                }

                ; 重写日志文件
                FileDelete(logFile)
                if (newContent != "") {
                    FileAppend(newContent, logFile)
                }
            }

        } catch {
            ; 清理单个文件失败时静默处理
        }
    }
}

; ========== 主题控制类 ==========
class ThemeControl {
    static REGISTRY_PATH := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    static GetCurrentTheme() {
        try {
            appsTheme := RegRead(ThemeControl.REGISTRY_PATH, "AppsUseLightTheme")
            try {
                systemTheme := RegRead(ThemeControl.REGISTRY_PATH, "SystemUsesLightTheme")
            } catch {
                systemTheme := appsTheme
            }
            return (appsTheme = 1 && systemTheme = 1)
        } catch {
            return true
        }
    }
    
    static SetTheme(isLight) {
        themeValue := isLight ? 1 : 0
        
        RegWrite(themeValue, "REG_DWORD", ThemeControl.REGISTRY_PATH, "AppsUseLightTheme")
        try RegWrite(themeValue, "REG_DWORD", ThemeControl.REGISTRY_PATH, "SystemUsesLightTheme")
        try {
            RegWrite(themeValue, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentColorMenu")
            RegWrite(themeValue, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "StartColorMenu")
        }
        
        ; 设置光标颜色以匹配主题
        ThemeControl.SetCursorColor(isLight)
        
        DllCall("user32.dll\PostMessage", "Ptr", 0xFFFF, "UInt", 0x001A, "Ptr", 0, "AStr", "ImmersiveColorSet")
        DllCall("user32.dll\PostMessage", "Ptr", 0xFFFF, "UInt", 0x031A, "Ptr", 0, "Ptr", 0)
    }
    
    static SetCursorColor(isLight) {
        try {
            ; 根据主题设置光标颜色
            ; 亮色主题使用黑色光标，暗色主题使用白色光标
            cursorScheme := isLight ? "Windows Default (system scheme)" : "Windows Black (system scheme)"
            
            ; 设置光标方案
            RegWrite(cursorScheme, "REG_SZ", "HKEY_CURRENT_USER\Control Panel\Cursors", "")
            
            ; 刷新光标设置
            DllCall("user32.dll\SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0x0002)
            
            Logger.LogInfo("ThemeControl.SetCursorColor", "光标颜色已设置: " (isLight ? "黑色" : "白色"))
        } catch Error as e {
            Logger.LogError("ThemeControl.SetCursorColor", "设置光标颜色失败: " e.message)
        }
    }
    
    static ToggleTheme() {
        currentTheme := ThemeControl.GetCurrentTheme()
        newTheme := !currentTheme
        
        ThemeControl.SetTheme(newTheme)
        ShowOSD("主题: " (newTheme ? "亮色" : "暗色"))
    }
}

; ========== 日出日落控制类 ==========
class SunriseSunset {
    static DEFAULT_LAT := 36.52    ; 北京纬度
    static DEFAULT_LNG := 118.46   ; 北京经度
    static API_URL := "https://api.sunrise-sunset.org/json"
    static CHECK_INTERVAL := 300000  ; 5分钟检查一次 (毫秒)
    static AUTO_THEME_ENABLED := true
    static lastSunriseTime := ""
    static lastSunsetTime := ""
    static themeCheckTimer := ""
    
    ; 获取指定坐标的日出日落时间
    static GetSunTimes(lat := "", lng := "") {
        try {
            ; 使用默认坐标如果未提供
            if (lat = "" || lng = "") {
                lat := SunriseSunset.DEFAULT_LAT
                lng := SunriseSunset.DEFAULT_LNG
            }
            
            ; 构建API URL
            url := SunriseSunset.API_URL . "?lat=" . lat . "&lng=" . lng . "&formatted=0"
            
            ; 创建HTTP请求
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", url, false)
            http.SetRequestHeader("User-Agent", "AutoHotkey/2.0")
            http.Send()
            
            ; 检查响应状态
            if (http.Status != 200) {
                throw Error("HTTP请求失败: " . http.Status)
            }
            
            ; 解析JSON响应
            response := http.ResponseText
            sunData := SunriseSunset.ParseSunData(response)
            
            if (sunData.status = "OK") {
                ; 转换为本地时间
                sunriseLocal := SunriseSunset.ConvertToLocalTime(sunData.sunrise)
                sunsetLocal := SunriseSunset.ConvertToLocalTime(sunData.sunset)
                
                ; 更新缓存
                SunriseSunset.lastSunriseTime := sunriseLocal
                SunriseSunset.lastSunsetTime := sunsetLocal
                
                Logger.LogInfo("SunriseSunset.GetSunTimes", "获取成功 - 日出: " . sunriseLocal . ", 日落: " . sunsetLocal)
                
                return {
                    sunrise: sunriseLocal,
                    sunset: sunsetLocal,
                    status: "success"
                }
            } else {
                throw Error("API返回错误: " . sunData.status)
            }
            
        } catch Error as e {
            Logger.LogError("SunriseSunset.GetSunTimes", "获取日出日落时间失败: " . e.message)
            return {
                sunrise: "",
                sunset: "",
                status: "error",
                error: e.message
            }
        }
    }
    
    ; 简单的JSON解析（仅解析需要的字段）
    static ParseSunData(jsonStr) {
        try {
            ; 提取status
            statusMatch := RegExMatch(jsonStr, '"status"\s*:\s*"([^"]+)"', &statusResult)
            status := statusMatch ? statusResult[1] : "UNKNOWN"
            
            if (status != "OK") {
                return {status: status}
            }
            
            ; 提取sunrise
            sunriseMatch := RegExMatch(jsonStr, '"sunrise"\s*:\s*"([^"]+)"', &sunriseResult)
            sunrise := sunriseMatch ? sunriseResult[1] : ""
            
            ; 提取sunset
            sunsetMatch := RegExMatch(jsonStr, '"sunset"\s*:\s*"([^"]+)"', &sunsetResult)
            sunset := sunsetMatch ? sunsetResult[1] : ""
            
            return {
                status: status,
                sunrise: sunrise,
                sunset: sunset
            }
        } catch Error as e {
            Logger.LogError("SunriseSunset.ParseSunData", "JSON解析失败: " . e.message)
            return {status: "PARSE_ERROR"}
        }
    }
    
    ; 将UTC时间转换为本地时间
    static ConvertToLocalTime(utcTimeStr) {
        try {
            ; 解析UTC时间字符串 (格式: 2024-05-30T10:30:45+00:00)
            if (RegExMatch(utcTimeStr, "(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", &timeMatch)) {
                year := timeMatch[1]
                month := timeMatch[2]
                day := timeMatch[3]
                hour := timeMatch[4]
                minute := timeMatch[5]
                second := timeMatch[6]
                
                ; 构建本地时间字符串并转换
                utcTime := year . month . day . hour . minute . second
                localTime := DateAdd(utcTime, 8, "Hours")  ; 转换为北京时间 (UTC+8)
                
                ; 格式化为可读时间
                return FormatTime(localTime, "HH:mm:ss")
            }
            return utcTimeStr
        } catch Error as e {
            Logger.LogError("SunriseSunset.ConvertToLocalTime", "时间转换失败: " . e.message)
            return utcTimeStr
        }
    }
    
    ; 显示日出日落信息
    static ShowSunInfo(lat := "", lng := "") {
        sunData := SunriseSunset.GetSunTimes(lat, lng)
        
        if (sunData.status = "success") {
            infoText := "日出: " . sunData.sunrise . "`n日落: " . sunData.sunset
            ShowOSD(infoText)
        } else {
            ShowOSD("获取日出日落时间失败")
        }
    }
    
    ; 启用自动主题切换
    static EnableAutoTheme() {
        SunriseSunset.AUTO_THEME_ENABLED := true
        
        ; 立即检查一次
        SunriseSunset.CheckAndSwitchTheme()
        
        ; 设置定时器定期检查
        if (SunriseSunset.themeCheckTimer) {
            SetTimer(SunriseSunset.themeCheckTimer, 0)  ; 先停止现有定时器
        }
        SunriseSunset.themeCheckTimer := () => SunriseSunset.CheckAndSwitchTheme()
        SetTimer(SunriseSunset.themeCheckTimer, SunriseSunset.CHECK_INTERVAL)
        
        ShowOSD("自动主题切换已启用")
        Logger.LogInfo("SunriseSunset.EnableAutoTheme", "自动主题切换已启用")
    }
    
    ; 禁用自动主题切换
    static DisableAutoTheme() {
        SunriseSunset.AUTO_THEME_ENABLED := false
        
        ; 停止定时器
        if (SunriseSunset.themeCheckTimer) {
            SetTimer(SunriseSunset.themeCheckTimer, 0)
            SunriseSunset.themeCheckTimer := ""
        }
        
        ShowOSD("自动主题切换已禁用")
        Logger.LogInfo("SunriseSunset.DisableAutoTheme", "自动主题切换已禁用")
    }
    
    ; 检查并切换主题
    static CheckAndSwitchTheme() {
        if (!SunriseSunset.AUTO_THEME_ENABLED) {
            return
        }
        
        try {
            ; 获取最新的日出日落时间
            sunData := SunriseSunset.GetSunTimes()
            
            if (sunData.status != "success") {
                Logger.LogError("SunriseSunset.CheckAndSwitchTheme", "无法获取日出日落时间")
                return
            }
            
            ; 获取当前时间
            currentTime := FormatTime(, "HH:mm:ss")
            
            ; 判断当前应该使用什么主题
            shouldUseLightTheme := SunriseSunset.ShouldUseLightTheme(currentTime, sunData.sunrise, sunData.sunset)
            currentTheme := ThemeControl.GetCurrentTheme()
            
            ; 如果需要切换主题
            if (shouldUseLightTheme != currentTheme) {
                ThemeControl.SetTheme(shouldUseLightTheme)
                themeText := shouldUseLightTheme ? "亮色" : "暗色"
                reasonText := shouldUseLightTheme ? "日出后" : "日落后"
                ShowOSD("自动切换: " . themeText . "主题 (" . reasonText . ")")
                Logger.LogInfo("SunriseSunset.CheckAndSwitchTheme", "自动切换到" . themeText . "主题")
            }
            
        } catch Error as e {
            Logger.LogError("SunriseSunset.CheckAndSwitchTheme", "主题检查失败: " . e.message)
        }
    }
    
    ; 判断当前时间是否应该使用亮色主题
    static ShouldUseLightTheme(currentTime, sunriseTime, sunsetTime) {
        ; 将时间转换为分钟数便于比较
        current := SunriseSunset.TimeToMinutes(currentTime)
        sunrise := SunriseSunset.TimeToMinutes(sunriseTime)
        sunset := SunriseSunset.TimeToMinutes(sunsetTime)
        
        ; 如果当前时间在日出和日落之间，使用亮色主题
        return (current >= sunrise && current < sunset)
    }
    
    ; 将时间字符串转换为分钟数
    static TimeToMinutes(timeStr) {
        if (RegExMatch(timeStr, "(\d{1,2}):(\d{2}):(\d{2})", &timeMatch)) {
            hours := Integer(timeMatch[1])
            minutes := Integer(timeMatch[2])
            return hours * 60 + minutes
        }
        return 0
    }
    
    ; 切换自动主题功能
    static ToggleAutoTheme() {
        if (SunriseSunset.AUTO_THEME_ENABLED) {
            SunriseSunset.DisableAutoTheme()
        } else {
            SunriseSunset.EnableAutoTheme()
        }
    }
}
; ========== 全局快捷键 ==========
; F1映射到Ctrl+C（复制）
F1::Send "^c"

; F2映射到Ctrl+V（粘贴）
F2::Send "^v"

; Alt+Alt映射到Ctrl+Alt+`
~LAlt Up::{
    static lastAltTime := 0
    currentTime := A_TickCount
    if (currentTime - lastAltTime < 300) {
        Send "^!``"
        lastAltTime := 0
    } else {
        lastAltTime := currentTime
    }
}

; Windows 剪贴板
#v::Send "^+#\"  ; Win+V -> Ctrl+Shift+Win+\

; 全局 Alt+W 关闭窗口（仅排除Zen和Chrome浏览器）
#HotIf !WinActive("ahk_exe chrome.exe") and !WinActive("ahk_exe zen.exe")and !WinActive("ahk_exe Typora.exe")
!w::Send "!{F4}"  ; Alt+W -> Alt+F4：关闭窗口
#HotIf

; Alt+D 映射为 Ctrl+K
!d::Send "^k"    ; Alt+D -> Ctrl+K

; 显示桌面
!Escape::Send "#d"    ; Alt+Esc -> Win+D：显示桌面

; 全屏
!f::Send "{F11}"    ; Alt+F -> F11：全屏/退出全屏

; 截图翻译
+r::Send "^+r"   ; Shift+R -> Ctrl+Shift+R：截图翻译

; 新建文件
+f::Send "^n"    ; Shift+F -> Ctrl+N：新建文件

; 主题切换
#+t:: {  ; Win+Shift+T：手动切换主题并关闭自动切换
    ; 先关闭自动主题切换
    SunriseSunset.DisableAutoTheme()
    ; 然后手动切换主题
    ThemeControl.ToggleTheme()
}

; 日出日落相关热键
#+o::SunriseSunset.ShowSunInfo()  ; Win+Shift+O：显示日出日落时间
#+a::SunriseSunset.ToggleAutoTheme()  ; Win+Shift+A：切换自动主题功能

; 桌面时钟相关热键
^!c::DesktopClock.Toggle()  ; Ctrl+Alt+C：切换时钟显示/隐藏

; 虚拟桌面快捷键、
!1::Send "^#{Left}"       ; Alt+1 -> Win+Ctrl+Left (切换到左侧桌面)
!3::Send "^#{Right}"      ; Alt+3 -> Win+Ctrl+Right (切换到右侧桌面)
!2::Send "^#d"           ; Alt+2 -> Win+Ctrl+D (新建桌面)
!4::Send "^#{F4}"         ; Alt+4 -> Win+Ctrl+F4 (关闭当前桌面)

; ========== 应用程序切换 ==========
; 通用应用切换函数（带错误处理）
ToggleApp(exeName, appPath := "") {
    try {
        if WinExist("ahk_exe " exeName) {
            if WinActive("ahk_exe " exeName) {
                ; 微信和Spotify特殊处理：关闭窗口而不是最小化（会在托盘继续运行）
                if (exeName = "Weixin.exe" || exeName = "Spotify.exe") {
                    WinClose  ; 关闭主窗口，程序继续在托盘运行
                    Logger.LogInfo("ToggleApp", "关闭主窗口: " exeName)
                } else {
                    WinMinimize  ; 其他应用最小化
                    Logger.LogInfo("ToggleApp", "最小化应用: " exeName)
                }
            } else {
                WinActivate  ; 激活目标应用
                Logger.LogInfo("ToggleApp", "激活应用: " exeName)
            }
        }
        else if (appPath != "") {
            Run appPath  ; 如果目标应用未运行且提供了路径，则启动
            Logger.LogInfo("ToggleApp", "启动应用: " exeName " 路径: " appPath)
        } else {
            ShowOSD("未找到应用: " exeName)
            Logger.LogError("ToggleApp", "应用未找到且无启动路径: " exeName)
        }
    } catch Error as e {
        Logger.LogError("ToggleApp", "操作失败 - 应用: " exeName " 错误: " e.message)
        ShowOSD("操作失败: " exeName)
    }
}

; ========== 应用程序切换快捷键 ==========
+g::ToggleApp("chrome.exe", "chrome.exe")  ; Shift+G：Chrome 窗口切换
+t::ToggleApp("Telegram.exe", "D:\Telegram Desktop\Telegram.exe")  ; Shift+T：Telegram 窗口切换
+n::ToggleApp("Notion.exe", "notion:")  ; Shift+N：Notion 窗口切换
+z::ToggleApp("zen.exe", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Zen.lnk")  ; Shift+Z：Zen 浏览器窗口切换
+s::ToggleApp("Spotify.exe", "spotify:")  ; Shift+S：Spotify 窗口切换
+w::ToggleApp("Weixin.exe", "D:\Weixin\Weixin.exe")  ; Shift+W：微信窗口切换

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
    try {
        WinSetAlwaysOnTop -1, "A"  ; -1 表示切换状态
        
        ; 获取置顶状态
        isTopmost := WinGetExStyle("A") & 0x8  ; 0x8 是 WS_EX_TOPMOST 标志
        
        ; 显示OSD提示
        if (isTopmost) {
            ShowOSD("置顶")
        } else {
            ShowOSD("取消")
        }
        
        Logger.LogInfo("WindowTopmost", "窗口置顶状态切换: " (isTopmost ? "已置顶" : "已取消"))
        
    } catch Error as e {
        Logger.LogError("WindowTopmost", "置顶操作失败: " e.message)
        ShowOSD("置顶失败")
    }
}

; 全局变量用于记录当前半透明穿透窗口的状态
global transparentWinHwnd := 0  ; 当前半透明穿透窗口的句柄
global transparentWinTransValue := Config.DEFAULT_TRANSPARENCY  ; 半透明窗口的透明度值

; 全局变量用于跟踪键盘锁定状态
global isKeyboardLocked := false
global lastClickTime := 0  ; 用于记录上次点击时间

; 连点器全局变量
global g_clickRecorder := {
    isActive: false,    ; 连点器模式是否激活
    isRecording: false,
    isPlaying: false,
    positions: [],
    currentIndex: 0,
    playTimer: 0,
    playInterval: 100,  ; 播放间隔（毫秒）
    loopCount: 0,       ; 当前循环次数
    maxLoops: -1        ; 最大循环次数，-1表示无限循环
}

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
        transparentWinTransValue := Min(transparentWinTransValue + Config.TRANSPARENCY_STEP, 255)
        
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
        transparentWinTransValue := Max(transparentWinTransValue - Config.TRANSPARENCY_STEP, 50)
        
        ; 应用新的透明度
        WinSetTransparent(transparentWinTransValue, "ahk_id " transparentWinHwnd)
        
        ; 显示当前透明度
        ShowOSD("透明度: " transparentWinTransValue)
    }
}

; 显示操作提示OSD（使用Config配置，带淡出效果）
ShowOSD(text) {
    try {
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
        
        ; 设置初始透明度 (0-255, 255为完全不透明)
        WinSetTransparent(225, osd)
        
        ; 为每个OSD实例创建独立的淡出状态
        fadeSteps := 10
        stepDelay := Config.OSD_FADE_TIME // fadeSteps
        fadeState := {step: 0, maxSteps: fadeSteps, osdRef: osd, delay: stepDelay}
        
        ; 设置显示时间后开始淡出，使用闭包避免全局变量冲突
        SetTimer(() => StartFadeOut(fadeState), -(Config.OSD_DISPLAY_TIME - Config.OSD_FADE_TIME))
        
        Logger.LogInfo("ShowOSD", "显示提示: " text)
    } catch Error as e {
        Logger.LogError("ShowOSD", "显示OSD失败: " e.message)
    }
}

; 开始淡出动画（每个实例独立）
StartFadeOut(fadeState) {
    try {
        if (!WinExist("ahk_id " fadeState.osdRef.Hwnd)) {
            return  ; 窗口已不存在，直接返回
        }
        
        ; 开始淡出动画
        SetTimer(() => DoFadeStep(fadeState), -fadeState.delay)
        
    } catch Error as e {
        Logger.LogError("StartFadeOut", "开始淡出失败: " e.message)
        ; 如果淡出失败，直接销毁窗口
        try {
            if (WinExist("ahk_id " fadeState.osdRef.Hwnd)) {
                fadeState.osdRef.Destroy()
            }
        } catch {
            ; 静默处理销毁失败
        }
    }
}

; 淡出步骤执行函数（每个实例独立）
DoFadeStep(fadeState) {
    try {
        if (!IsObject(fadeState)) {
            return  ; 如果状态对象不存在，直接返回
        }
        
        fadeState.step++
        if (fadeState.step <= fadeState.maxSteps && WinExist("ahk_id " fadeState.osdRef.Hwnd)) {
            ; 计算当前透明度 (从225逐渐减少到0)
            alpha := Round(225 * (fadeState.maxSteps - fadeState.step) / fadeState.maxSteps)
            WinSetTransparent(alpha, fadeState.osdRef)
            
            ; 继续下一步淡出
            SetTimer(() => DoFadeStep(fadeState), -fadeState.delay)
        } else {
            ; 淡出完成或窗口已不存在，销毁窗口
            try {
                if (WinExist("ahk_id " fadeState.osdRef.Hwnd)) {
                    fadeState.osdRef.Destroy()
                }
            } catch {
                ; 静默处理销毁失败
            }
        }
    } catch Error as e {
        Logger.LogError("DoFadeStep", "淡出步骤失败: " e.message)
        ; 出错时直接销毁窗口
        try {
            if (IsObject(fadeState) && WinExist("ahk_id " fadeState.osdRef.Hwnd)) {
                fadeState.osdRef.Destroy()
            }
        } catch {
            ; 静默处理销毁失败
        }
    }
}

; 连续退格
$+d::Send "{Backspace}"  ; Shift+D -> Backspace：连续退格

; 连续回车
$+e::Send "{Enter}"  ; Shift+E -> Enter：连续回车

; ========== Chrome 快捷键 ==========
#HotIf WinActive("ahk_exe chrome.exe")
+a::Send "^+a"  ; Shift+A：打开最近关闭的标签页
!q::Send "^t"   ; Alt+Q：新建标签页
!z::Send "^+b"  ; Alt+Z：显示/隐藏书签栏
+b::Send "^+m"  ; shift+B：自动填充密码
!w::Send "^w"  ; Alt+W：关闭标签页
![::Send "!{Left}"  ; Alt+[：后退
!]::Send "!{Right}"  ; Alt+]：前进
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

; ========== 键盘输入类 - 处理复杂文本输入 ==========
class KeyboardInput {
    ; 静态属性定义 - 使用属性访问器避免初始化问题
    static _isInputMode := false
    static _isPaused := false
    static _inputTimer := 0
    static _currentText := ""
    static _currentLines := []
    static _currentLineIndex := 0
    static _currentCharIndex := 0
    static _inputDelay := 10
    static _statusOSD := ""
    static _statusText := ""  ; 添加状态文本控件引用

    ; 属性访问器
    static isInputMode {
        get => this._isInputMode
        set => this._isInputMode := value
    }

    static isPaused {
        get => this._isPaused
        set => this._isPaused := value
    }

    static inputTimer {
        get => this._inputTimer
        set => this._inputTimer := value
    }

    static currentText {
        get => this._currentText
        set => this._currentText := value
    }

    static currentLines {
        get => this._currentLines
        set => this._currentLines := value
    }

    static currentLineIndex {
        get => this._currentLineIndex
        set => this._currentLineIndex := value
    }

    static currentCharIndex {
        get => this._currentCharIndex
        set => this._currentCharIndex := value
    }

    static inputDelay {
        get => this._inputDelay
        set => this._inputDelay := value
    }

    static statusOSD {
        get => this._statusOSD
        set => this._statusOSD := value
    }

    static statusText {
        get => this._statusText
        set => this._statusText := value
    }

    ; 进入模拟输入模式
    static EnterInputMode(text, delay := 10) {
        if (text = "" || this.isInputMode) {
            return false
        }

        ; 显示进入模式的提示（使用ShowOSD跟随鼠标）
        ShowOSD("进入模拟输入模式")

        ; 初始化模拟输入模式状态
        this.isInputMode := true
        this.isPaused := false
        this.currentText := text
        this.inputDelay := delay
        this.currentLineIndex := 0
        this.currentCharIndex := 0

        ; 预处理文本：统一换行符格式
        processedText := StrReplace(text, "`r`n", "`n")
        processedText := StrReplace(processedText, "`r", "`n")
        this.currentLines := StrSplit(processedText, "`n")

        ; 显示状态提示（跟随鼠标位置）
        this.ShowInputStatus("准备开始输入...")

        ; 开始输入处理
        this.StartInputProcess()

        Logger.LogInfo("KeyboardInput", "进入模拟输入模式，文本长度: " StrLen(text))
        return true
    }

    ; 退出模拟输入模式
    static ExitInputMode() {
        if (!this.isInputMode) {
            return
        }

        ; 停止定时器
        if (this.inputTimer) {
            SetTimer(this.inputTimer, 0)
            this.inputTimer := 0
        }

        ; 重置状态
        this.isInputMode := false
        this.isPaused := false
        this.currentText := ""
        this.currentLines := []
        this.currentLineIndex := 0
        this.currentCharIndex := 0

        ; 隐藏状态OSD
        this.HideInputStatus()

        ; 显示退出提示
        ShowOSD("退出模拟输入模式")
        Logger.LogInfo("KeyboardInput", "退出模拟输入模式")
    }

    ; 切换暂停状态
    static TogglePause() {
        if (!this.isInputMode) {
            return
        }

        this.isPaused := !this.isPaused
        statusText := this.isPaused ? "暂停输入" : "继续输入"
        this.ShowInputStatus(statusText)
        Logger.LogInfo("KeyboardInput", statusText)
    }

    ; 开始输入处理
    static StartInputProcess() {
        if (!this.isInputMode) {
            return
        }

        ; 创建输入定时器
        this.inputTimer := () => this.ProcessNextChar()
        SetTimer(this.inputTimer, this.inputDelay)
    }

    ; 处理下一个字符
    static ProcessNextChar() {
        if (!this.isInputMode || this.isPaused) {
            return
        }

        ; 检查是否完成所有输入
        if (this.currentLineIndex >= this.currentLines.Length) {
            this.ExitInputMode()
            ShowOSD("输入完成")
            return
        }

        currentLine := this.currentLines[this.currentLineIndex + 1]

        ; 如果当前行已处理完成
        if (this.currentCharIndex >= StrLen(currentLine)) {
            ; 如果不是最后一行，发送换行符
            if (this.currentLineIndex < this.currentLines.Length - 1) {
                Send "{Enter}"
                Sleep this.inputDelay * 2
            }

            ; 移动到下一行
            this.currentLineIndex++
            this.currentCharIndex := 0

            ; 更新状态显示
            this.UpdateInputProgress()
            return
        }

        ; 处理当前字符
        if (currentLine != "") {
            char := SubStr(currentLine, this.currentCharIndex + 1, 1)

            ; 发送字符
            if (this.IsSpecialChar(char)) {
                this.SendSpecialChar(char)
            } else {
                Send "{Text}" char
            }
        }

        ; 移动到下一个字符
        this.currentCharIndex++

        ; 更新状态显示
        this.UpdateInputProgress()
    }

    ; 智能文本输入方法 - 正确处理多行文本（保持原有功能用于非模式调用）
    static SmartTypeText(text, delay := 10) {
        if (text = "") {
            return
        }

        ; 预处理文本：统一换行符格式
        text := StrReplace(text, "`r`n", "`n")  ; 将Windows换行符转换为单一换行符
        text := StrReplace(text, "`r", "`n")    ; 将Mac换行符转换为单一换行符

        ; 按行分割文本处理
        lines := StrSplit(text, "`n")

        Loop lines.Length {
            currentLine := lines[A_Index]

            ; 处理当前行的文本（包括空行）
            if (currentLine != "") {
                KeyboardInput.TypeLineText(currentLine, delay)
            }

            ; 如果不是最后一行，添加换行符（无论是否为空行）
            if (A_Index < lines.Length) {
                Send "{Enter}"
                Sleep delay * 2  ; 换行后稍长延迟
            }
        }
    }

    ; 输入单行文本（处理特殊字符）
    static TypeLineText(lineText, delay := 10) {
        if (lineText = "") {
            return
        }

        ; 使用混合模式：优先使用Text模式，特殊字符使用Raw模式
        i := 1
        while (i <= StrLen(lineText)) {
            char := SubStr(lineText, i, 1)

            ; 检查是否为特殊字符需要特殊处理
            if (KeyboardInput.IsSpecialChar(char)) {
                KeyboardInput.SendSpecialChar(char)
            } else {
                ; 使用Text模式发送普通字符
                Send "{Text}" char
            }

            Sleep delay
            i++
        }
    }

    ; 检查是否为需要特殊处理的字符
    static IsSpecialChar(char) {
        ; 使用Unicode码点范围判断中文标点符号
        charCode := Ord(char)

        ; 中文标点符号的主要Unicode范围：
        ; 0xFF00-0xFFEF: 全角ASCII、全角标点
        ; 0x3000-0x303F: CJK符号和标点
        ; 0x2010-0x2027: 通用标点符号
        ; 特别处理常见的中文标点符号
        if ((charCode >= 0xFF00 && charCode <= 0xFFEF) ||
            (charCode >= 0x3000 && charCode <= 0x303F) ||
            (charCode >= 0x2010 && charCode <= 0x2027)) {
            return true
        }

        ; 特别处理一些常见的中文标点符号
        specialChars := ["，", "。", "；", "：", "？", "！", "`"", "`"", "'", "'", "（", "）", "【", "】", "《", "》", "、", "…", "—", "·"]
        for specialChar in specialChars {
            if (char = specialChar) {
                return true
            }
        }

        return false
    }

    ; 发送特殊字符
    static SendSpecialChar(char) {
        ; 对于中文标点符号，使用多种方式尝试发送
        ; 方法1：直接使用SendText（推荐）
        try {
            SendText char
            return
        }

        ; 方法2：如果SendText失败，使用Unicode格式发送
        try {
            charCode := Ord(char)
            Send "{U+" Format("{:04X}", charCode) "}"
            return
        }

        ; 方法3：最后使用Raw模式
        Send "{Raw}" char
    }



    ; Raw模式输入方法：结合智能处理和Raw模式（适用于复杂文本）
    static RawTypeText(text, delay := 15) {
        if (text = "") {
            return
        }

        ; 使用混合模式：对所有字符都使用Raw模式发送
        ; 这样可以确保最大兼容性，包括特殊字符和中文标点
        Loop Parse, text {
            char := A_LoopField

            ; 对所有字符统一使用Raw模式，确保最大兼容性
            Send "{Raw}" char
            Sleep delay
        }
    }

    ; 显示输入状态OSD（跟随鼠标位置，避免闪烁）
    static ShowInputStatus(statusTextContent) {
        try {
            ; 如果状态OSD不存在或已被销毁，创建新的
            if (!this.statusOSD || !WinExist("ahk_id " this.statusOSD.Hwnd)) {
                ; 获取当前鼠标位置
                MouseGetPos(&mouseX, &mouseY)

                ; 创建新的状态OSD
                this.statusOSD := Gui("-Caption +ToolWindow +AlwaysOnTop -Border", "Input Status")
                this.statusOSD.MarginX := 8
                this.statusOSD.MarginY := 5
                this.statusOSD.BackColor := "0x2D2D30"  ; 深色背景

                ; 添加状态文本控件并保存引用
                this.statusText := this.statusOSD.AddText("cWhite w200 Center", statusTextContent)

                ; 显示在鼠标位置附近（右下方偏移）
                offsetX := 20  ; 向右偏移
                offsetY := 20  ; 向下偏移

                ; 确保不超出屏幕边界
                displayX := Min(mouseX + offsetX, A_ScreenWidth - 220)
                displayY := Min(mouseY + offsetY, A_ScreenHeight - 50)

                this.statusOSD.Show("NoActivate x" displayX " y" displayY " AutoSize")

                ; 设置透明度和圆角
                WinSetTransparent(200, this.statusOSD)

                ; 应用圆角效果
                hwnd := this.statusOSD.Hwnd
                WinGetPos(,, &width, &height, "ahk_id " hwnd)
                hRgn := CreateRoundRectRgn(0, 0, width, height, 8, 8)
                SetWindowRgn(hwnd, hRgn)
            } else {
                ; 如果窗口已存在，只更新文本内容，避免闪烁
                if (this.statusText) {
                    this.statusText.Text := statusTextContent
                }
            }

        } catch Error as e {
            Logger.LogError("KeyboardInput.ShowInputStatus", "显示状态失败: " e.message)
        }
    }

    ; 隐藏输入状态OSD
    static HideInputStatus() {
        try {
            if (this.statusOSD && WinExist("ahk_id " this.statusOSD.Hwnd)) {
                this.statusOSD.Destroy()
                this.statusOSD := ""
                this.statusText := ""  ; 清理文本控件引用
            }
        } catch Error as e {
            Logger.LogError("KeyboardInput.HideInputStatus", "隐藏状态失败: " e.message)
        }
    }

    ; 更新输入进度
    static UpdateInputProgress() {
        if (!this.isInputMode) {
            return
        }

        try {
            ; 计算总字符数和已输入字符数
            totalChars := StrLen(this.currentText)
            processedChars := 0

            ; 计算已处理的字符数
            Loop this.currentLineIndex {
                if (A_Index <= this.currentLines.Length) {
                    processedChars += StrLen(this.currentLines[A_Index])
                    if (A_Index < this.currentLineIndex) {
                        processedChars += 1  ; 换行符
                    }
                }
            }
            processedChars += this.currentCharIndex

            ; 计算进度百分比
            progress := totalChars > 0 ? Round((processedChars / totalChars) * 100) : 0

            ; 构建状态文本
            statusText := "输入中 " progress "% (" processedChars "/" totalChars ")"
            if (this.isPaused) {
                statusText := "已暂停 " progress "% (" processedChars "/" totalChars ")"
            }

            ; 更新状态显示
            this.ShowInputStatus(statusText)

        } catch Error as e {
            Logger.LogError("KeyboardInput.UpdateInputProgress", "更新进度失败: " e.message)
        }
    }

    ; 检查是否处于模拟输入模式
    static IsInputMode() {
        return this.isInputMode
    }

    ; 检查是否暂停状态
    static IsPaused() {
        return this.isPaused
    }
}

; 使用 Alt+v 触发模拟输入模式（推荐）
; 进入专门的模拟输入模式，支持暂停/继续和手动退出
!v:: {
    ; 获取剪贴板内容
    clipText := A_Clipboard

    if (clipText != "") {
        ; 短暂延迟，以便用户可以准备好
        Sleep 500

        ; 进入模拟输入模式
        if (KeyboardInput.EnterInputMode(clipText, Config.TYPING_DELAY_FAST)) {
            Logger.LogInfo("KeyboardInput", "进入模拟输入模式，字符数: " StrLen(clipText))
        } else {
            ShowOSD("无法进入模拟输入模式")
        }
    } else {
        ShowOSD("剪贴板为空")
    }
}

; 使用 Ctrl+Alt+v 触发慢速模拟输入模式
; 适用于对输入速度敏感的应用程序
^!v:: {
    ; 获取剪贴板内容
    clipText := A_Clipboard

    if (clipText != "") {
        ; 短暂延迟，以便用户可以准备好
        Sleep 500

        ; 进入慢速模拟输入模式
        if (KeyboardInput.EnterInputMode(clipText, Config.TYPING_DELAY_SLOW)) {
            Logger.LogInfo("KeyboardInput", "进入慢速模拟输入模式，字符数: " StrLen(clipText))
        } else {
            ShowOSD("无法进入模拟输入模式")
        }
    } else {
        ShowOSD("剪贴板为空")
    }
}

; 辅助函数用于#HotIf条件检查
IsKeyboardInputMode() {
    return KeyboardInput.IsInputMode()
}

; 模拟输入模式下的交互控制快捷键
#HotIf IsKeyboardInputMode()

; 空格键：暂停/继续输入
Space:: {
    KeyboardInput.TogglePause()
}

; ESC键：退出模拟输入模式
Escape:: {
    KeyboardInput.ExitInputMode()
}

#HotIf

; ========== 媒体控制快捷键（使用MediaControl类） ==========

; 播放/暂停
^!Space::MediaControl.PlayPause()  ; Ctrl + Alt + Space

; 下一首
^!Right::MediaControl.Next()  ; Ctrl + Alt + 右箭头

; 上一首
^!Left::MediaControl.Previous()  ; Ctrl + Alt + 左箭头

; 音量增加
^!Up::MediaControl.VolumeUp()  ; Ctrl + Alt + 上箭头

; 音量减小
^!Down::MediaControl.VolumeDown()  ; Ctrl + Alt + 下箭头

; 静音/取消静音
^!M::MediaControl.Mute()  ; Ctrl + Alt + M

; ========== 连点器功能 ==========

; 连点器类
class ClickRecorder {
    ; 激活连点器模式
    static ActivateMode() {
        global g_clickRecorder
        if (!g_clickRecorder.isPlaying) {
            g_clickRecorder.isActive := true
            g_clickRecorder.isRecording := false  ; 仅进入模式，不自动开始记录
            ShowOSD("进入连点器模式")
            Logger.LogInfo("ClickRecorder", "激活连点器模式")
        }
    }
    
    ; 重置记录并开始记录（按住Ctrl+左键时）
    static ResetAndStartRecording() {
        global g_clickRecorder
        if (g_clickRecorder.isActive && !g_clickRecorder.isPlaying) {
            g_clickRecorder.isRecording := true
            g_clickRecorder.positions := []  ; 清空之前的记录
            ShowOSD("重置记录，开始重新录入位置")
            Logger.LogInfo("ClickRecorder", "重置记录并开始记录")
        }
    }
    
    ; 停止记录
    static StopRecording() {
        global g_clickRecorder
        if (g_clickRecorder.isRecording) {
            g_clickRecorder.isRecording := false
            posCount := g_clickRecorder.positions.Length
            ShowOSD("记录完成: " posCount " 个位置")
            Logger.LogInfo("ClickRecorder", "记录完成，共" posCount "个位置")
        }
    }
    
    ; 退出连点器模式
    static ExitMode() {
        global g_clickRecorder
        if (g_clickRecorder.isActive) {
            g_clickRecorder.isActive := false
            g_clickRecorder.isRecording := false
            if (g_clickRecorder.isPlaying) {
                this.StopPlaying()
            }
            ShowOSD("退出连点器模式")
            Logger.LogInfo("ClickRecorder", "退出连点器模式")
        }
    }
    
    ; 记录当前鼠标位置
    static RecordPosition() {
        global g_clickRecorder
        if (g_clickRecorder.isRecording) {
            MouseGetPos(&x, &y)
            g_clickRecorder.positions.Push({x: x, y: y})
            posCount := g_clickRecorder.positions.Length
            ShowOSD("记录位置 " posCount ": (" x ", " y ")")
            Logger.LogInfo("ClickRecorder", "记录位置" posCount ": (" x ", " y ")")
        }
    }
    
    ; 开始播放记录的点击
    static StartPlaying(loops := -1) {
        global g_clickRecorder
        if (g_clickRecorder.isActive && !g_clickRecorder.isPlaying && g_clickRecorder.positions.Length > 0) {
            g_clickRecorder.isRecording := false  ; 停止记录
            g_clickRecorder.isPlaying := true
            g_clickRecorder.currentIndex := 0
            g_clickRecorder.loopCount := 0
            g_clickRecorder.maxLoops := loops
            
            ; 开始播放定时器
            g_clickRecorder.playTimer := () => this.PlayNextClick()
            SetTimer(g_clickRecorder.playTimer, g_clickRecorder.playInterval)
            
            loopText := (loops == -1) ? "无限" : String(loops)
            ShowOSD("开始播放 (" loopText " 循环)")
            Logger.LogInfo("ClickRecorder", "开始播放，循环次数: " loopText)
        }
    }
    
    ; 播放下一个点击
    static PlayNextClick() {
        global g_clickRecorder
        if (!g_clickRecorder.isPlaying || g_clickRecorder.positions.Length == 0) {
            return
        }
        
        ; 获取当前位置
        pos := g_clickRecorder.positions[g_clickRecorder.currentIndex + 1]
        
        ; 移动鼠标并点击
        MouseMove(pos.x, pos.y, 0)
        Click
        
        ; 更新索引
        g_clickRecorder.currentIndex++
        
        ; 检查是否完成一轮
        if (g_clickRecorder.currentIndex >= g_clickRecorder.positions.Length) {
            g_clickRecorder.currentIndex := 0
            g_clickRecorder.loopCount++
            
            ; 检查是否达到最大循环次数
            if (g_clickRecorder.maxLoops != -1 && g_clickRecorder.loopCount >= g_clickRecorder.maxLoops) {
                this.StopPlaying()
                return
            }
        }
    }
    
    ; 停止播放
    static StopPlaying() {
        global g_clickRecorder
        if (g_clickRecorder.isPlaying) {
            g_clickRecorder.isPlaying := false
            if (g_clickRecorder.playTimer) {
                SetTimer(g_clickRecorder.playTimer, 0)
                g_clickRecorder.playTimer := 0
            }
            ShowOSD("停止播放")
            Logger.LogInfo("ClickRecorder", "停止播放，完成" g_clickRecorder.loopCount "次循环")
        }
    }
    
    ; 调整播放速度
    static AdjustSpeed(delta) {
        global g_clickRecorder
        g_clickRecorder.playInterval := Max(Min(g_clickRecorder.playInterval + delta, 2000), 10)
        
        ; 如果正在播放，更新定时器
        if (g_clickRecorder.isPlaying && g_clickRecorder.playTimer) {
            SetTimer(g_clickRecorder.playTimer, g_clickRecorder.playInterval)
        }
        
        ShowOSD("播放间隔: " g_clickRecorder.playInterval "ms")
    }
    
    ; 清空记录
    static ClearRecords() {
        global g_clickRecorder
        if (!g_clickRecorder.isRecording && !g_clickRecorder.isPlaying) {
            g_clickRecorder.positions := []
            ShowOSD("清空记录")
            Logger.LogInfo("ClickRecorder", "清空所有记录")
        }
    }
    
    ; 获取状态信息
    static GetStatus() {
        global g_clickRecorder
        posCount := g_clickRecorder.positions.Length
        if (g_clickRecorder.isRecording) {
            return "记录中 (" posCount " 个位置)"
        } else if (g_clickRecorder.isPlaying) {
            return "播放中 (" (g_clickRecorder.currentIndex + 1) "/" posCount ")"
        } else if (posCount > 0) {
            return "已记录 " posCount " 个位置"
        } else {
            return "无记录"
        }
    }
}

; 连点器热键
^+d:: {  ; Ctrl+Shift+D：仅进入连点器模式
    ClickRecorder.ActivateMode()
}

; 辅助函数用于#HotIf条件检查
IsClickRecorderActive() {
    global g_clickRecorder
    return g_clickRecorder.isActive
}

IsRecording() {
    global g_clickRecorder
    return g_clickRecorder.isRecording
}

IsPlaying() {
    global g_clickRecorder
    return g_clickRecorder.isPlaying
}

; 连点器模式下的快捷键（只有在连点器模式激活时才生效）
#HotIf IsClickRecorderActive()

; 空格键：开始/停止无限循环播放
Space:: {
    global g_clickRecorder
    if (g_clickRecorder.isPlaying) {
        ClickRecorder.StopPlaying()
    } else {
        ClickRecorder.StartPlaying(-1)  ; 无限循环
    }
}

; ESC键：退出连点器模式
Escape:: {
    ClickRecorder.ExitMode()
}

; 按住Ctrl+点击：重置记录，重新记录点击位置
^LButton:: {
    ClickRecorder.ResetAndStartRecording()
    ; 不执行原始点击，避免干扰
}

; 播放速度调节（在连点器模式下）
^+NumpadAdd:: {  ; Ctrl+Shift+数字键盘+：加速
    ClickRecorder.AdjustSpeed(-20)
}

^+NumpadSub:: {  ; Ctrl+Shift+数字键盘-：减速
    ClickRecorder.AdjustSpeed(20)
}

#HotIf

; 记录点击位置（在记录模式下）
#HotIf IsRecording()
LButton:: {
    ClickRecorder.RecordPosition()
    ; 继续执行原始点击
    Click
}
#HotIf

; ========== 键盘锁定功能 ==========

; 辅助函数用于#HotIf条件检查
CheckKeyboardLocked() {
    global isKeyboardLocked
    return isKeyboardLocked
}

; Ctrl+Alt+L：锁定键盘
^!l:: {
    global isKeyboardLocked
    isKeyboardLocked := true
    ShowOSD("键盘已锁定")
}

; 添加鼠标双击解锁功能
#HotIf CheckKeyboardLocked()
LButton:: {
    global lastClickTime, isKeyboardLocked
    currentTime := A_TickCount
    
    ; 检查是否是双击（两次点击间隔小于配置的阈值）
    if (currentTime - lastClickTime < Config.DOUBLE_CLICK_THRESHOLD) {
        isKeyboardLocked := false
        ShowOSD("键盘已解锁")
        lastClickTime := 0  ; 重置点击时间
    } else {
        lastClickTime := currentTime
    }
}
#HotIf

; 当键盘锁定时，拦截所有按键（除了解锁组合键）
#HotIf CheckKeyboardLocked()
*a::Return
*b::Return
*c::Return
*d::Return
*e::Return
*f::Return
*g::Return
*h::Return
*i::Return
*j::Return
*k::Return
*l::Return
*m::Return
*n::Return
*o::Return
*p::Return
*q::Return
*r::Return
*s::Return
*t::Return
*u::Return
*v::Return
*w::Return
*x::Return
*y::Return
*z::Return
*1::Return
*2::Return
*3::Return
*4::Return
*5::Return
*6::Return
*7::Return
*8::Return
*9::Return
*0::Return
*-::Return
*=::Return
*[::Return
*]::Return
*\::Return
*;::Return
*'::Return
*,::Return
*.::Return
*/::Return
*`::Return
*Tab::Return
*CapsLock::Return
*Space::Return
*Enter::Return
*Backspace::Return
*Delete::Return
*Insert::Return
*Home::Return
*End::Return
*PgUp::Return
*PgDn::Return
*Up::Return
*Down::Return
*Left::Return
*Right::Return
*F1::Return
*F2::Return
*F3::Return
*F4::Return
*F5::Return
*F6::Return
*F7::Return
*F8::Return
*F9::Return
*F10::Return
*F11::Return
*F12::Return
*NumLock::Return
*NumpadDiv::Return
*NumpadMult::Return
*NumpadAdd::Return
*NumpadSub::Return
*NumpadEnter::Return
*NumpadDot::Return
*Numpad0::Return
*Numpad1::Return
*Numpad2::Return
*Numpad3::Return
*Numpad4::Return
*Numpad5::Return
*Numpad6::Return
*Numpad7::Return
*Numpad8::Return
*Numpad9::Return
*PrintScreen::Return
*ScrollLock::Return
*Pause::Return
*LWin::Return
*RWin::Return
*LShift::Return
*RShift::Return

; 拦截所有修饰键
*LAlt::Return
*RAlt::Return
*LControl::Return
*RControl::Return
#HotIf

; ========== 脚本退出处理 ==========
; 脚本退出时清理桌面时钟
OnExit(CleanupOnExit)

CleanupOnExit(*) {
    try {
        DesktopClock.Destroy()
        Logger.LogInfo("OnExit", "脚本退出，桌面时钟已清理")
    } catch Error as e {
        Logger.LogError("OnExit", "清理桌面时钟失败: " e.message)
    }
}
