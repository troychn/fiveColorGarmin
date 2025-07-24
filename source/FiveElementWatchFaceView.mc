import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.UserProfile;
import Toybox.Math;

/**
 * 五行配色表盘视图类
 * 基于传统五行理论的智能表盘
 */
class FiveElementWatchFaceView extends WatchUi.WatchFace {

    // 屏幕尺寸相关
    private var _centerX as Number = 0;
    private var _centerY as Number = 0;
    private var _radius as Number = 0;
    private var _screenWidth as Number = 0;
    private var _screenHeight as Number = 0;

    // 使用系统字体显示图标字符
    // private var _iconFont as WatchUi.FontResource or Null = null;

    // 五行颜色定义
    private var _fiveElementColors as Array<Number> = [
        0x00FF00, // 木 - 绿色
        0xFF0000, // 火 - 红色  
        0xFFFF00, // 土 - 黄色
        0xFFFFFF, // 金 - 白色
        0x0080FF  // 水 - 蓝色
    ];
    
    /**
     * 获取当前五行配色方案
     * @return 包含主色和次色的配色方案
     */
    private function getCurrentElementColors() as Dictionary {
        
        var colorSchemes = [
            // 0 - 默认配色方案（蓝色系）
            {
                "backgroundColor" => Graphics.COLOR_BLACK,  // 黑色背景
                "primaryColor" => 0x2196F3,    // 蓝色（时间刻度）
                "secondaryColor" => 0x1565C0,  // 深蓝色
                "mainNumbers" => 0xFFFF00,     // 黄色 (12,3,6,9)
                "otherNumbers" => 0x2196F3     // 蓝色 (其他数字)
            },
            // 1 - 木元素配色方案（绿色系）
            {
                "backgroundColor" => Graphics.COLOR_BLACK,
                "primaryColor" => 0x4CAF50,    // 绿色（时间刻度）
                "secondaryColor" => 0x2E7D32,  // 深绿色
                "mainNumbers" => 0x81C784,     // 淡绿色 (12,3,6,9)
                "otherNumbers" => 0x4CAF50     // 绿色 (其他数字)
            },
            // 2 - 火元素配色方案（红色系）
            {
                "backgroundColor" => Graphics.COLOR_BLACK,
                "primaryColor" => 0xF44336,    // 红色（时间刻度）
                "secondaryColor" => 0xC62828,  // 深红色
                "mainNumbers" => 0xFF8A80,     // 淡红色 (12,3,6,9)
                "otherNumbers" => 0xF44336     // 红色 (其他数字)
            },
            // 3 - 土元素配色方案（橙黄色系）
            {
                "backgroundColor" => Graphics.COLOR_BLACK,
                "primaryColor" => 0xFF9800,    // 橙色（时间刻度）
                "secondaryColor" => 0xE65100,  // 深橙色
                "mainNumbers" => 0xFFCC80,     // 淡橙色 (12,3,6,9)
                "otherNumbers" => 0xFF9800     // 橙色 (其他数字)
            },
            // 4 - 金元素配色方案（白银色系）
            {
                "backgroundColor" => Graphics.COLOR_BLACK,
                "primaryColor" => 0xFFFFFF,    // 白色（时间刻度）
                "secondaryColor" => 0xBDBDBD,  // 灰色
                "mainNumbers" => 0xFFFFFF,     // 白色 (12,3,6,9)
                "otherNumbers" => 0xBDBDBD     // 灰色 (其他数字)
            },
            // 5 - 水元素配色方案（蓝色系）
            {
                "backgroundColor" => Graphics.COLOR_BLACK,
                "primaryColor" => 0x2196F3,    // 蓝色（时间刻度）
                "secondaryColor" => 0x1565C0,  // 深蓝色
                "mainNumbers" => 0x90CAF9,     // 淡蓝色 (12,3,6,9)
                "otherNumbers" => 0x2196F3     // 蓝色 (其他数字)
            }
        ];
        
        // 确保_elementIndex是有效的数字
        var index = _elementIndex;
        if (index == null) {
            index = 0;
        } else if (!(index instanceof Number)) {
            index = 0;
        } else if (index < 0 || index >= colorSchemes.size()) {
            index = 0;
        }
        
        var selectedScheme = colorSchemes[index];
        
        return selectedScheme;
    }

    // 五行名称
    private var _fiveElementNames as Array<String> = ["Wood", "Fire", "Earth", "Metal", "Water"];

    // 中文字体资源
    private var chineseFont as WatchUi.FontResource or Null = null;
    
    // SVG图标资源
    private var heartIcon as WatchUi.BitmapResource or Null = null;
    private var stepsIcon as WatchUi.BitmapResource or Null = null;
    private var caloriesIcon as WatchUi.BitmapResource or Null = null;
    private var batteryIcon as WatchUi.BitmapResource or Null = null;
    private var weatherIcon as WatchUi.BitmapResource or Null = null;
    
    // 设置缓存变量
    private var _showSteps as Boolean = true;
    private var _showHeartRate as Boolean = true;
    private var _showCalories as Boolean = true;
    private var _showBattery as Boolean = true;
    private var _showWeather as Boolean = true;
    private var _showDateInfo as Boolean = true; // 显示日期农历星期信息
    private var _elementIndex as Number = 0; // 五行元素索引
    private var _timeFormat as Number = 0; // 0=24小时, 1=12小时
    private var _brightness as Number = 50;
    private var _colorTheme as Number = 0;
    private var _dataDisplayMode as Number = 0;
    private var _dataUpdateFrequency as Number = 1; // 数据更新频率
    private var _weatherDataSource as Number = 0; // 天气数据源
    private var _language as Number = 0; // 语言设置
    private var _settingsLoaded as Boolean = false;

    /**
     * 初始化方法
     */
    function initialize() {
        try {
            WatchFace.initialize();
            
            // 初始化默认值
            _showSteps = true;
            _showHeartRate = true;
            _showCalories = true;
            _showBattery = true;
            _showWeather = true;
            _showDateInfo = true;
            _elementIndex = 0;
            _timeFormat = 0;
            _brightness = 50;
            _colorTheme = 0;
            _dataDisplayMode = 0;
            _dataUpdateFrequency = 1;
            _weatherDataSource = 0;
            _language = 0;
            _settingsLoaded = false;
            
            // 加载设置
            loadSettings();
            
            // 加载中文字体
            try {
                chineseFont = WatchUi.loadResource(Rez.Fonts.chinese_font);
            } catch (ex) {
                chineseFont = null;
            }
            
            // 加载SVG图标资源
            try {
                heartIcon = WatchUi.loadResource(Rez.Drawables.HeartIcon);
                stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
                caloriesIcon = WatchUi.loadResource(Rez.Drawables.CaloriesIcon);
                batteryIcon = WatchUi.loadResource(Rez.Drawables.BatteryIcon);
                weatherIcon = WatchUi.loadResource(Rez.Drawables.WeatherIcon);
            } catch (ex) {
                heartIcon = null;
                stepsIcon = null;
                caloriesIcon = null;
                batteryIcon = null;
                weatherIcon = null;
            }
            
        } catch (ex) {
            // 如果初始化失败，设置默认值
            _showSteps = true;
            _showHeartRate = true;
            _showCalories = true;
            _showBattery = true;
            _showWeather = true;
            _showDateInfo = true;
            _elementIndex = 0;
            _timeFormat = 0;
            _brightness = 50;
            _colorTheme = 0;
            _dataDisplayMode = 0;
            _dataUpdateFrequency = 1;
            _weatherDataSource = 0;
            _language = 0;
            _settingsLoaded = false;
            chineseFont = null;
            heartIcon = null;
            stepsIcon = null;
            caloriesIcon = null;
            batteryIcon = null;
            weatherIcon = null;
        }
    }
    
    /**
     * 加载用户设置
     */
    private function loadSettings() as Void {
        try {
            var app = Application.getApp();
            
            // 读取显示设置
            var showStepsValue = app.getProperty("ShowSteps");
            _showSteps = showStepsValue;
            if (_showSteps == null) { 
                _showSteps = true; 
            }
            
            var showHeartRateValue = app.getProperty("ShowHeartRate");
            _showHeartRate = showHeartRateValue;
            if (_showHeartRate == null) { 
                _showHeartRate = true; 
            }
            
            var showCaloriesValue = app.getProperty("ShowCalories");
            _showCalories = showCaloriesValue;
            if (_showCalories == null) { 
                _showCalories = true; 
            }
            
            var showBatteryValue = app.getProperty("ShowBattery");
            _showBattery = showBatteryValue;
            if (_showBattery == null) { 
                _showBattery = true; 
            }
            
            var showWeatherValue = app.getProperty("ShowWeather");
            _showWeather = showWeatherValue;
            if (_showWeather == null) { 
                _showWeather = true; 
            }
            
            var showDateInfoValue = app.getProperty("ShowDateInfo");
            _showDateInfo = showDateInfoValue;
            if (_showDateInfo == null) { 
                _showDateInfo = true; 
            }
            
            // 读取五行元素设置
            var elementIndexValue = app.getProperty("ElementIndex");
            _elementIndex = elementIndexValue;
            if (_elementIndex == null) { 
                _elementIndex = 0; 
            }
            
            // 读取格式设置
            var timeFormatValue = app.getProperty("TimeFormat");
            _timeFormat = timeFormatValue;
            if (_timeFormat == null) { 
                _timeFormat = 0; 
            }
            
            var brightnessValue = app.getProperty("Brightness");
            _brightness = brightnessValue;
            if (_brightness == null) { 
                _brightness = 50; 
            }
            
            var colorThemeValue = app.getProperty("ColorTheme");
            _colorTheme = colorThemeValue;
            if (_colorTheme == null) { 
                _colorTheme = 0; 
            }
            
            var dataDisplayModeValue = app.getProperty("DataDisplayMode");
            _dataDisplayMode = dataDisplayModeValue;
            if (_dataDisplayMode == null) { 
                _dataDisplayMode = 0; 
            }
            
            // 读取新增设置项
            var dataUpdateFrequencyValue = app.getProperty("DataUpdateFrequency");
            _dataUpdateFrequency = dataUpdateFrequencyValue;
            if (_dataUpdateFrequency == null) { 
                _dataUpdateFrequency = 1; 
            }
            
            var weatherDataSourceValue = app.getProperty("WeatherDataSource");
            _weatherDataSource = weatherDataSourceValue;
            if (_weatherDataSource == null) { 
                _weatherDataSource = 0; 
            }
            
            var languageValue = app.getProperty("Language");
            _language = languageValue;
            if (_language == null) { 
                _language = 0; 
            }
            
            _settingsLoaded = true;
            
        } catch (ex) {
            // 设置加载失败时使用默认值
            _showSteps = true;
            _showHeartRate = true;
            _showCalories = true;
            _showBattery = true;
            _showWeather = true;
            _showDateInfo = true;
            _elementIndex = 0;
            _timeFormat = 0;
            _brightness = 50;
            _colorTheme = 0;
            _dataDisplayMode = 0;
            _dataUpdateFrequency = 1;
            _weatherDataSource = 0;
            _language = 0;
            _settingsLoaded = false;
        }
    }

    /**
     * 布局加载完成后调用
     * @param dc 绘图上下文
     */
    function onLayout(dc as Graphics.Dc) as Void {
        
        try {
            // 获取屏幕尺寸
            _screenWidth = dc.getWidth();
            _screenHeight = dc.getHeight();
            _centerX = (_screenWidth / 2).toNumber();
            _centerY = (_screenHeight / 2).toNumber();
            _radius = (_screenWidth < _screenHeight ? _screenWidth : _screenHeight) / 2 - 10;
            
        } catch (ex) {
            throw ex;
        }
        
        
        // 强制触发表盘更新
        WatchUi.requestUpdate();
    }

    /**
     * 表盘更新方法 - 完整五行表盘
     * @param dc 绘图上下文
     */
    public function onUpdate(dc as Graphics.Dc) as Void {
        try {
            // 确保屏幕尺寸已初始化
            if (_centerX == 0 || _centerY == 0) {
                _screenWidth = dc.getWidth();
                _screenHeight = dc.getHeight();
                _centerX = (_screenWidth / 2).toNumber();
                _centerY = (_screenHeight / 2).toNumber();
                _radius = (_screenWidth < _screenHeight ? _screenWidth : _screenHeight) / 2 - 10;
            }
            
            // 重新加载设置以确保最新配置生效
            loadSettings();
            
            // 获取当前五行配色方案
            var elementColors = getCurrentElementColors();
            
            // 1. 清除屏幕为五行配色背景
            dc.setColor(elementColors["backgroundColor"], elementColors["backgroundColor"]);
            dc.clear();
            
            // 2. 不绘制白色圆圈边框（已去掉）
            
            // 3. 绘制时间刻度
            drawHourMarks(dc);
            
            // 5. 移除重复的时间显示 - 时间将在drawCenterTimeInfo中绘制
            
            // 5. 绘制中心时间和日期信息
            drawCenterTimeInfo(dc);
            
            // 6. 绘制健康数据信息
            drawHealthData(dc);
            
            // 7. 绘制时分秒指针
            drawWatchHands(dc);
        } catch (ex) {
            // 绘制错误信息到屏幕
            try {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                dc.clear();
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_MEDIUM, "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 40, Graphics.FONT_SMALL, ex.getErrorMessage(), Graphics.TEXT_JUSTIFY_CENTER);
            } catch (ex2) {
                // 静默处理错误显示失败
            }
        }
    }

    /**
     * 绘制小时刻度 - 彩色数字
     */
    private function drawHourMarks(dc as Graphics.Dc) as Void {
        try {
            // 获取当前五行配色方案
            var elementColors = getCurrentElementColors();
            
            // 定义12个小时的颜色（根据用户需求：主要数字12、3、6、9为主要颜色，其他为次要颜色）
            var hourColors = [
                elementColors["mainNumbers"], // 12点 - 主要数字颜色
                elementColors["otherNumbers"], // 1点 - 其他数字颜色
                elementColors["otherNumbers"], // 2点 - 其他数字颜色
                elementColors["mainNumbers"], // 3点 - 主要数字颜色
                elementColors["otherNumbers"], // 4点 - 其他数字颜色
                elementColors["otherNumbers"], // 5点 - 其他数字颜色
                elementColors["mainNumbers"], // 6点 - 主要数字颜色
                elementColors["otherNumbers"], // 7点 - 其他数字颜色
                elementColors["otherNumbers"], // 8点 - 其他数字颜色
                elementColors["mainNumbers"], // 9点 - 主要数字颜色
                elementColors["otherNumbers"], // 10点 - 其他数字颜色
                elementColors["otherNumbers"]  // 11点 - 其他数字颜色
            ];
            
            for (var i = 0; i < 12; i++) {
                var angle = i * 30 * Math.PI / 180; // 每小时30度
                var hour = ((i == 0) ? 12 : i).toNumber(); // 确保hour是Number类型
                
                // 计算数字位置 - 重新设计位置算法，确保数字合理分布
                var baseDistance = _radius - 25; // 增加基础距离，让数字更靠近边缘
                var textX = _centerX + (baseDistance * Math.sin(angle)).toNumber();
                var textY = _centerY - (baseDistance * Math.cos(angle)).toNumber();
                
                // 根据用户要求进行精确调整：11、12、1点再向上移动3像素，其余9个数字再向上移动6像素
                if (i == 11 || i == 0 || i == 1) { // 11点、12点、1点位置
                    if (i == 0) { // 12点位置
                        textY -= 13; // 原来-10，现在再向上移动3像素，总共-13
                    } else if (i == 1) { // 1点位置
                        textX -= 6;
                        textY -= 11; // 原来-8，现在再向上移动3像素，总共-11
                    } else if (i == 11) { // 11点位置
                        textX += 6;
                        textY -= 11; // 原来-8，现在再向上移动3像素，总共-11
                    }
                } else { // 其余9个数字（2、3、4、5、6、7、8、9、10）再向上移动6像素
                    if (i == 6) { // 6点位置
                        textY -= 50; // 原来-45，现在再向上移动5像素，总共-50
                    } else if (i == 3) { // 3点位置
                        textX -= 12;
                        textY -= 29; // 原来-23，现在再向上移动6像素，总共-29
                    } else if (i == 9) { // 9点位置
                        textX += 12;
                        textY -= 29; // 原来-23，现在再向上移动6像素，总共-29
                    } else if (i == 2) { // 2点位置
                        textX -= 6;
                        textY -= 30; // 原来-24，现在再向上移动6像素，总共-30
                    } else if (i == 4 || i == 5) { // 4点和5点位置
                        textX -= 6;
                        textY -= 35; // 原来-29，现在再向上移动6像素，总共-35
                    } else if (i == 7 || i == 8) { // 7点和8点位置
                        textX += 6;
                        textY -= 35; // 原来-29，现在再向上移动6像素，总共-35
                    } else if (i == 10) { // 10点位置
                        textX += 9; // 原来+6，现在再向右移动3像素，总共+9
                        textY -= 30; // 原来-24，现在再向上移动6像素，总共-30
                    }
                }
                
                // 设置对应颜色并绘制小时数字 - 主要数字(12、3、6、9)使用FONT_MEDIUM，其他数字使用FONT_TINY
                dc.setColor(hourColors[i], Graphics.COLOR_TRANSPARENT);
                var fontSize = Graphics.FONT_MEDIUM; // 主要数字使用更大字体
                // 对于非主要数字(1、2、4、5、7、8、10、11)，使用更小的字体
                if (i != 0 && i != 3 && i != 6 && i != 9) { // 不是12、3、6、9点
                    fontSize = Graphics.FONT_TINY;
                }
                dc.drawText(textX, textY, fontSize, hour.toString(), Graphics.TEXT_JUSTIFY_CENTER);
                
                // 绘制小时刻度线 - 贴近表盘边缘，更长的刻度线
                var outerX = _centerX + ((_radius - 2) * Math.sin(angle)).toNumber();
                var outerY = _centerY - ((_radius - 2) * Math.cos(angle)).toNumber();
                var innerX = _centerX + ((_radius - 20) * Math.sin(angle)).toNumber();
                var innerY = _centerY - ((_radius - 20) * Math.cos(angle)).toNumber();
                dc.setColor(hourColors[i], Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(3);
                dc.drawLine(outerX, outerY, innerX, innerY);
            }
            
            // 绘制分钟刻度 - 使用次要颜色短刻度线
            dc.setColor(elementColors["secondaryColor"], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1); // 细线条
            
            for (var j = 0; j < 60; j++) {
                // 跳过已经绘制小时刻度的位置
                if (j % 5 != 0) {
                    var minuteAngle = j * 6 * Math.PI / 180; // 每分钟6度
                    
                    // 计算分钟刻度线位置 - 贴近表盘边缘，更短的刻度线
                    var outerX = _centerX + ((_radius - 2) * Math.sin(minuteAngle)).toNumber();
                    var outerY = _centerY - ((_radius - 2) * Math.cos(minuteAngle)).toNumber();
                    var innerX = _centerX + ((_radius - 10) * Math.sin(minuteAngle)).toNumber(); // 缩短长度
                    var innerY = _centerY - ((_radius - 10) * Math.cos(minuteAngle)).toNumber();
                    
                    dc.drawLine(outerX, outerY, innerX, innerY);
                    
                    // 每绘制10个分钟刻度输出一次调试信息
                    if (j % 10 == 1) {
                    }
                }
            }
            
        } catch (ex) {
        }
    }

    /**
     * 绘制五行配色圆点
     */
    private function drawFiveElementDots(dc as Graphics.Dc) as Void {
        try {
            // 在表盘顶部绘制五行配色圆点
            var dotY = _centerY - _radius + 50;
            var dotSpacing = 25;
            var startX = _centerX - (4 * dotSpacing) / 2;
            
            for (var i = 0; i < 5; i++) {
                var dotX = startX + (i * dotSpacing);
                dc.setColor(_fiveElementColors[i], Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, 8);
            }
            
            // 绘制"五行配色"标题
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, dotY - 25, Graphics.FONT_MEDIUM, Application.loadResource(Rez.Strings.FiveElementTitle), Graphics.TEXT_JUSTIFY_CENTER);
            
        } catch (ex) {
        }
    }
    
    /**
     * 绘制中心时间和日期信息
     */
    private function drawCenterTimeInfo(dc as Graphics.Dc) as Void {
        try {
            var clockTime = System.getClockTime();
            
            // 获取当前时间并格式化
            var now = Time.now();
            var today = Gregorian.info(now, Time.FORMAT_MEDIUM);
            
            // 绘制今日宜穿配色建议 - 注释掉避免乱码
            // dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // dc.drawText(_centerX, _centerY - 80, Graphics.FONT_SMALL, Application.loadResource(Rez.Strings.TodayClothingSuggestion), Graphics.TEXT_JUSTIFY_CENTER);
            
            // 绘制大号时间 - 根据设置应用时间格式
            var hour = clockTime.hour.toNumber();
            var min = clockTime.min.toNumber();
            var timeText = "";
            
            // 根据时间格式设置显示
            if (_timeFormat == 1) { // 12小时格式
                var displayHour = hour;
                var ampm = "AM";
                if (hour == 0) {
                    displayHour = 12;
                } else if (hour > 12) {
                    displayHour = hour - 12;
                    ampm = "PM";
                } else if (hour == 12) {
                    ampm = "PM";
                }
                var hourStr = displayHour.toString();
                var minStr = min < 10 ? "0" + min.toString() : min.toString();
                timeText = hourStr + ":" + minStr + " " + ampm;
            } else { // 24小时格式
                var hourStr = hour < 10 ? "0" + hour.toString() : hour.toString();
                var minStr = min < 10 ? "0" + min.toString() : min.toString();
                timeText = hourStr + ":" + minStr;
            }
            
            // 绘制时间文本
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, _centerY - 130, Graphics.FONT_SMALL, timeText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // 根据设置决定是否显示日期信息
            if (_showDateInfo) {
                // 确保获取正确的当前日期
                var currentYear = today.year;
                var currentMonth = today.month;
                var currentDay = today.day;
                
                // 格式化日期字符串 - 06/29 格式
                var monthNum = convertMonthToNumber(currentMonth);
                var dayNum = (currentDay != null && currentDay instanceof Number) ? currentDay : 27;
                var yearNum = (currentYear != null && currentYear instanceof Number) ? currentYear : 2024;
                
                var monthStr = monthNum < 10 ? "0" + monthNum.toString() : monthNum.toString();
                var dayStr = dayNum < 10 ? "0" + dayNum.toString() : dayNum.toString();
            
            // 使用修正的星期计算算法，基于2025年7月18日是星期五的基准
            var dayOfWeekNum = calculateDayOfWeek(yearNum, monthNum, dayNum);
            var weekdayIndex = dayOfWeekNum - 1;
            if (weekdayIndex < 0 || weekdayIndex >= 7) {
                weekdayIndex = 0; // 默认为星期日
            }
            // 绘制日期和星期在同一行，位置在时间下方，格式：06月29 星期日，整体下移20像素
            var dateString = monthStr + "月" + dayStr;
            
            // 设置日期和星期的统一字体大小和颜色为深绿色，与时间显示保持一致
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            
            // 调整位置：日期和星期在同一行，位于时间下方，整体下移20像素
            var dateWeekY = _centerY - 80;  // 位于时间下方，下移20像素
            
            // 使用资源文件中的星期名称
            var weekNames = ["日", "一", "二", "三", "四", "五", "六"];
            
            if (weekdayIndex >= 0 && weekdayIndex < weekNames.size()) {
                var weekText = "星期" + weekNames[weekdayIndex];
                
                // 计算农历日期
                var lunarDate = convertToLunar(currentYear, monthNum, dayNum);
                
                // 检查农历字符串是否有效
                if (lunarDate == null || lunarDate.equals("")) {
                    lunarDate = "农历未知";
                }
                
                // 使用自定义中文字体分别绘制日期、农历和星期文本，通过位置调整保持间距
                var fontToUse = (chineseFont != null) ? chineseFont : Graphics.FONT_TINY;
                
                // 分别绘制日期、农历和星期，避免使用空格字符
                // 计算文本宽度来确定合适的位置偏移
                var dateWidth = dc.getTextWidthInPixels(dateString, fontToUse);
                var lunarWidth = dc.getTextWidthInPixels(lunarDate, fontToUse);
                var weekWidth = dc.getTextWidthInPixels(weekText, fontToUse);
                var spacing = 8; // 每个元素之间的间距
                var totalWidth = dateWidth + lunarWidth + weekWidth + spacing * 2; // 总宽度包含两个间距
                
                // 计算起始位置，使整体居中
                var startX = _centerX - totalWidth / 2;
                
                // 设置文本颜色为绿色，与时间保持一致
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                
                // 绘制日期
                var dateX = startX + dateWidth / 2;
                dc.drawText(dateX, dateWeekY, fontToUse, dateString, Graphics.TEXT_JUSTIFY_CENTER);
                
                // 绘制农历（在日期右侧，保持间距）
                var lunarX = startX + dateWidth + spacing + lunarWidth / 2;
                dc.drawText(lunarX, dateWeekY, fontToUse, lunarDate, Graphics.TEXT_JUSTIFY_CENTER);
                
                // 绘制星期（在农历右侧，保持间距）
                var weekX = startX + dateWidth + spacing + lunarWidth + spacing + weekWidth / 2;
                dc.drawText(weekX, dateWeekY, fontToUse, weekText, Graphics.TEXT_JUSTIFY_CENTER);
                
                
                
                } else {
                    // 如果星期获取失败，只显示日期和农历
                    var lunarDate = convertToLunar(currentYear, monthNum, dayNum);
                    
                    // 检查农历字符串是否有效
                    if (lunarDate == null || lunarDate.equals("")) {
                        lunarDate = "农历未知";
                    }
                    var fontToUse = (chineseFont != null) ? chineseFont : Graphics.FONT_TINY;
                    
                    var dateWidth = dc.getTextWidthInPixels(dateString, fontToUse);
                    var lunarWidth = dc.getTextWidthInPixels(lunarDate, fontToUse);
                    var spacing = 8;
                    var totalWidth = dateWidth + lunarWidth + spacing;
                    var startX = _centerX - totalWidth / 2;
                    
                    // 设置文本颜色为绿色，与时间保持一致
                    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                    
                    // 绘制日期
                    dc.drawText(startX + dateWidth / 2, dateWeekY, fontToUse, dateString, Graphics.TEXT_JUSTIFY_CENTER);
                    
                    // 绘制农历
                    dc.drawText(startX + dateWidth + spacing + lunarWidth / 2, dateWeekY, fontToUse, lunarDate, Graphics.TEXT_JUSTIFY_CENTER);
                }
            } // 结束_showDateInfo条件判断
            
            
        } catch (ex) {
        }
    }

    /**
     * 绘制健康数据 - 心率、步数、卡路里、天气、电量
     * 按照用户要求的布局：
     * - 左上方红框：心率（红色心形图标）
     * - 右上方红框：步数（绿色脚印图标）
     * - 左下方红框：卡路里（火焰色火焰图标）
     * - 右下方红框：天气（天气图标，根据天气变化）
     * - 底部中间长方形：电量（电池图标平躺，左侧显示电量值）
     */
    private function drawHealthData(dc as Graphics.Dc) as Void {
        try {
            // 获取活动数据
            var activityInfo = null;
            try {
                activityInfo = ActivityMonitor.getInfo();
            } catch (ex) {
            }
            
            // 获取系统数据
            var systemStats = null;
            try {
                systemStats = System.getSystemStats();
            } catch (ex) {
            }
            
            // 获取心率数据 - 使用模拟数据（Connect IQ表盘无法直接获取实时心率）
   // 心率数据 - 获取真实心率
        var heartRate = getHeartRate();
            
            // 定义数据框的尺寸和位置
            var iconSize = 24; // 图标大小 (增加三分之一，从18增加到24)
            var verticalOffset = 0; // 垂直偏移量，可以调整整体位置
            
            // 左上方红框位置 - 心率 (向左移动10像素，向上移动15像素)
            var heartRateX = _centerX - 100;
            var heartRateY = _centerY - 35 + verticalOffset;
            
            // 右上方红框位置 - 步数 (向右移动18像素，向上移动15像素)
            var stepsX = _centerX + 93 + 5;
            var stepsY = _centerY - 35 + verticalOffset;
            
            // 左下方红框位置 - 卡路里 (向上移动12像素)
            var caloriesX = _centerX - 70;
            var caloriesY = _centerY + 55 + verticalOffset - 6 - 6;
            
            // 右下方红框位置 - 天气 (向上移动12像素)
            var weatherX = _centerX + 70;
            var weatherY = _centerY + 55 + verticalOffset - 6 - 6;
            
            // 底部中间长方形位置 - 电量 (向下移动6像素)
            var batteryX = _centerX - 15; // 整体向左移动15px
            var batteryY = _centerY + 116 + verticalOffset;
            
            // 1. 绘制心率数据 (左上方红框) - 根据设置显示
            if (_showHeartRate) {
                var heartRateValue = "--";
                if (heartRate != null) {
                    heartRateValue = heartRate.toString();
                }
                
                // 绘制心率图标 (使用SVG资源)
                if (heartIcon != null) {
                    dc.drawBitmap(heartRateX - iconSize/2, heartRateY - 6 - iconSize/2, heartIcon as WatchUi.BitmapResource);
                } else {
                    // 备用方案：绘制简单心形
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    drawHeartIcon(dc, heartRateX, heartRateY - 8, iconSize);
                }
                
                // 绘制心率数值 (使用最小字体，与图标大小匹配，颜色与心率图标一致)
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(heartRateX, heartRateY + 6, Graphics.FONT_SYSTEM_XTINY, heartRateValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 2. 绘制步数数据 (右上方红框) - 根据设置显示
            if (_showSteps) {
                var stepsValue = "--";
                if (activityInfo != null && activityInfo.steps != null) {
                    stepsValue = activityInfo.steps.toString();
                }
                
                // 绘制步数图标 (使用SVG资源)
                if (stepsIcon != null) {
                    dc.drawBitmap(stepsX - iconSize/2, stepsY - 6 - iconSize/2, stepsIcon as WatchUi.BitmapResource);
                } else {
                    // 备用方案：绘制简单脚印
                    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                    drawFootprintIcon(dc, stepsX, stepsY - 8, iconSize);
                }
                
                // 绘制步数数值 (使用最小字体，与图标大小匹配，颜色与步数图标一致)
                dc.setColor(0xFF9900, Graphics.COLOR_TRANSPARENT); // 橙色，与步数图标一致
                dc.drawText(stepsX, stepsY + 6, Graphics.FONT_SYSTEM_XTINY, stepsValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 3. 绘制卡路里数据 (左下方红框) - 根据设置显示
            if (_showCalories) {
                var caloriesValue = "--";
                if (activityInfo != null && activityInfo.calories != null) {
                    caloriesValue = activityInfo.calories.toString();
                }
                
                // 绘制卡路里图标 (使用SVG资源)
                if (caloriesIcon != null) {
                    dc.drawBitmap(caloriesX - iconSize/2, caloriesY - 6 - iconSize/2, caloriesIcon as WatchUi.BitmapResource);
                } else {
                    // 备用方案：绘制简单火焰
                    dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT); // 火焰色
                    drawFireIcon(dc, caloriesX, caloriesY - 8, iconSize);
                }
                
                // 绘制卡路里数值 (使用最小字体，与图标大小匹配，颜色与卡路里图标一致)
                dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT); // 火焰色
                dc.drawText(caloriesX, caloriesY + 6, Graphics.FONT_SYSTEM_XTINY, caloriesValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 4. 绘制天气数据 (右下方红框) - 根据设置显示
            if (_showWeather) {
                // 注意：Garmin Connect IQ SDK不直接提供天气数据，这里使用模拟数据
                var weatherData = getWeatherData();
                // 格式化温度显示，避免过多小数位
                var temperature = weatherData[:temperature];
                var weatherValue;
                if (temperature instanceof Float || temperature instanceof Double) {
                    // 四舍五入到整数
                    weatherValue = Math.round(temperature).toNumber().toString() + "°";
                } else {
                    weatherValue = temperature.toString() + "°";
                }
                var weatherCondition = weatherData[:condition]; // 可以是：sunny, cloudy, rainy, snowy等
                
                // 绘制天气图标 (使用SVG资源)
                if (weatherIcon != null) {
                    dc.drawBitmap(weatherX - iconSize/2, weatherY - 6 - iconSize/2, weatherIcon as WatchUi.BitmapResource);
                } else {
                    // 备用方案：绘制简单天气图标
                    drawWeatherIcon(dc, weatherX, weatherY - 8, iconSize, weatherCondition);
                }
                
                // 绘制天气数值 (使用最小字体，与图标大小匹配，颜色与天气图标一致)
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(weatherX, weatherY + 6, Graphics.FONT_SYSTEM_XTINY, weatherValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 5. 绘制电量数据 (底部中间长方形) - 根据设置显示
            if (_showBattery) {
                var batteryValue = "--";
                if (systemStats != null && systemStats.battery != null) {
                    var battery = systemStats.battery.toNumber();
                    batteryValue = battery.toString() + "%";
                }
                
                // 绘制电池图标 (平躺) - 精确控制间距
                // 重新设计布局：图标右边缘到文字左边缘的间距最小化
                var batteryIconX = batteryX - iconSize; // 图标完全位于batteryX左侧
                var batteryTextX = batteryX; // 文字紧贴batteryX，实现最小间距
                
                // 绘制电池图标 (使用SVG资源)
                if (batteryIcon != null) {
                    dc.drawBitmap(batteryIconX, batteryY - iconSize/2, batteryIcon as WatchUi.BitmapResource);
                } else {
                    // 备用方案：绘制简单电池图标
                    dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                    drawBatteryIcon(dc, batteryIconX, batteryY, iconSize);
                }
                
                // 绘制电量数值 (使用最小字体，与图标大小匹配)
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(batteryTextX, batteryY, Graphics.FONT_SYSTEM_XTINY, batteryValue, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            
        } catch (ex) {
        }
    }
    
    /**
     * 绘制心形图标 (基于HTML SVG的精致设计)
     */
    private function drawHeartIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        
        // 基于SVG路径的心形设计: M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z
        // 缩放到适合的尺寸
        var scale = size / 24.0;
        
        // 绘制心形主体 (更精确的形状)
        // 左上圆弧
        var leftCenterX = x - quarterSize;
        var leftCenterY = y - quarterSize + 2;
        dc.fillCircle(leftCenterX, leftCenterY, quarterSize + 1);
        
        // 右上圆弧
        var rightCenterX = x + quarterSize;
        var rightCenterY = y - quarterSize + 2;
        dc.fillCircle(rightCenterX, rightCenterY, quarterSize + 1);
        
        // 心形下半部分 (更流畅的曲线)
        var heartBottom = [
            [x - halfSize, y - 1],
            [x - quarterSize, y + quarterSize],
            [x, y + halfSize + 3],
            [x + quarterSize, y + quarterSize],
            [x + halfSize, y - 1],
            [x, y + 1]
        ];
        dc.fillPolygon(heartBottom);
        
        // 连接上下部分
        dc.fillRectangle(x - halfSize, y - quarterSize + 2, size, quarterSize + 3);
        
        // 添加高光效果
        dc.setColor(0xFF6666, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - quarterSize/2, y - quarterSize/2, 2);
    }
    
    /**
     * 绘制步数图标 (基于HTML SVG的人形设计)
     */
    private function drawFootprintIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        var eighthSize = size / 8;
        
        // 基于SVG路径的人形步数图标: M13.5 5.5c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zM9.8 8.9L7 23h2.1l1.8-8 2.1 2v6h2v-7.5l-2.1-2 .6-3C14.8 12 16.8 13 19 13v-2c-1.9 0-3.5-.8-4.3-2.1l-1-1.6c-.4-.6-1-1-1.7-1-.3 0-.5.1-.8.1L9 8.3V13h2V9.6l-.2-.7z
        
        // 绘制人形头部
        dc.fillCircle(x + quarterSize, y - halfSize + 2, quarterSize - 1);
        
        // 绘制身体主干
        dc.fillRectangle(x + quarterSize - 2, y - quarterSize + 2, 4, halfSize + 2);
        
        // 绘制左臂
        var leftArm = [
            [x - quarterSize, y - quarterSize + 4],
            [x + quarterSize - 2, y - eighthSize],
            [x + quarterSize - 2, y - eighthSize + 3],
            [x - quarterSize + 2, y - quarterSize + 7]
        ];
        dc.fillPolygon(leftArm);
        
        // 绘制右臂
        var rightArm = [
            [x + quarterSize + 2, y - eighthSize],
            [x + halfSize + 2, y - quarterSize + 4],
            [x + halfSize, y - quarterSize + 7],
            [x + quarterSize + 2, y - eighthSize + 3]
        ];
        dc.fillPolygon(rightArm);
        
        // 绘制左腿 (行走姿态)
        var leftLeg = [
            [x + quarterSize - 2, y + quarterSize - 2],
            [x - eighthSize, y + halfSize + 4],
            [x - eighthSize + 2, y + halfSize + 6],
            [x + quarterSize, y + quarterSize]
        ];
        dc.fillPolygon(leftLeg);
        
        // 绘制右腿 (行走姿态)
        var rightLeg = [
            [x + quarterSize, y + quarterSize - 2],
            [x + halfSize + 2, y + halfSize + 4],
            [x + halfSize + 4, y + halfSize + 6],
            [x + quarterSize + 2, y + quarterSize]
        ];
        dc.fillPolygon(rightLeg);
        
        // 添加动感效果线条
        dc.setColor(0x88FF88, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(x - halfSize, y, x - quarterSize, y - 2);
        dc.drawLine(x - halfSize + 2, y + 2, x - quarterSize + 2, y);
    }
    
    /**
     * 绘制火焰图标 (基于HTML SVG的精致火焰设计)
     */
    private function drawFireIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        var eighthSize = size / 8;
        
        // 基于SVG路径的火焰设计: M13.5 0.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 3.73-2.07 0-3.63-1.67-3.63-3.73l0.03-0.36C5.21 7.51 4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 17.41 3.8 13.5 0.67z
        
        // 绘制火焰主体外层
        var outerFlame = [
            [x - halfSize + 1, y + halfSize],
            [x - quarterSize - 2, y + quarterSize],
            [x - quarterSize, y - eighthSize],
            [x - eighthSize, y - quarterSize - 2],
            [x, y - halfSize - 2],
            [x + eighthSize, y - quarterSize - 2],
            [x + quarterSize, y - eighthSize],
            [x + quarterSize + 2, y + quarterSize],
            [x + halfSize - 1, y + halfSize]
        ];
        dc.fillPolygon(outerFlame);
        
        // 绘制火焰中层 (橙红色)
        dc.setColor(0xFF4400, Graphics.COLOR_TRANSPARENT);
        var middleFlame = [
            [x - quarterSize, y + quarterSize - 2],
            [x - eighthSize - 1, y + eighthSize],
            [x - eighthSize/2, y - eighthSize],
            [x, y - quarterSize],
            [x + eighthSize/2, y - eighthSize],
            [x + eighthSize + 1, y + eighthSize],
            [x + quarterSize, y + quarterSize - 2]
        ];
        dc.fillPolygon(middleFlame);
        
        // 绘制火焰内核 (明亮橙色)
        dc.setColor(0xFF8800, Graphics.COLOR_TRANSPARENT);
        var innerFlame = [
            [x - eighthSize, y + eighthSize],
            [x - 2, y],
            [x, y - eighthSize - 1],
            [x + 2, y],
            [x + eighthSize, y + eighthSize]
        ];
        dc.fillPolygon(innerFlame);
        
        // 添加火焰高光
        dc.setColor(0xFFCC44, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - 2, y - 2, 2);
        
        // 恢复原色
        dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT);
    }
    
    /**
     * 绘制天气图标 (基于HTML SVG的太阳设计)
     */
    /**
     * 获取真实心率数据
     * @return 心率值，如果无法获取则返回默认值
     */
    private function getHeartRate() as Number {
        try {
            var iterator = ActivityMonitor.getHeartRateHistory(null, false);
            if (iterator != null) {
                var sample = iterator.next();
                if (sample != null && sample.heartRate != null) {
                    return sample.heartRate;
                }
            }
        } catch (ex) {
            // 忽略异常，返回默认值
        }
        return 72; // 默认心率
    }

    /**
     * 获取真实天气数据
     * @return 包含温度和天气状况的字典
     */
    private function getWeatherData() as Dictionary {
        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null) {
                var temperature = 25; // 默认温度
                var condition = "sunny"; // 默认天气状况
                
                // 获取温度
                if (conditions.temperature != null) {
                    temperature = conditions.temperature;
                }
                
                // 获取天气状况
                if (conditions.condition != null) {
                    condition = mapWeatherCondition(conditions.condition);
                }
                
                return {
                    :temperature => temperature,
                    :condition => condition
                };
            }
        } catch (ex) {
            // 忽略异常，返回默认值
        }
        
        // 返回默认天气数据
        return {
            :temperature => 25,
            :condition => "sunny"
        };
    }

    /**
     * 将Garmin天气状况映射为我们的图标类型
     * @param condition Garmin天气状况
     * @return 对应的图标类型
     */
    private function mapWeatherCondition(condition as Number) as String {
        // Garmin Weather条件常量映射
        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_PARTLY_CLEAR:
                return "sunny";
            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLOUDY:
                return "cloudy";
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
                return "rainy";
            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
                return "snowy";
            default:
                return "sunny";
        }
    }

    private function drawWeatherIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number, condition as String) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        var eighthSize = size / 8;
        
        // 基于SVG路径的太阳设计: M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zM13 .55h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-1.41 15.7l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8zM20 10.5v2h3v-2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6z
        
        if (condition.equals("sunny")) {
            // 绘制太阳核心
            dc.setColor(0xFFDD00, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, halfSize - 1);
            
            // 绘制太阳内核高光
            dc.setColor(0xFFFF44, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, quarterSize);
            
            // 绘制8条主要光芒 (基于SVG设计)
            dc.setColor(0xFFCC00, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            
            // 上方光芒
            dc.drawLine(x, y - halfSize - 3, x, y - halfSize - 6);
            // 下方光芒
            dc.drawLine(x, y + halfSize + 3, x, y + halfSize + 6);
            // 左方光芒
            dc.drawLine(x - halfSize - 3, y, x - halfSize - 6, y);
            // 右方光芒
            dc.drawLine(x + halfSize + 3, y, x + halfSize + 6, y);
            
            // 对角线光芒
            var diagOffset = (halfSize + 3) * 0.707; // 45度角
            var diagOffsetLong = (halfSize + 6) * 0.707;
            
            // 左上
            dc.drawLine(x - diagOffset, y - diagOffset, x - diagOffsetLong, y - diagOffsetLong);
            // 右上
            dc.drawLine(x + diagOffset, y - diagOffset, x + diagOffsetLong, y - diagOffsetLong);
            // 左下
            dc.drawLine(x - diagOffset, y + diagOffset, x - diagOffsetLong, y + diagOffsetLong);
            // 右下
            dc.drawLine(x + diagOffset, y + diagOffset, x + diagOffsetLong, y + diagOffsetLong);
            
            // 添加太阳中心亮点
            dc.setColor(0xFFFFAA, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x - 2, y - 2, 2);
            
        } else if (condition.equals("cloudy")) {
            // 绘制云朵
            dc.setColor(0xCCCCCC, Graphics.COLOR_TRANSPARENT);
            
            // 云朵主体 (多个重叠的圆形)
            dc.fillCircle(x - quarterSize, y + 1, quarterSize + 1);
            dc.fillCircle(x + quarterSize, y + 1, quarterSize + 1);
            dc.fillCircle(x - eighthSize, y - quarterSize + 2, quarterSize);
            dc.fillCircle(x + eighthSize, y - quarterSize + 2, quarterSize);
            dc.fillCircle(x, y, halfSize);
            
            // 添加云朵高光
            dc.setColor(0xEEEEEE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x - quarterSize + 2, y - 2, quarterSize - 1);
            
        } else {
            // 默认太阳图标
            dc.setColor(0xFFDD00, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, halfSize - 1);
            dc.setColor(0xFFFF44, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, quarterSize);
            
            // 简化光芒
            dc.setColor(0xFFCC00, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(x, y - halfSize - 4, x, y - halfSize - 7);
            dc.drawLine(x, y + halfSize + 4, x, y + halfSize + 7);
            dc.drawLine(x - halfSize - 4, y, x - halfSize - 7, y);
            dc.drawLine(x + halfSize + 4, y, x + halfSize + 7, y);
        }
    }
    
    /**
     * 绘制电池图标 (精致平躺风格)
     */
    private function drawBatteryIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var width = size * 1.6;
        var height = size * 0.9;
        var capWidth = size * 0.25;
        var capHeight = size * 0.5;
        
        // 绘制电池外框阴影效果
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(x - width/2 + 1, y - height/2 + 1, width, height);
        
        // 绘制电池主体外框 (更精致的边框)
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - width/2, y - height/2, width, height);
        
        // 绘制电池正极头部 (更立体的效果)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + width/2, y - capHeight/2, capWidth, capHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(x + width/2, y - capHeight/2, capWidth, capHeight);
        
        // 获取电池电量
        var batteryLevel = 0.75; // 默认75%电量
        if (System.getSystemStats() != null && System.getSystemStats().battery != null) {
            batteryLevel = System.getSystemStats().battery / 100.0;
        }
        
        // 固定使用绿色 (根据用户要求)
        var fillColor = Graphics.COLOR_GREEN;
        var highlightColor = 0x66FF66; // 浅绿色高光
        
        // 绘制电池电量填充 (带渐变效果)
        var fillWidth = (width - 6) * batteryLevel;
        if (fillWidth > 2) {
            // 主填充色
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x - width/2 + 3, y - height/2 + 3, fillWidth, height - 6);
            
            // 添加高光效果 (顶部1/3区域)
            dc.setColor(highlightColor, Graphics.COLOR_TRANSPARENT);
            var highlightHeight = (height - 6) / 3;
            dc.fillRectangle(x - width/2 + 3, y - height/2 + 3, fillWidth, highlightHeight);
        }
        
        // 添加电池内部分段指示器 (更精致的设计)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 1; i < 4; i++) {
            var lineX = x - width/2 + (width * i / 4);
            // 只在未填充区域绘制分段线
            if (lineX > x - width/2 + 3 + fillWidth) {
                dc.drawLine(lineX, y - height/2 + 2, lineX, y + height/2 - 2);
            }
        }
        
        // 添加电池外框内侧高光
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(x - width/2 + 1, y - height/2 + 1, x + width/2 - 1, y - height/2 + 1);
        dc.drawLine(x - width/2 + 1, y - height/2 + 1, x - width/2 + 1, y + height/2 - 1);
    }

    /**
     * 传统五行纳甲算法 - 根据日期计算五行配色
     * 基于天干地支、五行相生相克理论
     * @return 包含最吉、次吉、平吉颜色的数组
     */
    /**
     * 将 Garmin 月份枚举或字符串转换为数字
     * @param monthEnum Gregorian 月份枚举或字符串
     * @return 月份数字 (1-12)
     */
    private function convertMonthToNumber(monthEnum) as Number {
        if (monthEnum == null) { 
            return 6; 
        }
        
        // 调试信息：记录原始月份数据类型和值
        var monthType = "unknown";
        var monthValue = "null";
        
        try {
            if (monthEnum instanceof Number) {
                monthType = "Number";
                monthValue = monthEnum.toString();
            } else if (monthEnum instanceof String) {
                monthType = "String";
                monthValue = monthEnum;
            } else {
                monthType = "Enum";
                monthValue = "enum_value";
            }
        } catch (ex) {
            monthType = "error";
        }
        
        // 优先处理数字类型（真机环境常见）
        if (monthEnum instanceof Number) {
            var numValue = monthEnum.toNumber();
            
            // 检测月份范围并进行相应转换
            if (numValue >= 1 && numValue <= 12) {
                // 标准1-12范围，直接返回
                return numValue;
            } else if (numValue >= 0 && numValue <= 11) {
                // 0-11范围（真机常见），转换为1-12
                var convertedValue = numValue + 1;
                return convertedValue;
            } else {
                // 超出范围，使用当前系统时间的月份作为备用
                var currentTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
                var fallbackMonth = 7; // 默认7月
                try {
                    if (currentTime != null && currentTime.month != null) {
                        // 递归调用自身来处理系统时间的月份
                        fallbackMonth = convertMonthToNumber(currentTime.month);
                    }
                } catch (ex) {
                    // 如果获取系统时间失败，使用默认值
                }
                return fallbackMonth;
            }
        }
        
        // 处理字符串格式的月份
        if (monthEnum instanceof String) {
            var monthStr = monthEnum.toString();
            if (monthStr.equals("Jan") || monthStr.equals("January")) { return 1; }
            if (monthStr.equals("Feb") || monthStr.equals("February")) { return 2; }
            if (monthStr.equals("Mar") || monthStr.equals("March")) { return 3; }
            if (monthStr.equals("Apr") || monthStr.equals("April")) { return 4; }
            if (monthStr.equals("May")) { return 5; }
            if (monthStr.equals("Jun") || monthStr.equals("June")) { return 6; }
            if (monthStr.equals("Jul") || monthStr.equals("July")) { return 7; }
            if (monthStr.equals("Aug") || monthStr.equals("August")) { return 8; }
            if (monthStr.equals("Sep") || monthStr.equals("September")) { return 9; }
            if (monthStr.equals("Oct") || monthStr.equals("October")) { return 10; }
            if (monthStr.equals("Nov") || monthStr.equals("November")) { return 11; }
            if (monthStr.equals("Dec") || monthStr.equals("December")) { return 12; }
            
            // 尝试直接转换数字字符串
            try {
                var numFromStr = monthStr.toNumber();
                if (numFromStr != null && numFromStr >= 1 && numFromStr <= 12) {
                    return numFromStr;
                }
            } catch (ex) {
                // 转换失败，继续其他处理
            }
        }
        
        // 处理 Gregorian 月份枚举（模拟器环境常见）
        try {
            switch (monthEnum) {
                case Gregorian.MONTH_JANUARY:
                    return 1;
                case Gregorian.MONTH_FEBRUARY:
                    return 2;
                case Gregorian.MONTH_MARCH:
                    return 3;
                case Gregorian.MONTH_APRIL:
                    return 4;
                case Gregorian.MONTH_MAY:
                    return 5;
                case Gregorian.MONTH_JUNE:
                    return 6;
                case Gregorian.MONTH_JULY:
                    return 7;
                case Gregorian.MONTH_AUGUST:
                    return 8;
                case Gregorian.MONTH_SEPTEMBER:
                    return 9;
                case Gregorian.MONTH_OCTOBER:
                    return 10;
                case Gregorian.MONTH_NOVEMBER:
                    return 11;
                case Gregorian.MONTH_DECEMBER:
                    return 12;
                default:
                    return 6; // 默认6月
            }
        } catch (ex) {
            // 枚举处理失败，返回默认值
            return 6;
        }
    }
    
    /**
     * 使用蔡勒公式计算星期
     * @param year 年份
     * @param month 月份 (1-12)
     * @param day 日期
     * @return 星期数字 (1-7, 1=周日)
     */
    private function calculateDayOfWeek(year as Number, month as Number, day as Number) as Number {
        // 使用基于已知基准日期的相对计算方法
        // 基准：2025年7月18日是星期五（dayOfWeek = 6）
        var baseYear = 2025;
        var baseMonth = 7;
        var baseDay = 18;
        var baseDayOfWeek = 6; // 星期五
        
        // 计算目标日期与基准日期的天数差
        var targetDays = calculateDaysSince1900(year, month, day);
        var baseDays = calculateDaysSince1900(baseYear, baseMonth, baseDay);
        var daysDiff = targetDays - baseDays;
        
        // 计算星期（daysDiff可能为负数）
        var dayOfWeek = baseDayOfWeek + (daysDiff % 7);
        
        // 确保结果在1-7范围内
        while (dayOfWeek <= 0) {
            dayOfWeek += 7;
        }
        while (dayOfWeek > 7) {
            dayOfWeek -= 7;
        }
        
        return dayOfWeek;
    }
    
    /**
     * 计算指定日期距离1900年1月1日的天数
     * @param year 年份
     * @param month 月份
     * @param day 日期
     * @return 天数
     */
    private function calculateDaysSince1900(year as Number, month as Number, day as Number) as Number {
        var totalDays = 0;
        
        // 计算年份贡献的天数
        for (var y = 1900; y < year; y++) {
            if (isLeapYear(y)) {
                totalDays += 366;
            } else {
                totalDays += 365;
            }
        }
        
        // 计算月份贡献的天数
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (isLeapYear(year)) {
            daysInMonth[1] = 29;
        }
        
        for (var m = 1; m < month; m++) {
            totalDays += daysInMonth[m - 1];
        }
        
        // 加上当月的天数
        totalDays += day;
        
        return totalDays;
    }

    /**
     * 计算指定日期的五行配色
     * @param today 日期信息对象，如果为null则使用当前日期
     * @return 包含时针、分针、秒针颜色的数组 [大吉色, 次吉色, 平平色]
     */
    private function calculateDailyFiveElementColors(today) as Array {
        try {
            // 如果没有传入日期参数，则使用当前日期
            if (today == null) {
                today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            }
            
            // 获取当前日期
            var year = today.year;
            var month = today.month;
            var day = today.day;
            
            
            // 安全转换为数字类型
            var yearNum = (year != null && year instanceof Number) ? year : 2025;
            var monthNum = convertMonthToNumber(month);
            var dayNum = (day != null && day instanceof Number) ? day : 29;
            
            
            // 修正的传统五行纳甲算法 - 基于天干地支计算日五行
            // 1. 计算年天干：(年份-4) % 10
            var yearTianGan = (yearNum - 4) % 10;
            
            // 2. 计算年地支：(年份-4) % 12
            var yearDiZhi = (yearNum - 4) % 12;
            
            // 3. 计算日天干地支（简化算法）
            var dayOfYear = getDayOfYear(monthNum, dayNum, yearNum);
            var dayTianGan = (yearTianGan * 5 + monthNum * 2 + dayNum) % 10;
            var dayDiZhi = (dayOfYear + yearDiZhi) % 12;
            
            // 5. 根据日地支确定日五行
            // 地支五行对应：子亥水，寅卯木，巳午火，申酉金，辰戌丑未土
            var dayElement;
            if (dayDiZhi == 0 || dayDiZhi == 11) {      // 子、亥 - 水
                dayElement = 4; // 水
            } else if (dayDiZhi == 2 || dayDiZhi == 3) { // 寅、卯 - 木
                dayElement = 0; // 木
            } else if (dayDiZhi == 5 || dayDiZhi == 6) { // 巳、午 - 火
                dayElement = 1; // 火
            } else if (dayDiZhi == 8 || dayDiZhi == 9) { // 申、酉 - 金
                dayElement = 3; // 金
            } else {                                      // 辰、戌、丑、未 - 土
                dayElement = 2; // 土
            }
            
            // 6. 根据五行相生理论计算配色
            // 五行相生：木生火，火生土，土生金，金生水，水生木
            // 大吉色：日五行所生的五行（火生土，所以火日大吉为土-黄色）
            // 次吉色：与日五行相同的五行
            // 平平色：克日五行的五行（水克火，所以火日平平为水-黑色）
            var mostLucky = (dayElement + 1) % 5;        // 大吉：日五行生的五行
            var secondLucky = dayElement;                // 次吉：日五行本身
            var normalLucky = (dayElement + 3) % 5;      // 平平：克日五行的五行
            
            // 7. 定义五行颜色映射
            var elementColorMap = [
                0x00FF00,  // 木 - 绿色
                0xFF0000,  // 火 - 红色
                0xFFFF00,  // 土 - 黄色
                0xFFFFFF,  // 金 - 白色
                0x000000   // 水 - 纯黑色（有白色边框，无需担心与背景重叠）
            ];
            
            var colors = [
                elementColorMap[mostLucky],    // 时针颜色（大吉）
                elementColorMap[secondLucky],  // 分针颜色（次吉）
                elementColorMap[normalLucky]   // 秒针颜色（平平）
            ];
            
            var elementNames = ["木", "火", "土", "金", "水"];
            var diZhiNames = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];
            
            // 定义五行对应的中文颜色描述
            var elementColorNames = ["绿色", "红色", "黄色", "白色", "黑色"];
            
            
            return colors;
        } catch (ex) {
            // 默认返回黄红黑配色（2025年6月29日的正确配色）
            return [0xFFFF00, 0xFF0000, 0x000000];
        }
    }
    
    /**
     * 计算某日是一年中的第几天
     * @param month 月份
     * @param day 日期
     * @param year 年份
     * @return 年积日
     */
    private function getDayOfYear(month as Number, day as Number, year as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        
        // 判断闰年
        if (isLeapYear(year)) {
            daysInMonth[1] = 29;
        }
        
        var dayOfYear = day;
        for (var i = 0; i < month - 1; i++) {
            dayOfYear += daysInMonth[i];
        }
        
        return dayOfYear;
    }
    
    /**
     * 判断是否为闰年
     * @param year 年份
     * @return 是否为闰年
     */
    private function isLeapYear(year as Number) as Boolean {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }

    /**
     * 获取明日的五行配色
     * @return 包含明日时针、分针、秒针颜色的数组 [大吉色, 次吉色, 平平色]
     */
    private function getTomorrowFiveElementColors() as Array {
        try {
            // 获取明日的日期
            var tomorrow = new Time.Moment(Time.now().value() + 24 * 60 * 60);
            var tomorrowInfo = Gregorian.info(tomorrow, Time.FORMAT_MEDIUM);
            
            // 计算明日的五行配色
            return calculateDailyFiveElementColors(tomorrowInfo);
        } catch (ex) {
            // 如果出错，返回默认配色
            return calculateDailyFiveElementColors(null);
        }
    }

    /**
     * 获取指定日期偏移的五行配色
     * @param dayOffset 日期偏移量（0=今天，1=明天，-1=昨天）
     * @return 包含指定日期时针、分针、秒针颜色的数组 [大吉色, 次吉色, 平平色]
     */
    private function getFiveElementColorsByOffset(dayOffset as Number) as Array {
        try {
            // 计算目标日期
            var targetMoment = new Time.Moment(Time.now().value() + dayOffset * 24 * 60 * 60);
            var targetInfo = Gregorian.info(targetMoment, Time.FORMAT_MEDIUM);
            
            // 计算目标日期的五行配色
            return calculateDailyFiveElementColors(targetInfo);
        } catch (ex) {
            // 如果出错，返回当前日期的配色
            return calculateDailyFiveElementColors(null);
        }
    }

    /**
     * 农历计算函数 - 将公历日期转换为农历日期
     * 基于农历算法的动态计算，支持任意年份
     * @param year 公历年份
     * @param month 公历月份
     * @param day 公历日期
     * @return 农历日期字符串，格式如"六月十六"
     */
    private function convertToLunar(year as Number, month as Number, day as Number) as String {
        
        // 农历月份名称
        var lunarMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"];
        
        // 农历日期名称
        var lunarDays = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ];
        
        // 直接使用改进的农历算法进行动态计算，移除try-catch避免调用错误的备用算法
        var lunarResult = calculateLunarDate(year, month, day);
        var lunarMonthObj = lunarResult.get("month");
        var lunarDayObj = lunarResult.get("day");
        var isLeapMonth = lunarResult.hasKey("isLeapMonth") ? lunarResult.get("isLeapMonth") : false;
        

        
        // 安全的类型转换和范围检查
        var lunarMonth = 1;
        var lunarDay = 1;
        
        if (lunarMonthObj != null) {
             try {
                 lunarMonth = (lunarMonthObj as Number).toNumber();
                 if (lunarMonth < 1) { lunarMonth = 1; }
                 if (lunarMonth > 12) { lunarMonth = 12; }
             } catch (ex) {
                 lunarMonth = 1;
             }
         }
         
         if (lunarDayObj != null) {
             try {
                 lunarDay = (lunarDayObj as Number).toNumber();
                 if (lunarDay < 1) { lunarDay = 1; }
                 if (lunarDay > 30) { lunarDay = 30; }
             } catch (ex) {
                 lunarDay = 1;
             }
         }
        
        isLeapMonth = (isLeapMonth != null) ? isLeapMonth : false;
        
        var monthStr = lunarMonths[lunarMonth - 1] + "月";
        if (isLeapMonth) {
            monthStr = "闰" + monthStr;
        }
        
        var finalResult = monthStr + lunarDays[lunarDay - 1];
        
        return finalResult;
    }
    
    /**
     * 计算儒略日数 - 基于6tail/lunar标准算法
     * 参考6tail/lunar-javascript项目的实现
     */
    private function getJulianDay(year as Number, month as Number, day as Number) as Number {
        // 标准儒略日计算公式，与6tail/lunar保持一致
        if (month <= 2) {
            month += 12;
            year -= 1;
        }
        
        var a = year / 100;
        var b = 2 - a + a / 4;
        
        // 使用标准的儒略日公式
        var jd = (365.25 * (year + 4716)).toNumber() + (30.6001 * (month + 1)).toNumber() + day + b - 1524;
        
        return jd;
    }
    
    /**
     * 计算农历年的总天数（包含闰月处理）
     * 基于6tail/lunar标准算法的位操作逻辑
     */
    private function getLunarYearDays(year as Number, lunarYearData as Array) as Number {
        if (year < 1900 || year > 2100) {
            return 354; // 默认农历年天数
        }
        
        var yearIndex = year - 1900;
        if (yearIndex >= lunarYearData.size()) {
            return 354;
        }
        
        var yearData = lunarYearData[yearIndex];
        var totalDays = 348; // 12个月，每月29天的基础天数
        
        // 计算12个普通月的额外天数（大月比小月多1天）
        // 根据6tail/lunar算法：bit4-bit15对应1-12月
        for (var month = 1; month <= 12; month++) {
            if (((yearData >> (month + 3)) & 0x1) != 0) {
                totalDays += 1;
            }
        }
        
        // 处理闰月：如果有闰月，增加闰月天数
        var leapMonth = getLeapMonth(year, lunarYearData);
        if (leapMonth > 0) {
            // 闰月天数由bit16决定：1为大月(30天)，0为小月(29天)
            var leapDays = ((yearData & 0x10000) != 0) ? 30 : 29;
            totalDays += leapDays;
        }
        
        return totalDays;
    }
    
    /**
     * 计算农历日期的核心算法 - 基于6tail/lunar标准算法重构
     * 参考：6tail/lunar-javascript项目的权威实现
     * @param year 公历年份
     * @param month 公历月份
     * @param day 公历日期
     * @return 包含农历月份和日期的字典
     */
    private function calculateLunarDate(year as Number, month as Number, day as Number) as Dictionary {
        // 如果年份超出范围，使用简化算法
        if (year < 1900 || year > 2100) {
            return getSimpleLunarResult(year, month, day);
        }
        
        // 标准农历年份数据（1900-2100年）- 来自6tail/lunar项目的权威数据
        // 数据格式：低4位表示闰月月份(0=无闰月)，bit16表示闰月大小，bit4-15表示12个月大小
        var lunarInfo = [
            0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,//1900-1909
            0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,//1910-1919
            0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,//1920-1929
            0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,//1930-1939
            0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,//1940-1949
            0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,//1950-1959
            0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,//1960-1969
            0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6,//1970-1979
            0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,//1980-1989
            0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,//1990-1999
            0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,//2000-2009
            0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,//2010-2019
            0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea66,0x0d530,//2020-2029
            0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,//2030-2039
            0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,//2040-2049
            0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,//2050-2059
            0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,//2060-2069
            0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,//2070-2079
            0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,//2080-2089
            0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,//2090-2099
            0x0d520//2100
        ];
        
        // 基准日期：1900年1月30日 = 农历1900年正月初一
        // 根据6tail/lunar标准算法的基准日期设定
        var baseYear = 1900;
        var baseMonth = 1;
        var baseDay = 30;
        var baseJulianDay = getJulianDay(baseYear, baseMonth, baseDay);
        var targetJulianDay = getJulianDay(year, month, day);
        var offset = targetJulianDay - baseJulianDay;
        
        if (offset < 0) {
            return getSimpleLunarResult(year, month, day);
        }
        
        // 从农历1900年开始逐年计算
        var lunarYear = 1900;
        
        // 逐年减去农历年天数，找到目标农历年
        while (lunarYear < 2100) {
            var yearDays = getLunarYearDays(lunarYear, lunarInfo);
            if (offset < yearDays) {
                break;
            }
            offset -= yearDays;
            lunarYear++;
        }
        
        // 在目标农历年内逐月计算
        var lunarMonth = 1;
        var isLeapMonth = false;
        var leapMonth = getLeapMonth(lunarYear, lunarInfo);
        
        // 逐月减去天数，找到目标月份
        while (lunarMonth <= 12) {
            // 计算当前月份的天数
            var monthDays = getLunarMonthDays(lunarYear, lunarMonth, lunarInfo);
            
            if (offset < monthDays) {
                break; // 找到目标月份
            }
            
            offset -= monthDays;
            
            // 检查是否有闰月（闰月在正常月份之后）
            if (leapMonth > 0 && lunarMonth == leapMonth) {
                // 计算闰月天数
                var leapMonthDays = getLeapMonthDays(lunarYear, lunarInfo);
                if (offset < leapMonthDays) {
                    isLeapMonth = true;
                    break; // 在闰月中找到目标日期
                }
                offset -= leapMonthDays;
            }
            
            lunarMonth++;
        }
        
        // 计算农历日期（从1开始）
        var lunarDay = offset + 1;
        
        // 边界检查并强制转换为Number类型
        var finalMonth = lunarMonth.toNumber();
        var finalDay = lunarDay.toNumber();
        var finalIsLeap = isLeapMonth;
        
        if (finalMonth > 12) { finalMonth = 12; }
        if (finalMonth < 1) { finalMonth = 1; }
        if (finalDay > 30) { finalDay = 30; }
        if (finalDay < 1) { finalDay = 1; }
        
        return {
            "month" => finalMonth,
            "day" => finalDay,
            "isLeapMonth" => finalIsLeap
        };
    }
    
    /**
     * 简化农历计算结果（备用方案）
     */
    private function getSimpleLunarResult(year as Number, month as Number, day as Number) as Dictionary {
        // 基于平均月相周期的简化计算
        var dayOfYear = getDayOfYear(month, day, year);
        var lunarDayOfYear = ((dayOfYear - 15) * 12.368).toNumber() % 354; // 农历年约354天
        
        var lunarMonth = (lunarDayOfYear / 29).toNumber() + 1;
        var lunarDay = (lunarDayOfYear % 29).toNumber() + 1;
        
        if (lunarMonth > 12) { lunarMonth = 12; }
        if (lunarMonth < 1) { lunarMonth = 1; }
        if (lunarDay > 30) { lunarDay = 30; }
        if (lunarDay < 1) { lunarDay = 1; }
        
        return {
            "month" => lunarMonth,
            "day" => lunarDay,
            "isLeapMonth" => false
        };
    }
     
     /**
      * 获取公历年份的天数
      */
     private function getDaysInYear(year as Number) as Number {
         if (isLeapYear(year)) {
             return 366;
         } else {
             return 365;
         }
     }
     
     /**
      * 获取农历某月的天数
      */
     private function getLunarMonthDays(lunarYear as Number, lunarMonth as Number, lunarInfo as Array) as Number {
         var yearIndex = lunarYear - 1900;
         if (yearIndex < 0 || yearIndex >= lunarInfo.size()) {
             return 29; // 默认小月
         }
         
         var info = lunarInfo[yearIndex];
         // 标准位操作：bit4-bit15对应1-12月（参考6tail/lunar算法）
         // 1月对应bit4，2月对应bit5，...，12月对应bit15
         return ((info >> (lunarMonth + 3)) & 0x1) ? 30 : 29;
     }
     
     /**
      * 获取农历年的闰月月份（0表示无闰月）
      */
     private function getLeapMonth(lunarYear as Number, lunarInfo as Array) as Number {
         var yearIndex = lunarYear - 1900;
         if (yearIndex < 0 || yearIndex >= lunarInfo.size()) {
             return 0;
         }
         
         return lunarInfo[yearIndex] & 0xf;
     }
     
     /**
      * 获取农历闰月的天数
      */
     private function getLeapMonthDays(lunarYear as Number, lunarInfo as Array) as Number {
         var yearIndex = lunarYear - 1900;
         if (yearIndex < 0 || yearIndex >= lunarInfo.size()) {
             return 0;
         }
         
         var info = lunarInfo[yearIndex];
         if ((info & 0xf) == 0) {
             return 0; // 无闰月
         }
         
         if ((info & 0x10000) != 0) {
             return 30; // 闰大月
         } else {
             return 29; // 闰小月
         }
     }
    

    

    
    /**
     * 简化农历计算（备用方案）
     */
    private function getSimpleLunar(year as Number, month as Number, day as Number) as String {
        var lunarMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"];
        var lunarDays = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ];
        
        // 基于平均月相周期的简化计算
        var dayOfYear = getDayOfYear(month, day, year);
        var lunarDayOfYear = ((dayOfYear - 15) * 12.368).toNumber() % 354; // 农历年约354天
        
        var lunarMonth = (lunarDayOfYear / 29).toNumber() + 1;
        var lunarDay = (lunarDayOfYear % 29).toNumber() + 1;
        
        if (lunarMonth > 12) { lunarMonth = 12; }
        if (lunarMonth < 1) { lunarMonth = 1; }
        if (lunarDay > 30) { lunarDay = 30; }
        if (lunarDay < 1) { lunarDay = 1; }
        
        return lunarMonths[lunarMonth - 1] + "月" + lunarDays[lunarDay - 1];
    }
    
    /**
     * 绘制表盘指针 - 基于日期的五行配色，参考SVG图标设计
     */
    private function drawWatchHands(dc as Graphics.Dc) as Void {
        try {
            var clockTime = System.getClockTime();
            
            // 安全获取时间值并进行null检查
            var hour = 0;
            var min = 0;
            var sec = 0;
            
            if (clockTime.hour != null) {
                hour = clockTime.hour.toNumber();
            }
            if (clockTime.min != null) {
                min = clockTime.min.toNumber();
            }
            if (clockTime.sec != null) {
                sec = clockTime.sec.toNumber();
            }
            
            
            // 计算指针角度
            var hourAngle = ((hour % 12) * 30 + min * 0.5) * Math.PI / 180;
            var minuteAngle = min * 6 * Math.PI / 180;
            var secondAngle = sec * 6 * Math.PI / 180;
            
            
            // 获取当日五行配色（最吉、次吉、平吉）
            var dailyColors = calculateDailyFiveElementColors(null);
            // 获取明日五行配色
            var tomorrowColors = getTomorrowFiveElementColors();
            
            // 确保颜色值是数字类型
            var hourColor = (dailyColors[0] instanceof Number) ? dailyColors[0] : 0x00FF00;
            var minuteColor = (dailyColors[1] instanceof Number) ? dailyColors[1] : 0xFF0000;
            var secondColor = (dailyColors[2] instanceof Number) ? dailyColors[2] : 0xFFFFFF;
            
            // 确保明日配色值是数字类型
            var tomorrowHourColor = (tomorrowColors[0] instanceof Number) ? tomorrowColors[0] : 0x00FF00;
            var tomorrowMinuteColor = (tomorrowColors[1] instanceof Number) ? tomorrowColors[1] : 0xFF0000;
            var tomorrowSecondColor = (tomorrowColors[2] instanceof Number) ? tomorrowColors[2] : 0xFFFFFF;
            
            // 确保_radius不为null并进行安全计算
            var safeRadius = (_radius != null) ? _radius : 100;
            
            // 计算指针长度，根据用户要求调整
            var originalHourLength = (safeRadius - 25).toNumber();
            var originalMinuteLength = (safeRadius - 10).toNumber();
            var originalSecondLength = (safeRadius - 5).toNumber();
            
            // 时针长度缩短1/3再缩短8像素后再缩短六分之一，分针长度调整到时针和秒针之间，秒针缩短24像素
            var hourLength = ((originalHourLength * 2 / 3 - 8) * 5 / 6 + 10).toNumber(); // 时针缩短1/3再缩短8像素后再缩短六分之一，然后增加10像素
            var secondLength = (originalSecondLength - 24).toNumber(); // 秒针缩短24像素
            var minuteLength = ((hourLength + secondLength) / 2 + 5).toNumber(); // 分针长度设为时针和秒针的中间值再增加5像素
            
            // 指针宽度按比例增加三分之一，确保主体颜色清晰可见
            var hourWidth = 24;   // 时针宽度从18增加到24（增加1/3）
            var minuteWidth = 19; // 分针宽度从14增加到19（增加1/3）  
            var secondWidth = 11; // 秒针宽度从8增加到11（增加1/3）
            
            // 绘制时针
            drawArrowHandWithTomorrowColor(dc, hourAngle, hourLength, hourWidth, 12, hourColor, tomorrowHourColor, "hour");
            
            // 绘制分针
            drawArrowHandWithTomorrowColor(dc, minuteAngle, minuteLength, minuteWidth, 8, minuteColor, tomorrowMinuteColor, "minute");
            
            // 绘制秒针
            drawArrowHandWithTomorrowColor(dc, secondAngle, secondLength, secondWidth, 4, secondColor, tomorrowSecondColor, "second");
            
            // 绘制三层空心中心圆点
            drawCenterCircles(dc, hourColor, minuteColor, secondColor);
            
        } catch (ex) {
        }
    }
    
    /**
     * 绘制带明日配色的指针
     * @param dc 绘图上下文
     * @param angle 指针角度
     * @param length 指针长度
     * @param width 指针宽度
     * @param arrowSize 箭头尖端大小
     * @param color 指针颜色
     * @param tomorrowColor 明日配色
     * @param type 指针类型
     */
    private function drawArrowHandWithTomorrowColor(dc as Graphics.Dc, angle as Float, length as Number, width as Number, arrowSize as Number, color as Number, tomorrowColor as Number, type as String) as Void {
        drawNewStylePointer(dc, angle, length, width, color, tomorrowColor, type);
    }
    
    /**
     * 绘制三层空心中心圆点
     * @param dc 绘图上下文
     * @param hourColor 时针颜色
     * @param minuteColor 分针颜色
     * @param secondColor 秒针颜色
     */
    private function drawCenterCircles(dc as Graphics.Dc, hourColor as Number, minuteColor as Number, secondColor as Number) as Void {
        // 外层圆（时针）
        dc.setColor(hourColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(_centerX, _centerY, 8);
        
        // 中层圆（分针）
        dc.setColor(minuteColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(_centerX, _centerY, 5);
        
        // 内层圆（秒针）
        dc.setColor(secondColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(_centerX, _centerY, 2);
    }
    
    /**
     * 绘制新样式指针：按设计图重新设计
     * @param dc 绘图上下文
     * @param angle 角度（弧度）
     * @param length 指针长度
     * @param width 指针宽度
     * @param bodyColor 主体颜色（今日配色）
     * @param tipColor 尖端小图标颜色（明日配色）
     * @param type 指针类型
     */
    private function drawNewStylePointer(dc as Graphics.Dc, angle as Float, length as Number, width as Number, bodyColor as Number, tipColor as Number, type as String) as Void {
        var sin = Math.sin(angle);
        var cos = Math.cos(angle);
        if (sin == null) { sin = 0.0; }
        if (cos == null) { cos = 1.0; }
        
        // 计算垂直方向
        var perpAngle = angle + Math.PI / 2;
        var perpSin = Math.sin(perpAngle);
        var perpCos = Math.cos(perpAngle);
        if (perpSin == null) { perpSin = 0.0; }
        if (perpCos == null) { perpCos = 1.0; }
        
        // 按照设计图重新定义指针形状 - 从尾部逐渐变宽到连接处，然后形成三角形尖端
        var baseLength = length * 0.75;  // 主体长度
        var tipLength = length * 0.25;   // 尖端长度，形成三角形
        var tailWidth = width * 0.3;     // 尾部宽度（最窄）
        var maxWidth = width * 1.1;      // 主体与尖端连接处的最大宽度（调宽以容纳空心三角形）
        
        // 计算关键点坐标
        var centerX = _centerX;
        var centerY = _centerY;
        
        // 主体结束点（尖端开始点，也是最宽处）
        var baseEndX = _centerX + (baseLength * sin).toNumber();
        var baseEndY = _centerY - (baseLength * cos).toNumber();
        
        // 指针尖端
        var tipX = _centerX + (length * sin).toNumber();
        var tipY = _centerY - (length * cos).toNumber();
        
        // 计算尾部的四个顶点（最窄处）
        var tailHalfWidth = tailWidth / 2;
        var leftTailX = centerX + (tailHalfWidth * perpSin).toNumber();
        var leftTailY = centerY - (tailHalfWidth * perpCos).toNumber();
        var rightTailX = centerX - (tailHalfWidth * perpSin).toNumber();
        var rightTailY = centerY + (tailHalfWidth * perpCos).toNumber();
        
        // 计算主体结束处的四个顶点（最宽处）
        var maxHalfWidth = maxWidth / 2;
        var leftMaxX = baseEndX + (maxHalfWidth * perpSin).toNumber();
        var leftMaxY = baseEndY - (maxHalfWidth * perpCos).toNumber();
        var rightMaxX = baseEndX - (maxHalfWidth * perpSin).toNumber();
        var rightMaxY = baseEndY + (maxHalfWidth * perpCos).toNumber();
        
        // 检查是否需要白色描边
        var needStroke = (bodyColor == 0x000000) || (bodyColor == tipColor) || 
                        (bodyColor == 0x0000FF && type.equals("minute")) ||
                        (bodyColor == 0x00FF00 && type.equals("hour"));
        
        // 先绘制白色描边（如果需要）- 梯形+三角形一体化描边
        if (needStroke) {
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            var strokeOffset = 1; // 减少描边偏移，使线条更精细
            
            // 计算描边的各个关键点
            var strokeTailHalfWidth = tailHalfWidth + strokeOffset;
            var strokeLeftTailX = centerX + (strokeTailHalfWidth * perpSin).toNumber();
            var strokeLeftTailY = centerY - (strokeTailHalfWidth * perpCos).toNumber();
            var strokeRightTailX = centerX - (strokeTailHalfWidth * perpSin).toNumber();
            var strokeRightTailY = centerY + (strokeTailHalfWidth * perpCos).toNumber();
            
            var strokeMaxHalfWidth = maxHalfWidth + strokeOffset;
            var strokeLeftMaxX = baseEndX + (strokeMaxHalfWidth * perpSin).toNumber();
            var strokeLeftMaxY = baseEndY - (strokeMaxHalfWidth * perpCos).toNumber();
            var strokeRightMaxX = baseEndX - (strokeMaxHalfWidth * perpSin).toNumber();
            var strokeRightMaxY = baseEndY + (strokeMaxHalfWidth * perpCos).toNumber();
            
            var strokeTipEndX = _centerX + ((length + strokeOffset) * sin).toNumber();
            var strokeTipEndY = _centerY - ((length + strokeOffset) * cos).toNumber();
            
            // 绘制完整的描边形状：梯形主体+三角形尖端
            var strokePointerPoints = [
                [strokeLeftTailX, strokeLeftTailY],    // 尾部左侧
                [strokeRightTailX, strokeRightTailY],  // 尾部右侧
                [strokeRightMaxX, strokeRightMaxY],    // 最宽处右侧
                [strokeTipEndX, strokeTipEndY],        // 三角形尖端
                [strokeLeftMaxX, strokeLeftMaxY]       // 最宽处左侧
            ];
            dc.fillPolygon(strokePointerPoints);
        }
        
        // 绘制完整的指针形状（今日配色）- 梯形主体+三角形尖端一体化
        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        var pointerPoints = [
            [leftTailX, leftTailY],    // 尾部左侧（最窄）
            [rightTailX, rightTailY],  // 尾部右侧（最窄）
            [rightMaxX, rightMaxY],    // 最宽处右侧
            [tipX, tipY],              // 三角形尖端
            [leftMaxX, leftMaxY]       // 最宽处左侧
        ];
        dc.fillPolygon(pointerPoints);
        
        // 绘制明日配色小指针 - 与主指针形状相同但尺寸更小，位于指针内部
        drawTomorrowMiniPointer(dc, angle, length, width, bodyColor, tipColor, sin, cos, perpSin, perpCos);
        
        // 去掉指针尾部配重，保持简洁的指针设计
    }
    
    /**
     * 绘制明日配色小指针 - 菱形形状，从指针尖端向内5像素开始
     * @param dc 绘图上下文
     * @param angle 指针角度
     * @param length 主指针长度
     * @param width 主指针宽度
     * @param bodyColor 主指针颜色（今日配色）
     * @param tipColor 小指针颜色（明日配色）
     * @param sin 角度正弦值
     * @param cos 角度余弦值
     * @param perpSin 垂直角度正弦值
     * @param perpCos 垂直角度余弦值
     */
    private function drawTomorrowMiniPointer(dc as Graphics.Dc, angle as Float, length as Number, width as Number, bodyColor as Number, tipColor as Number, sin as Float, cos as Float, perpSin as Float, perpCos as Float) as Void {
        // 始终绘制明日配色小指针，无论今日配色与明日配色是否相同
        
        // 小指针的尺寸参数（按主指针比例缩小六分之一）
        var miniScale = 5.0 / 6.0; // 缩小六分之一
        var miniLength = (length * miniScale).toNumber();
        var miniWidth = (width * 0.4).toNumber(); // 宽度设为主指针的40%
        
        // 菱形小指针参数（增加50%尺寸）
        var diamondLength = 30; // 菱形长度（从20增加到30，增加50%）
        var diamondWidth = (miniWidth * 1.5).toNumber(); // 菱形最大宽度（增加50%）
        var offsetFromTip = 5; // 从指针尖端向内的偏移距离
        
        // 计算菱形的关键点坐标
        var centerX = _centerX;
        var centerY = _centerY;
        
        // 菱形起始点（从指针尖端向内5像素）
        var diamondStartX = _centerX + ((miniLength - offsetFromTip) * sin).toNumber();
        var diamondStartY = _centerY - ((miniLength - offsetFromTip) * cos).toNumber();
        
        // 菱形结束点（向内延伸diamondLength像素）
        var diamondEndX = _centerX + ((miniLength - offsetFromTip - diamondLength) * sin).toNumber();
        var diamondEndY = _centerY - ((miniLength - offsetFromTip - diamondLength) * cos).toNumber();
        
        // 菱形中点（最宽处）
        var diamondMidX = _centerX + ((miniLength - offsetFromTip - diamondLength/2) * sin).toNumber();
        var diamondMidY = _centerY - ((miniLength - offsetFromTip - diamondLength/2) * cos).toNumber();
        
        // 计算菱形左右边界点
        var diamondHalfWidth = diamondWidth / 2;
        var diamondLeftX = diamondMidX + (diamondHalfWidth * perpSin).toNumber();
        var diamondLeftY = diamondMidY - (diamondHalfWidth * perpCos).toNumber();
        var diamondRightX = diamondMidX - (diamondHalfWidth * perpSin).toNumber();
        var diamondRightY = diamondMidY + (diamondHalfWidth * perpCos).toNumber();
        
        // 根据今日配色与明日配色的关系选择边框策略
        var borderOffset = 2;
        var borderDiamondHalfWidth = diamondHalfWidth + borderOffset;
        
        // 计算边框菱形的关键点
        var borderDiamondStartX = _centerX + ((miniLength - offsetFromTip + borderOffset) * sin).toNumber();
        var borderDiamondStartY = _centerY - ((miniLength - offsetFromTip + borderOffset) * cos).toNumber();
        
        var borderDiamondEndX = _centerX + ((miniLength - offsetFromTip - diamondLength - borderOffset) * sin).toNumber();
        var borderDiamondEndY = _centerY - ((miniLength - offsetFromTip - diamondLength - borderOffset) * cos).toNumber();
        
        var borderDiamondLeftX = diamondMidX + (borderDiamondHalfWidth * perpSin).toNumber();
        var borderDiamondLeftY = diamondMidY - (borderDiamondHalfWidth * perpCos).toNumber();
        var borderDiamondRightX = diamondMidX - (borderDiamondHalfWidth * perpSin).toNumber();
        var borderDiamondRightY = diamondMidY + (borderDiamondHalfWidth * perpCos).toNumber();
        
        // 边框颜色逻辑：如果今日配色与明日配色都是黑色，则使用白色边框；其他情况都使用透明边框（黑色）
        var borderColor = (bodyColor == 0x000000 && tipColor == 0x000000) ? 0xFFFFFF : 0x000000;
        dc.setColor(borderColor, Graphics.COLOR_TRANSPARENT);
        var borderPoints = [
            [borderDiamondStartX, borderDiamondStartY],  // 菱形头部
            [borderDiamondLeftX, borderDiamondLeftY],    // 菱形左侧
            [borderDiamondEndX, borderDiamondEndY],      // 菱形尾部
            [borderDiamondRightX, borderDiamondRightY]   // 菱形右侧
        ];
        dc.fillPolygon(borderPoints);
        
        // 只有当今日配色与明日配色都是黑色时，才绘制白色描边
        if (bodyColor == 0x000000 && tipColor == 0x000000) {
            var strokeOffset = 1;
            var strokeDiamondHalfWidth = diamondHalfWidth + strokeOffset;
            
            var strokeDiamondStartX = _centerX + ((miniLength - offsetFromTip + strokeOffset) * sin).toNumber();
            var strokeDiamondStartY = _centerY - ((miniLength - offsetFromTip + strokeOffset) * cos).toNumber();
            
            var strokeDiamondEndX = _centerX + ((miniLength - offsetFromTip - diamondLength - strokeOffset) * sin).toNumber();
            var strokeDiamondEndY = _centerY - ((miniLength - offsetFromTip - diamondLength - strokeOffset) * cos).toNumber();
            
            var strokeDiamondLeftX = diamondMidX + (strokeDiamondHalfWidth * perpSin).toNumber();
            var strokeDiamondLeftY = diamondMidY - (strokeDiamondHalfWidth * perpCos).toNumber();
            var strokeDiamondRightX = diamondMidX - (strokeDiamondHalfWidth * perpSin).toNumber();
            var strokeDiamondRightY = diamondMidY + (strokeDiamondHalfWidth * perpCos).toNumber();
            
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            var strokePoints = [
                [strokeDiamondStartX, strokeDiamondStartY],  // 菱形头部
                [strokeDiamondLeftX, strokeDiamondLeftY],    // 菱形左侧
                [strokeDiamondEndX, strokeDiamondEndY],      // 菱形尾部
                [strokeDiamondRightX, strokeDiamondRightY]   // 菱形右侧
            ];
            dc.fillPolygon(strokePoints);
        }
        
        // 绘制小指针主体（明日配色）- 菱形形状
        dc.setColor(tipColor, Graphics.COLOR_TRANSPARENT);
        var miniPointerPoints = [
            [diamondStartX, diamondStartY],  // 菱形头部
            [diamondLeftX, diamondLeftY],    // 菱形左侧
            [diamondEndX, diamondEndY],      // 菱形尾部
            [diamondRightX, diamondRightY]   // 菱形右侧
        ];
        dc.fillPolygon(miniPointerPoints);
        
        // 菱形小指针不需要配重，保持简洁的菱形设计
    }
    
    /**
     * 绘制箭头形状的辅助方法
     */
    private function drawArrowShape(dc as Graphics.Dc, centerX as Number, centerY as Number,
                                   expandX as Number, expandY as Number,
                                   maxWidthX as Number, maxWidthY as Number,
                                   arrowBaseX as Number, arrowBaseY as Number,
                                   tipX as Number, tipY as Number,
                                   centerWidth as Number, expandWidth as Number, 
                                   maxWidth as Number, arrowWidth as Number,
                                   perpSin as Number, perpCos as Number) as Void {
        
        // 计算各段的左右边界点
        var centerHalf = centerWidth / 2;
        var expandHalf = expandWidth / 2;
        var maxHalf = maxWidth / 2;
        var arrowHalf = arrowWidth / 2;
        
        // 构建完整的箭头多边形点集
        var points = [
            // 左侧轮廓（从中心到箭头尖端）
            [(centerX + (centerHalf * perpSin)).toNumber(), (centerY - (centerHalf * perpCos)).toNumber()],
            [(expandX + (expandHalf * perpSin)).toNumber(), (expandY - (expandHalf * perpCos)).toNumber()],
            [(maxWidthX + (maxHalf * perpSin)).toNumber(), (maxWidthY - (maxHalf * perpCos)).toNumber()],
            [(arrowBaseX + (arrowHalf * perpSin)).toNumber(), (arrowBaseY - (arrowHalf * perpCos)).toNumber()],
            [tipX, tipY], // 箭头尖端
            // 右侧轮廓（从箭头尖端回到中心）
            [(arrowBaseX - (arrowHalf * perpSin)).toNumber(), (arrowBaseY + (arrowHalf * perpCos)).toNumber()],
            [(maxWidthX - (maxHalf * perpSin)).toNumber(), (maxWidthY + (maxHalf * perpCos)).toNumber()],
            [(expandX - (expandHalf * perpSin)).toNumber(), (expandY + (expandHalf * perpCos)).toNumber()],
            [(centerX - (centerHalf * perpSin)).toNumber(), (centerY + (centerHalf * perpCos)).toNumber()]
        ];
        
        dc.fillPolygon(points);
    }
    
    /**
     * 绘制箭头形状的指针 - 参考SVG图标设计，增强对比度
     * @param dc 绘图上下文
     * @param angle 指针角度
     * @param length 指针长度
     * @param width 指针宽度
     * @param arrowSize 箭头尖端大小
     * @param color 指针颜色
     * @param type 指针类型
     */
    private function drawArrowHand(dc as Graphics.Dc, angle as Float, length as Number, width as Number, arrowSize as Number, color as Number, type as String) as Void {
        var sin = Math.sin(angle);
        var cos = Math.cos(angle);
        if (sin == null) { sin = 0.0; }
        if (cos == null) { cos = 1.0; }
        
        // 计算指针端点
        var endX = _centerX + (length * sin).toNumber();
        var endY = _centerY - (length * cos).toNumber();
        
        // 计算指针主体的宽度点
        var perpAngle = angle + Math.PI / 2;
        var perpSin = Math.sin(perpAngle);
        var perpCos = Math.cos(perpAngle);
        if (perpSin == null) { perpSin = 0.0; }
        if (perpCos == null) { perpCos = 1.0; }
        
        var halfWidth = width / 2;
        
        // 计算指针主体的四个顶点
        var baseLength = length * 0.7; // 主体长度为总长度的70%
        var baseEndX = _centerX + (baseLength * sin).toNumber();
        var baseEndY = _centerY - (baseLength * cos).toNumber();
        
        // 主体左右边缘点
        var leftBaseX = _centerX + (halfWidth * perpSin).toNumber();
        var leftBaseY = _centerY - (halfWidth * perpCos).toNumber();
        var rightBaseX = _centerX - (halfWidth * perpSin).toNumber();
        var rightBaseY = _centerY + (halfWidth * perpCos).toNumber();
        
        var leftEndX = baseEndX + (halfWidth * perpSin).toNumber();
        var leftEndY = baseEndY - (halfWidth * perpCos).toNumber();
        var rightEndX = baseEndX - (halfWidth * perpSin).toNumber();
        var rightEndY = baseEndY + (halfWidth * perpCos).toNumber();
        
        // 获取描边颜色（用于增强对比度）
        var strokeColor = getStrokeColorForPointer(color);
        
        // 先绘制白色描边（使用更精确的描边算法，确保所有角度都可见）
        if (strokeColor != color) {
            dc.setColor(strokeColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            
            // 计算精确的描边偏移向量
            var strokeWidth = 1; // 描边宽度调整为1像素，形成细线效果
            var strokeHalfWidth = (halfWidth + strokeWidth);
            
            // 重新计算描边的边缘点
            var strokeLeftBaseX = _centerX + (strokeHalfWidth * perpSin).toNumber();
            var strokeLeftBaseY = _centerY - (strokeHalfWidth * perpCos).toNumber();
            var strokeRightBaseX = _centerX - (strokeHalfWidth * perpSin).toNumber();
            var strokeRightBaseY = _centerY + (strokeHalfWidth * perpCos).toNumber();
            
            var strokeLeftEndX = baseEndX + (strokeHalfWidth * perpSin).toNumber();
            var strokeLeftEndY = baseEndY - (strokeHalfWidth * perpCos).toNumber();
            var strokeRightEndX = baseEndX - (strokeHalfWidth * perpSin).toNumber();
            var strokeRightEndY = baseEndY + (strokeHalfWidth * perpCos).toNumber();
            
            // 计算延长的箭头尖端
            var extendedLength = length + 2;
            var strokeEndX = _centerX + (extendedLength * sin).toNumber();
            var strokeEndY = _centerY - (extendedLength * cos).toNumber();
            
            // 绘制描边主体矩形
            var strokeBodyPoints = [
                [strokeLeftBaseX, strokeLeftBaseY],
                [strokeRightBaseX, strokeRightBaseY],
                [strokeRightEndX, strokeRightEndY],
                [strokeLeftEndX, strokeLeftEndY]
            ];
            dc.fillPolygon(strokeBodyPoints);
            
            // 绘制描边箭头尖端三角形
            var strokeArrowPoints = [
                [strokeLeftEndX, strokeLeftEndY],
                [strokeRightEndX, strokeRightEndY],
                [strokeEndX, strokeEndY]
            ];
            dc.fillPolygon(strokeArrowPoints);
        }
        
        // 再绘制主体颜色
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        
        // 绘制指针主体矩形
        var bodyPoints = [
            [leftBaseX, leftBaseY],
            [rightBaseX, rightBaseY],
            [rightEndX, rightEndY],
            [leftEndX, leftEndY]
        ];
        dc.fillPolygon(bodyPoints);
        
        // 绘制箭头尖端三角形
        var arrowPoints = [
            [leftEndX, leftEndY],
            [rightEndX, rightEndY],
            [endX, endY]
        ];
        dc.fillPolygon(arrowPoints);
        
        // 为所有指针添加平衡配重（尾巴）
        if (type.equals("second") || type.equals("hour") || type.equals("minute")) {
            var balanceLength = (length * 0.2).toNumber();
            var balanceX = _centerX - (balanceLength * sin).toNumber();
            var balanceY = _centerY + (balanceLength * cos).toNumber();
            
            var balanceWidth = width / 2;
            var balanceHalfWidth = balanceWidth / 2;
            
            var leftBalanceX = _centerX + (balanceHalfWidth * perpSin).toNumber();
            var leftBalanceY = _centerY - (balanceHalfWidth * perpCos).toNumber();
            var rightBalanceX = _centerX - (balanceHalfWidth * perpSin).toNumber();
            var rightBalanceY = _centerY + (balanceHalfWidth * perpCos).toNumber();
            
            var leftBalanceEndX = balanceX + (balanceHalfWidth * perpSin).toNumber();
            var leftBalanceEndY = balanceY - (balanceHalfWidth * perpCos).toNumber();
            var rightBalanceEndX = balanceX - (balanceHalfWidth * perpSin).toNumber();
            var rightBalanceEndY = balanceY + (balanceHalfWidth * perpCos).toNumber();
            
            // 为平衡配重也添加白色描边（使用精确算法）
            if (strokeColor != color) {
                dc.setColor(strokeColor, Graphics.COLOR_TRANSPARENT);
                var balanceStrokeWidth = 1; // 平衡配重描边也调整为1像素
                var balanceStrokeHalfWidth = (balanceHalfWidth + balanceStrokeWidth);
                
                var strokeLeftBalanceX = _centerX + (balanceStrokeHalfWidth * perpSin).toNumber();
                var strokeLeftBalanceY = _centerY - (balanceStrokeHalfWidth * perpCos).toNumber();
                var strokeRightBalanceX = _centerX - (balanceStrokeHalfWidth * perpSin).toNumber();
                var strokeRightBalanceY = _centerY + (balanceStrokeHalfWidth * perpCos).toNumber();
                
                var extendedBalanceLength = balanceLength + 1;
                var strokeBalanceEndX = _centerX - (extendedBalanceLength * sin).toNumber();
                var strokeBalanceEndY = _centerY + (extendedBalanceLength * cos).toNumber();
                
                var strokeLeftBalanceEndX = strokeBalanceEndX + (balanceStrokeHalfWidth * perpSin).toNumber();
                var strokeLeftBalanceEndY = strokeBalanceEndY - (balanceStrokeHalfWidth * perpCos).toNumber();
                var strokeRightBalanceEndX = strokeBalanceEndX - (balanceStrokeHalfWidth * perpSin).toNumber();
                var strokeRightBalanceEndY = strokeBalanceEndY + (balanceStrokeHalfWidth * perpCos).toNumber();
                
                var strokeBalancePoints = [
                    [strokeLeftBalanceX, strokeLeftBalanceY],
                    [strokeRightBalanceX, strokeRightBalanceY],
                    [strokeRightBalanceEndX, strokeRightBalanceEndY],
                    [strokeLeftBalanceEndX, strokeLeftBalanceEndY]
                ];
                dc.fillPolygon(strokeBalancePoints);
                
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            }
            
            var balancePoints = [
                [leftBalanceX, leftBalanceY],
                [rightBalanceX, rightBalanceY],
                [rightBalanceEndX, rightBalanceEndY],
                [leftBalanceEndX, leftBalanceEndY]
            ];
            dc.fillPolygon(balancePoints);
        }
    }
    
    /**
     * 获取指针的描边颜色，统一使用白色描边增强视觉一致性
     * @param pointerColor 指针主体颜色
     * @return 描边颜色
     */
    private function getStrokeColorForPointer(pointerColor as Number) as Number {
        // 统一使用白色描边，确保所有指针在深色背景下都清晰可见
        // 同时保持视觉一致性，避免用户混淆指针颜色
        return 0xFFFFFF;  // 统一白色描边
    }

    /**
     * 进入睡眠模式时调用
     */
    function onEnterSleep() as Void {
    }

    /**
     * 退出睡眠模式时调用
     */
    function onExitSleep() as Void {
    }

    /**
     * 部分更新时调用
     * @param dc 绘图上下文
     */
    function onPartialUpdate(dc as Graphics.Dc) as Void {
    }

    /**
     * 显示模式改变时调用
     * @param mode 显示模式
     */
    function onShow() as Void {
    }

    /**
     * 隐藏时调用
     */
    function onHide() as Void {
    }
}