import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.WatchUi;

/**
 * FR255专用渲染器 - 完全独立的渲染架构
 * 与FR965设备完全隔离，确保互不影响
 */
class FR255Renderer {
    
    private var deviceAdapter as DeviceAdapter or Null = null;
    private var centerX as Number = 130;
    private var centerY as Number = 130;
    private var radius as Number = 120;
    private var screenWidth as Number = 260;
    private var screenHeight as Number = 260;
    
    // 中文字体资源
    private var chineseFont as WatchUi.FontResource or Null = null;
    private var chineseFontSmall as WatchUi.FontResource or Null = null;
    
    /**
     * 构造函数
     */
    function initialize() {
        // 默认构造函数
    }
    
    /**
     * 设置渲染器参数
     * @param adapter 设备适配器
     * @param cX 中心X坐标
     * @param cY 中心Y坐标
     * @param r 半径
     * @param sW 屏幕宽度
     * @param sH 屏幕高度
     */
    public function setup(adapter as DeviceAdapter, cX as Number, cY as Number, r as Number, sW as Number, sH as Number) as Void {
        deviceAdapter = adapter;
        centerX = cX;
        centerY = cY;
        radius = r;
        screenWidth = sW;
        screenHeight = sH;
        
        // 加载中文字体
        try {
            chineseFont = WatchUi.loadResource(Rez.Fonts.chinese_font);
            chineseFontSmall = WatchUi.loadResource(Rez.Fonts.chinese_font_small);
        } catch (ex) {
            chineseFont = null;
            chineseFontSmall = null;
        }
    }
    
    /**
     * FR255专用表盘渲染方法 - 完整版本
     * @param dc 绘图上下文
     * @param elementColors 五行配色方案
     * @param settings 用户设置参数
     */
    public function renderWatchFace(dc as Graphics.Dc, elementColors as Dictionary, settings as Dictionary or Null) as Void {
        if (deviceAdapter == null) {
            return;
        }
        
        // 清除背景
        dc.setColor(elementColors["backgroundColor"], elementColors["backgroundColor"]);
        dc.clear();
        
        var scale = deviceAdapter.getScaleRatio();
        
        // FR255专用渲染流程 - 按照FR965的完整布局
        drawFR255HourMarks(dc, elementColors, scale);
        drawFR255MinuteMarks(dc, elementColors, scale);
        drawFR255CenterTimeInfo(dc, elementColors, scale, settings);
        drawFR255HealthData(dc, elementColors, scale, settings);
        drawFR255WatchHands(dc, elementColors, scale);
    }
    
    /**
     * FR255专用小时刻度绘制
     */
    private function drawFR255HourMarks(dc as Graphics.Dc, elementColors as Dictionary, scale as Float) as Void {
        try {
            // FR255专用的小时刻度配色
            var hourColors = [
                elementColors["mainNumbers"],    // 12点 - 主要数字颜色
                elementColors["otherNumbers"],   // 1点
                elementColors["otherNumbers"],   // 2点
                elementColors["mainNumbers"],    // 3点 - 主要数字颜色
                elementColors["otherNumbers"],   // 4点
                elementColors["otherNumbers"],   // 5点
                elementColors["mainNumbers"],    // 6点 - 主要数字颜色
                elementColors["otherNumbers"],   // 7点
                elementColors["otherNumbers"],   // 8点
                elementColors["mainNumbers"],    // 9点 - 主要数字颜色
                elementColors["otherNumbers"],   // 10点
                elementColors["otherNumbers"]    // 11点
            ];
            
            for (var i = 0; i < 12; i++) {
                var angle = i * 30 * Math.PI / 180; // 每小时30度
                var hour = (i == 0) ? 12 : i;
                
                // FR255专用的文字位置计算 - 与刻度线相隔2像素
                var textRadius = (radius - 22) * scale; // 调整距离，与刻度线相隔2像素
                var textX = centerX + (textRadius * Math.sin(angle)).toNumber();
                var textY = centerY - (textRadius * Math.cos(angle)).toNumber();
                
                // 特殊位置调整：数字6、5、7向上移动2像素
                if (hour == 6 || hour == 5 || hour == 7) {
                    textY -= 3;
                }
                
                // FR255专用字体适配 - 增大五分之一
                dc.setColor(hourColors[i], Graphics.COLOR_TRANSPARENT);
                var fontSize = Graphics.FONT_MEDIUM; // 主要数字从SMALL改为MEDIUM，增大五分之一
                if (i != 0 && i != 3 && i != 6 && i != 9) {
                    fontSize = Graphics.FONT_SMALL; // 其他数字从XTINY改为SMALL，增大五分之一
                }
                dc.drawText(textX, textY, fontSize, hour.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                
                // FR255专用刻度线 - 贴近表盘边缘，缩短2像素
                var scaledRadius = radius * scale;
                var outerX = centerX + ((scaledRadius - 2) * Math.sin(angle)).toNumber();
                var outerY = centerY - ((scaledRadius - 2) * Math.cos(angle)).toNumber();
                var innerX = centerX + ((scaledRadius - 18) * Math.sin(angle)).toNumber(); // 从20改为18，缩短2像素
                var innerY = centerY - ((scaledRadius - 18) * Math.cos(angle)).toNumber(); // 从20改为18，缩短2像素
                
                dc.setColor(hourColors[i], Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(3);
                dc.drawLine(outerX, outerY, innerX, innerY);
            }
        } catch (ex) {
            // 静默处理错误
        }
    }
    
    /**
     * 将月份枚举转换为数字
     */
    private function convertMonthToNumber(monthEnum) as Number {
        if (monthEnum == null) { 
            return 7; // 默认7月
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
                return numValue + 1;
            } else {
                // 超出范围，使用默认值
                return 7;
            }
        }
        
        // 处理字符串类型（模拟器环境常见）
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
        
        // 处理Gregorian枚举类型
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
                    return 7; // 默认7月
            }
        } catch (ex) {
            // 枚举处理失败，返回默认值
            return 7;
        }
    }
    
    /**
     * 计算星期几 - 移植自FR965的正确算法
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
     * 转换为农历
     */
    private function convertToLunar(year as Number, month as Number, day as Number) as String {
        // 简化的农历计算
        var lunarMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"];
        var lunarDays = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ];
        
        // 基于平均月相周期的简化计算
        var dayOfYear = getDayOfYear(month, day, year);
        var lunarDayOfYear = (dayOfYear * 354 / 365).toNumber();
        
        var lunarMonth = (lunarDayOfYear / 29).toNumber() + 1;
        var lunarDay = (lunarDayOfYear % 29).toNumber() + 1;
        
        if (lunarMonth > 12) { lunarMonth = 12; }
        if (lunarMonth < 1) { lunarMonth = 1; }
        if (lunarDay > 30) { lunarDay = 30; }
        if (lunarDay < 1) { lunarDay = 1; }
        
        return lunarMonths[lunarMonth - 1] + "月" + lunarDays[lunarDay - 1];
    }
    
    /**
     * 获取一年中的第几天
     */
    private function getDayOfYear(month as Number, day as Number, year as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        
        // 闰年判断
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
     */
    private function isLeapYear(year as Number) as Boolean {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }
    
    /**
     * 获取心率数据
     */
    private function getHeartRate() as Number or Null {
        try {
            var heartRateIterator = ActivityMonitor.getHeartRateHistory(1, true);
            if (heartRateIterator != null) {
                var sample = heartRateIterator.next();
                if (sample != null && sample.heartRate != null) {
                    return sample.heartRate;
                }
            }
        } catch (ex) {
            // 忽略错误
        }
        return 119; // 模拟数据
    }
    
    /**
     * 获取天气数据 - 使用真实Weather API
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
    
    /**
     * 绘制心形图标
     */
    private function drawHeartIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        
        // 左上圆弧
        var leftCenterX = x - quarterSize;
        var leftCenterY = y - quarterSize + 2;
        dc.fillCircle(leftCenterX, leftCenterY, quarterSize + 1);
        
        // 右上圆弧
        var rightCenterX = x + quarterSize;
        var rightCenterY = y - quarterSize + 2;
        dc.fillCircle(rightCenterX, rightCenterY, quarterSize + 1);
        
        // 下方三角形
        var points = [
            [x - halfSize, y],
            [x + halfSize, y],
            [x, y + halfSize + 2]
        ];
        dc.fillPolygon(points);
    }
    
    /**
     * 绘制脚印图标
     */
    private function drawFootprintIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        
        // 脚掌主体
        dc.fillCircle(x, y + quarterSize, halfSize);
        
        // 脚趾
        for (var i = 0; i < 5; i++) {
            var toeX = x - halfSize + (i * quarterSize);
            var toeY = y - quarterSize;
            var toeSize = (i == 2) ? 3 : 2; // 中趾稍大
            dc.fillCircle(toeX, toeY, toeSize);
        }
    }
    
    /**
     * 绘制火焰图标
     */
    private function drawFireIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        
        // 火焰主体
        var points = [
            [x, y - halfSize],
            [x - quarterSize, y],
            [x - quarterSize/2, y + quarterSize],
            [x + quarterSize/2, y + quarterSize],
            [x + quarterSize, y],
            [x + quarterSize/2, y - quarterSize],
            [x, y - halfSize]
        ];
        dc.fillPolygon(points);
        
        // 内部火焰
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        var innerPoints = [
            [x, y - quarterSize],
            [x - quarterSize/2, y + quarterSize/2],
            [x + quarterSize/2, y + quarterSize/2]
        ];
        dc.fillPolygon(innerPoints);
    }
    
    /**
     * 绘制天气图标
     */
    private function drawWeatherIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number, condition as String) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        var eighthSize = size / 8;
        
        if (condition.equals("sunny")) {
            // 绘制太阳
            dc.setColor(0xFFDD00, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, halfSize);
            
            // 太阳光线
            dc.setPenWidth(2);
            var rayLength = halfSize + 4;
            for (var i = 0; i < 8; i++) {
                var angle = i * 45 * Math.PI / 180;
                var startX = x + (halfSize * Math.cos(angle)).toNumber();
                var startY = y + (halfSize * Math.sin(angle)).toNumber();
                var endX = x + (rayLength * Math.cos(angle)).toNumber();
                var endY = y + (rayLength * Math.sin(angle)).toNumber();
                dc.drawLine(startX, startY, endX, endY);
            }
        } else {
            // 默认太阳图标
            dc.setColor(0xFFDD00, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, halfSize);
        }
    }
    
    /**
     * 绘制电池图标
     */
    private function drawBatteryIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var width = size;
        var height = size / 2;
        
        // 电池外框
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(x - width/2, y - height/2, width, height);
        
        // 电池正极
        dc.fillRectangle(x + width/2, y - height/4, 2, height/2);
        
        // 电池填充 (绿色)
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var fillWidth = (width - 4) * 0.5; // 50%电量
        dc.fillRectangle(x - width/2 + 2, y - height/2 + 2, fillWidth, height - 4);
    }
    
    /**
     * FR255专用分钟刻度绘制
     */
    private function drawFR255MinuteMarks(dc as Graphics.Dc, elementColors as Dictionary, scale as Float) as Void {
        try {
            if (deviceAdapter == null) {
                return;
            }
            
            // 使用安全的颜色获取方式
            var markColor = Graphics.COLOR_LT_GRAY;
            if (elementColors.hasKey("otherNumbers")) {
                markColor = elementColors["otherNumbers"];
            }
            
            dc.setColor(markColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1); // 使用固定线宽避免适配器问题
            
            var scaledRadius = (radius * scale).toNumber();
            
            for (var j = 0; j < 60; j++) {
                if (j % 5 != 0) { // 跳过小时刻度位置
                    var minuteAngle = j * 6 * Math.PI / 180;
                    
                    // 分钟刻度线 - 贴近表盘边缘，更短的刻度线
                    var outerX = centerX + ((scaledRadius - 2) * Math.sin(minuteAngle)).toNumber();
                    var outerY = centerY - ((scaledRadius - 2) * Math.cos(minuteAngle)).toNumber();
                    var innerX = centerX + ((scaledRadius - 10) * Math.sin(minuteAngle)).toNumber();
                    var innerY = centerY - ((scaledRadius - 10) * Math.cos(minuteAngle)).toNumber();
                    
                    dc.drawLine(outerX, outerY, innerX, innerY);
                }
            }
        } catch (ex) {
            // 静默处理错误
        }
    }
    
    /**
     * FR255专用五行配色圆点绘制
     */
    private function drawFR255FiveElementDots(dc as Graphics.Dc, elementColors as Dictionary, scale as Float) as Void {
        try {
            // FR255专用的五行颜色
            var fiveElementColors = [
                0x00FF00, // 木 - 绿色
                0xFF0000, // 火 - 红色  
                0xFFFF00, // 土 - 黄色
                0xFFFFFF, // 金 - 白色
                0x0080FF  // 水 - 蓝色
            ];
            
            // FR255专用位置和大小
            var dotY = centerY - (radius * scale).toNumber() + deviceAdapter.getAdaptedOffset(30);
            var dotSpacing = deviceAdapter.getAdaptedOffset(18);
            var dotRadius = deviceAdapter.getAdaptedOffset(5);
            var startX = centerX - (4 * dotSpacing) / 2;
            
            for (var i = 0; i < 5; i++) {
                var dotX = startX + (i * dotSpacing);
                dc.setColor(fiveElementColors[i], Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, dotRadius);
            }
        } catch (ex) {
            // 静默处理错误
        }
    }
    
    /**
     * FR255专用中心时间信息绘制 - 参考FR965完整布局
     * @param dc 绘图上下文
     * @param elementColors 五行配色方案
     * @param scale 缩放比例
     * @param settings 用户设置参数
     */
    private function drawFR255CenterTimeInfo(dc as Graphics.Dc, elementColors as Dictionary, scale as Float, settings as Dictionary or Null) as Void {
        try {
            var clockTime = System.getClockTime();
            var now = Time.now();
            var today = Gregorian.info(now, Time.FORMAT_MEDIUM);
            
            // FR255适配的位置计算 (260x260分辨率) - 向上移动26像素
            var timeY = centerY - 76;  // 时间位置，向上移动26像素（原20+6）
            var dateY = centerY - 51;  // 日期位置，向上移动26像素（原20+6）
            
            // 1. 绘制时间 - 24小时格式，字体缩小一半
            var hour = clockTime.hour.toNumber();
            var min = clockTime.min.toNumber();
            var hourStr = hour < 10 ? "0" + hour.toString() : hour.toString();
            var minStr = min < 10 ? "0" + min.toString() : min.toString();
            var timeText = hourStr + ":" + minStr;
            
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, timeY, Graphics.FONT_TINY, timeText, Graphics.TEXT_JUSTIFY_CENTER); // 字体从XTINY改为TINY，放大三分之一
            
            // 2. 绘制日期、农历、星期信息 - 参考FR965的安全类型处理
            var currentYear = today.year;
            var currentMonth = today.month;
            var currentDay = today.day;
            
            // 安全的类型转换和默认值处理，参考FR965逻辑
            var monthNum = convertMonthToNumber(currentMonth);
            var dayNum = (currentDay != null && currentDay instanceof Number) ? currentDay : 29;
            var yearNum = (currentYear != null && currentYear instanceof Number) ? currentYear : 2025;
            
            // 日期转换完成，现在应该正确显示当前日期
            
            // 格式化日期
            var monthStr = monthNum < 10 ? "0" + monthNum.toString() : monthNum.toString();
            var dayStr = dayNum < 10 ? "0" + dayNum.toString() : dayNum.toString();
            var dateString = monthStr + "月" + dayStr;
            
            // 计算星期
            var dayOfWeekNum = calculateDayOfWeek(yearNum, monthNum, dayNum);
            var weekdayIndex = dayOfWeekNum - 1;
            if (weekdayIndex < 0 || weekdayIndex >= 7) {
                weekdayIndex = 0;
            }
            var weekNames = ["日", "一", "二", "三", "四", "五", "六"];
            var weekText = "星期" + weekNames[weekdayIndex];
            
            // 计算农历
            var lunarDate = convertToLunar(yearNum, monthNum, dayNum);
            if (lunarDate == null || lunarDate.equals("")) {
                lunarDate = "农历未知";
            }
            
            // FR255简化布局 - 只显示日期和星期，移除农历避免重叠
            var smallFont = Graphics.FONT_XTINY;
            var fontToUse = smallFont; // 默认使用小字体
            var useChineseFont = false;
            var scaleRatio = 1.0; // 缩放比例
            
            // 计算小字体的宽度（只计算日期和星期）
            var dateWidth = dc.getTextWidthInPixels(dateString, fontToUse);
            var weekWidth = dc.getTextWidthInPixels(weekText, fontToUse);
            var spacing = 20; // 日期和星期之间的间距，确保明显分隔空间
            var totalWidth = dateWidth + weekWidth + spacing;
            
            // 如果中文字体可用，优先使用中文字体避免乱码，但缩小三分之一
            if (chineseFont != null) {
                var chineseDateWidth = dc.getTextWidthInPixels(dateString, chineseFont);
                var chineseWeekWidth = dc.getTextWidthInPixels(weekText, chineseFont);
                
                // 缩小三分之一后的宽度
                scaleRatio = 0.67; // 缩小约三分之一
                var scaledDateWidth = chineseDateWidth * scaleRatio;
                var scaledWeekWidth = chineseWeekWidth * scaleRatio;
                var scaledTotalWidth = scaledDateWidth + scaledWeekWidth + spacing;
                
                // 如果缩放后的中文字体宽度合适，则使用中文字体
                if (scaledTotalWidth < screenWidth * 0.7) {
                    fontToUse = chineseFont;
                    useChineseFont = true;
                    dateWidth = scaledDateWidth;
                    weekWidth = scaledWeekWidth;
                    totalWidth = scaledTotalWidth;
                }
            }
            
            var startX = centerX - totalWidth / 2;
            
            // 绘制日期和星期 - 根据设置显示
            var showDateInfo = true;
            if (settings != null && settings.hasKey("showDateInfo")) {
                showDateInfo = settings["showDateInfo"];
            }
            
            if (showDateInfo) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                
                if (useChineseFont) {
                    // 使用中文字体时需要应用缩放
                    var dateX = startX + dateWidth / 2;
                    var weekX = startX + dateWidth + spacing + weekWidth / 2;
                    
                    // 通过调整字体高度模拟缩放效果
                    var adjustedDateY = dateY + 2; // 稍微向下调整位置
                    dc.drawText(dateX, adjustedDateY, fontToUse, dateString, Graphics.TEXT_JUSTIFY_CENTER);
                    dc.drawText(weekX, adjustedDateY, fontToUse, weekText, Graphics.TEXT_JUSTIFY_CENTER);
                } else {
                    // 使用小字体时正常绘制
                    var dateX = startX + dateWidth / 2;
                    var weekX = startX + dateWidth + spacing + weekWidth / 2;
                    dc.drawText(dateX, dateY, fontToUse, dateString, Graphics.TEXT_JUSTIFY_CENTER);
                    dc.drawText(weekX, dateY, fontToUse, weekText, Graphics.TEXT_JUSTIFY_CENTER);
                }
            }
            
        } catch (ex) {
            // 静默处理错误
        }
    }
    
    /**
     * FR255专用健康数据绘制 - 参考FR965布局
     * @param dc 绘图上下文
     * @param elementColors 五行配色方案
     * @param scale 缩放比例
     * @param settings 用户设置参数
     */
    private function drawFR255HealthData(dc as Graphics.Dc, elementColors as Dictionary, scale as Float, settings as Dictionary or Null) as Void {
        try {
            // 获取健康数据
            var activityInfo = ActivityMonitor.getInfo();
            var systemStats = System.getSystemStats();
            
            // 获取心率数据
            var heartRate = getHeartRate();
            
            // FR255适配的图标大小和位置 (260x260分辨率) - 参考FR965布局比例
            var iconSize = 16; // 适配图标大小
            var verticalOffset = 15; // 整体向下偏移
            
            // 位置计算 - 根据FR965布局比例调整，按用户要求微调位置，整体向上移动6像素
            var heartRateX = centerX - 70 + 10; // 心率右移10像素
            var heartRateY = centerY - 15 + verticalOffset - 5 - 6; // 心率上移5像素，再向上移动6像素
            
            var stepsX = centerX + 70 - 10; // 步数左移10像素
            var stepsY = centerY - 15 + verticalOffset - 5 - 6; // 步数上移5像素，再向上移动6像素
            
            var caloriesX = centerX - 50 + 5; // 消耗能量右移5像素
            var caloriesY = centerY + 35 + verticalOffset - 5 - 6; // 消耗能量上移5像素，再向上移动6像素
            
            var weatherX = centerX + 50 - 5; // 天气左移5像素
            var weatherY = centerY + 35 + verticalOffset - 5 - 6; // 天气上移5像素，再向上移动6像素
            
            var batteryX = centerX;
            var batteryY = centerY + 75 + verticalOffset - 15 - 6; // 电量上移15像素，再向上移动6像素
            
            // 1. 绘制心率数据 (左上方) - 根据设置显示
            var showHeartRate = true;
            if (settings != null && settings.hasKey("showHeartRate")) {
                showHeartRate = settings["showHeartRate"];
            }
            
            if (showHeartRate) {
                var heartRateValue = "--";
                if (heartRate != null) {
                    heartRateValue = heartRate.toString();
                }
                
                // 绘制心率图标
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                drawHeartIcon(dc, heartRateX, heartRateY - 6, iconSize);
                
                // 绘制心率数值
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(heartRateX, heartRateY + 5, Graphics.FONT_SYSTEM_XTINY, heartRateValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 2. 绘制步数数据 (右上方) - 根据设置显示
            var showSteps = true;
            if (settings != null && settings.hasKey("showSteps")) {
                showSteps = settings["showSteps"];
            }
            
            if (showSteps) {
                var stepsValue = "--";
                if (activityInfo != null && activityInfo.steps != null) {
                    stepsValue = activityInfo.steps.toString();
                }
                
                // 绘制步数图标
                dc.setColor(0xFF9900, Graphics.COLOR_TRANSPARENT);
                drawFootprintIcon(dc, stepsX, stepsY - 6, iconSize);
                
                // 绘制步数数值
                dc.setColor(0xFF9900, Graphics.COLOR_TRANSPARENT);
                dc.drawText(stepsX, stepsY + 5, Graphics.FONT_SYSTEM_XTINY, stepsValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 3. 绘制卡路里数据 (左下方) - 根据设置显示
            var showCalories = true;
            if (settings != null && settings.hasKey("showCalories")) {
                showCalories = settings["showCalories"];
            }
            
            if (showCalories) {
                var caloriesValue = "--";
                if (activityInfo != null && activityInfo.calories != null) {
                    caloriesValue = activityInfo.calories.toString();
                }
                
                // 绘制卡路里图标
                dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT);
                drawFireIcon(dc, caloriesX, caloriesY - 6, iconSize);
                
                // 绘制卡路里数值
                dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT);
                dc.drawText(caloriesX, caloriesY + 5, Graphics.FONT_SYSTEM_XTINY, caloriesValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 4. 绘制天气数据 (右下方) - 根据设置显示
            var showWeather = true;
            if (settings != null && settings.hasKey("showWeather")) {
                showWeather = settings["showWeather"];
            }
            
            if (showWeather) {
                var weatherData = getWeatherData();
                var temperature = weatherData[:temperature];
                var weatherValue;
                if (temperature instanceof Float || temperature instanceof Double) {
                    weatherValue = Math.round(temperature).toNumber().toString() + "°";
                } else {
                    weatherValue = temperature.toString() + "°";
                }
                var weatherCondition = weatherData[:condition];
                
                // 绘制天气图标
                drawWeatherIcon(dc, weatherX, weatherY - 6, iconSize, weatherCondition);
                
                // 绘制天气数值
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(weatherX, weatherY + 5, Graphics.FONT_SYSTEM_XTINY, weatherValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 5. 绘制电量数据 (底部中间) - 根据设置显示
            var showBattery = true;
            if (settings != null && settings.hasKey("showBattery")) {
                showBattery = settings["showBattery"];
            }
            
            if (showBattery) {
                var batteryValue = "--";
                if (systemStats != null && systemStats.battery != null) {
                    var battery = systemStats.battery.toNumber();
                    batteryValue = battery.toString() + "%";
                }
                
                // 绘制电池图标
                var batteryIconX = batteryX - iconSize;
                var batteryTextX = batteryX;
                
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                drawBatteryIcon(dc, batteryIconX, batteryY, iconSize);
                
                // 绘制电量数值
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(batteryTextX, batteryY, Graphics.FONT_SYSTEM_XTINY, batteryValue, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            
        } catch (ex) {
            // 静默处理错误
        }
    }
    
    /**
     * FR255专用指针绘制 - 采用FR965的复杂指针设计
     */
    private function drawFR255WatchHands(dc as Graphics.Dc, elementColors as Dictionary, scale as Float) as Void {
        try {
            var clockTime = System.getClockTime();
            var hour = clockTime.hour;
            var minute = clockTime.min;
            var second = clockTime.sec;
            
            // 计算指针角度（转换为标准数学角度）
            var hourAngle = ((hour % 12) * 30 + minute * 0.5) * Math.PI / 180;
            var minuteAngle = (minute * 6) * Math.PI / 180;
            var secondAngle = (second * 6) * Math.PI / 180;
            
            // 获取当日五行配色（最吉、次吉、平吉）
            var dailyColors = calculateFR255DailyFiveElementColors();
            // 获取明日五行配色
            var tomorrowColors = getFR255TomorrowFiveElementColors();
            
            // 确保颜色值是数字类型
            var hourColor = (dailyColors[0] instanceof Number) ? dailyColors[0] : 0x00FF00;
            var minuteColor = (dailyColors[1] instanceof Number) ? dailyColors[1] : 0xFF0000;
            var secondColor = (dailyColors[2] instanceof Number) ? dailyColors[2] : 0xFFFFFF;
            
            // 确保明日配色值是数字类型
            var tomorrowHourColor = (tomorrowColors[0] instanceof Number) ? tomorrowColors[0] : 0x00FF00;
            var tomorrowMinuteColor = (tomorrowColors[1] instanceof Number) ? tomorrowColors[1] : 0xFF0000;
            var tomorrowSecondColor = (tomorrowColors[2] instanceof Number) ? tomorrowColors[2] : 0xFFFFFF;
            
            // FR255适配的指针长度和宽度
            var scaledRadius = (radius * scale).toNumber();
            var originalHourLength = (scaledRadius - 25).toNumber();
            var originalMinuteLength = (scaledRadius - 10).toNumber();
            var originalSecondLength = (scaledRadius - 5).toNumber();
            
            // 按FR965的比例调整指针长度
            var hourLength = ((originalHourLength * 2 / 3 - 8) * 5 / 6 + 10).toNumber();
            var secondLength = (originalSecondLength - 24).toNumber();
            var minuteLength = ((hourLength + secondLength) / 2 + 5).toNumber();
            
            // 指针宽度按比例增加三分之一，适配FR255屏幕
            var hourWidth = 18;   // FR255适配的时针宽度
            var minuteWidth = 14; // FR255适配的分针宽度
            var secondWidth = 8;  // FR255适配的秒针宽度
            
            // 绘制时针
            drawFR255NewStylePointer(dc, hourAngle, hourLength, hourWidth, hourColor, tomorrowHourColor, "hour");
            
            // 绘制分针
            drawFR255NewStylePointer(dc, minuteAngle, minuteLength, minuteWidth, minuteColor, tomorrowMinuteColor, "minute");
            
            // 绘制秒针
            drawFR255NewStylePointer(dc, secondAngle, secondLength, secondWidth, secondColor, tomorrowSecondColor, "second");
            
            // 绘制三层空心中心圆点
            drawFR255CenterCircles(dc, hourColor, minuteColor, secondColor);
            
        } catch (ex) {
            // 静默处理错误
        }
    }
    
    /**
     * FR255专用五行配色计算 - 移植自FR965
     */
    private function calculateFR255DailyFiveElementColors() as Array {
        try {
            var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            var year = today.year;
            var month = today.month;
            var day = today.day;
            
            // 安全转换为数字类型
            var yearNum = (year != null && year instanceof Number) ? year : 2025;
            var monthNum = convertMonthToNumber(month);
            var dayNum = (day != null && day instanceof Number) ? day : 29;
            
            // 修正的传统五行纳甲算法 - 基于天干地支计算日五行
            var yearTianGan = (yearNum - 4) % 10;
            var yearDiZhi = (yearNum - 4) % 12;
            
            // 计算日天干地支（简化算法）
            var dayOfYear = getFR255DayOfYear(monthNum, dayNum, yearNum);
            var dayTianGan = (yearTianGan * 5 + monthNum * 2 + dayNum) % 10;
            var dayDiZhi = (dayOfYear + yearDiZhi) % 12;
            
            // 根据日地支确定日五行
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
            
            // 根据五行相生理论计算配色
            var mostLucky = (dayElement + 1) % 5;        // 大吉：日五行生的五行
            var secondLucky = dayElement;                // 次吉：日五行本身
            var normalLucky = (dayElement + 3) % 5;      // 平平：克日五行的五行
            
            // 定义五行颜色映射
            var elementColorMap = [
                0x00FF00,  // 木 - 绿色
                0xFF0000,  // 火 - 红色
                0xFFFF00,  // 土 - 黄色
                0xFFFFFF,  // 金 - 白色
                0x000000   // 水 - 纯黑色
            ];
            
            return [
                elementColorMap[mostLucky],    // 时针颜色（大吉）
                elementColorMap[secondLucky],  // 分针颜色（次吉）
                elementColorMap[normalLucky]   // 秒针颜色（平平）
            ];
        } catch (ex) {
            // 默认返回黄红黑配色
            return [0xFFFF00, 0xFF0000, 0x000000];
        }
    }
    
    /**
     * FR255专用明日五行配色计算
     */
    private function getFR255TomorrowFiveElementColors() as Array {
        try {
            // 获取明日的日期
            var tomorrow = new Time.Moment(Time.now().value() + 24 * 60 * 60);
            var tomorrowInfo = Gregorian.info(tomorrow, Time.FORMAT_MEDIUM);
            
            var year = tomorrowInfo.year;
            var month = tomorrowInfo.month;
            var day = tomorrowInfo.day;
            
            // 安全转换为数字类型
            var yearNum = (year != null && year instanceof Number) ? year : 2025;
            var monthNum = convertMonthToNumber(month);
            var dayNum = (day != null && day instanceof Number) ? day : 30;
            
            // 使用相同的五行计算逻辑
            var yearTianGan = (yearNum - 4) % 10;
            var yearDiZhi = (yearNum - 4) % 12;
            
            var dayOfYear = getFR255DayOfYear(monthNum, dayNum, yearNum);
            var dayTianGan = (yearTianGan * 5 + monthNum * 2 + dayNum) % 10;
            var dayDiZhi = (dayOfYear + yearDiZhi) % 12;
            
            var dayElement;
            if (dayDiZhi == 0 || dayDiZhi == 11) {
                dayElement = 4; // 水
            } else if (dayDiZhi == 2 || dayDiZhi == 3) {
                dayElement = 0; // 木
            } else if (dayDiZhi == 5 || dayDiZhi == 6) {
                dayElement = 1; // 火
            } else if (dayDiZhi == 8 || dayDiZhi == 9) {
                dayElement = 3; // 金
            } else {
                dayElement = 2; // 土
            }
            
            var mostLucky = (dayElement + 1) % 5;
            var secondLucky = dayElement;
            var normalLucky = (dayElement + 3) % 5;
            
            var elementColorMap = [
                0x00FF00,  // 木 - 绿色
                0xFF0000,  // 火 - 红色
                0xFFFF00,  // 土 - 黄色
                0xFFFFFF,  // 金 - 白色
                0x000000   // 水 - 纯黑色
            ];
            
            return [
                elementColorMap[mostLucky],
                elementColorMap[secondLucky],
                elementColorMap[normalLucky]
            ];
        } catch (ex) {
            // 如果出错，返回默认配色
            return [0xFFFF00, 0xFF0000, 0x000000];
        }
    }
    
    /**
     * FR255专用年积日计算
     */
    private function getFR255DayOfYear(month as Number, day as Number, year as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        
        // 判断闰年
        if (isFR255LeapYear(year)) {
            daysInMonth[1] = 29;
        }
        
        var dayOfYear = day;
        for (var i = 0; i < month - 1; i++) {
            dayOfYear += daysInMonth[i];
        }
        
        return dayOfYear;
    }
    
    /**
     * FR255专用闰年判断
     */
    private function isFR255LeapYear(year as Number) as Boolean {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }
    
    /**
     * FR255专用新样式指针绘制 - 移植自FR965
     */
    private function drawFR255NewStylePointer(dc as Graphics.Dc, angle as Float, length as Number, width as Number, bodyColor as Number, tipColor as Number, type as String) as Void {
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
        
        // 按照FR965设计定义指针形状 - 从尾部逐渐变宽到连接处，然后形成三角形尖端
        var baseLength = length * 0.75;  // 主体长度
        var tipLength = length * 0.25;   // 尖端长度，形成三角形
        var tailWidth = width * 0.3;     // 尾部宽度（最窄）
        var maxWidth = width * 1.1;      // 主体与尖端连接处的最大宽度
        
        // 计算关键点坐标
        var centerXLocal = centerX;
        var centerYLocal = centerY;
        
        // 主体结束点（尖端开始点，也是最宽处）
        var baseEndX = centerX + (baseLength * sin).toNumber();
        var baseEndY = centerY - (baseLength * cos).toNumber();
        
        // 指针尖端
        var tipX = centerX + (length * sin).toNumber();
        var tipY = centerY - (length * cos).toNumber();
        
        // 计算尾部的四个顶点（最窄处）
        var tailHalfWidth = tailWidth / 2;
        var leftTailX = centerXLocal + (tailHalfWidth * perpSin).toNumber();
        var leftTailY = centerYLocal - (tailHalfWidth * perpCos).toNumber();
        var rightTailX = centerXLocal - (tailHalfWidth * perpSin).toNumber();
        var rightTailY = centerYLocal + (tailHalfWidth * perpCos).toNumber();
        
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
        
        // 先绘制多层描边以改善边框效果（如果需要）
        if (needStroke) {
            // 绘制多层描边，从外到内逐渐变细，提供更好的抗锯齿效果
            for (var strokeLayer = 2; strokeLayer >= 1; strokeLayer--) {
                var strokeOffset = strokeLayer;
                var strokeAlpha = (strokeLayer == 2) ? 0x888888 : 0xFFFFFF; // 外层灰色，内层白色
                
                dc.setColor(strokeAlpha, Graphics.COLOR_TRANSPARENT);
                
                var strokeTailHalfWidth = tailHalfWidth + strokeOffset;
                var strokeLeftTailX = centerXLocal + (strokeTailHalfWidth * perpSin).toNumber();
                var strokeLeftTailY = centerYLocal - (strokeTailHalfWidth * perpCos).toNumber();
                var strokeRightTailX = centerXLocal - (strokeTailHalfWidth * perpSin).toNumber();
                var strokeRightTailY = centerYLocal + (strokeTailHalfWidth * perpCos).toNumber();
                
                var strokeMaxHalfWidth = maxHalfWidth + strokeOffset;
                var strokeLeftMaxX = baseEndX + (strokeMaxHalfWidth * perpSin).toNumber();
                var strokeLeftMaxY = baseEndY - (strokeMaxHalfWidth * perpCos).toNumber();
                var strokeRightMaxX = baseEndX - (strokeMaxHalfWidth * perpSin).toNumber();
                var strokeRightMaxY = baseEndY + (strokeMaxHalfWidth * perpCos).toNumber();
                
                var strokeTipEndX = centerX + ((length + strokeOffset) * sin).toNumber();
                var strokeTipEndY = centerY - ((length + strokeOffset) * cos).toNumber();
                
                var strokePointerPoints = [
                    [strokeLeftTailX, strokeLeftTailY],
                    [strokeRightTailX, strokeRightTailY],
                    [strokeRightMaxX, strokeRightMaxY],
                    [strokeTipEndX, strokeTipEndY],
                    [strokeLeftMaxX, strokeLeftMaxY]
                ];
                dc.fillPolygon(strokePointerPoints);
            }
        }
        
        // 绘制完整的指针形状（今日配色）
        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        var pointerPoints = [
            [leftTailX, leftTailY],    // 尾部左侧（最窄）
            [rightTailX, rightTailY],  // 尾部右侧（最窄）
            [rightMaxX, rightMaxY],    // 最宽处右侧
            [tipX, tipY],              // 三角形尖端
            [leftMaxX, leftMaxY]       // 最宽处左侧
        ];
        dc.fillPolygon(pointerPoints);
        
        // 绘制明日配色小指针
        drawFR255TomorrowMiniPointer(dc, angle, length, width, bodyColor, tipColor, sin, cos, perpSin, perpCos);
    }
    
    /**
     * FR255专用明日配色小指针绘制 - 移植自FR965
     */
    private function drawFR255TomorrowMiniPointer(dc as Graphics.Dc, angle as Float, length as Number, width as Number, bodyColor as Number, tipColor as Number, sin as Float, cos as Float, perpSin as Float, perpCos as Float) as Void {
        // 小指针的尺寸参数（按主指针比例缩小）
        var miniScale = 5.0 / 6.0;
        var miniLength = (length * miniScale).toNumber();
        var miniWidth = (width * 0.4).toNumber();
        
        // 菱形小指针参数（适配FR255屏幕）
        var diamondLength = 20; // FR255适配的菱形长度
        var diamondWidth = (miniWidth * 1.2).toNumber(); // FR255适配的菱形宽度
        var offsetFromTip = 4; // FR255适配的偏移距离
        
        // 计算菱形的关键点坐标
        var centerXLocal = centerX;
        var centerYLocal = centerY;
        
        // 菱形起始点（从指针尖端向内偏移）
        var diamondStartX = centerX + ((miniLength - offsetFromTip) * sin).toNumber();
        var diamondStartY = centerY - ((miniLength - offsetFromTip) * cos).toNumber();
        
        // 菱形结束点
        var diamondEndX = centerX + ((miniLength - offsetFromTip - diamondLength) * sin).toNumber();
        var diamondEndY = centerY - ((miniLength - offsetFromTip - diamondLength) * cos).toNumber();
        
        // 菱形中点（最宽处）
        var diamondMidX = centerX + ((miniLength - offsetFromTip - diamondLength/2) * sin).toNumber();
        var diamondMidY = centerY - ((miniLength - offsetFromTip - diamondLength/2) * cos).toNumber();
        
        // 计算菱形左右边界点
        var diamondHalfWidth = diamondWidth / 2;
        var diamondLeftX = diamondMidX + (diamondHalfWidth * perpSin).toNumber();
        var diamondLeftY = diamondMidY - (diamondHalfWidth * perpCos).toNumber();
        var diamondRightX = diamondMidX - (diamondHalfWidth * perpSin).toNumber();
        var diamondRightY = diamondMidY + (diamondHalfWidth * perpCos).toNumber();
        
        // 绘制多层边框以改善小指针的视觉效果
        var borderColor = (bodyColor == 0x000000 && tipColor == 0x000000) ? 0xFFFFFF : 0x000000;
        
        // 绘制双层边框，提供更好的对比度
        for (var borderLayer = 2; borderLayer >= 1; borderLayer--) {
            var borderOffset = borderLayer;
            var currentBorderColor = (borderLayer == 2) ? 0x666666 : borderColor; // 外层深灰，内层根据逻辑
            
            dc.setColor(currentBorderColor, Graphics.COLOR_TRANSPARENT);
            var borderDiamondHalfWidth = diamondHalfWidth + borderOffset;
            
            var borderDiamondStartX = centerX + ((miniLength - offsetFromTip + borderOffset) * sin).toNumber();
            var borderDiamondStartY = centerY - ((miniLength - offsetFromTip + borderOffset) * cos).toNumber();
            var borderDiamondEndX = centerX + ((miniLength - offsetFromTip - diamondLength - borderOffset) * sin).toNumber();
            var borderDiamondEndY = centerY - ((miniLength - offsetFromTip - diamondLength - borderOffset) * cos).toNumber();
            var borderDiamondLeftX = diamondMidX + (borderDiamondHalfWidth * perpSin).toNumber();
            var borderDiamondLeftY = diamondMidY - (borderDiamondHalfWidth * perpCos).toNumber();
            var borderDiamondRightX = diamondMidX - (borderDiamondHalfWidth * perpSin).toNumber();
            var borderDiamondRightY = diamondMidY + (borderDiamondHalfWidth * perpCos).toNumber();
            
            var borderPoints = [
                [borderDiamondStartX, borderDiamondStartY],
                [borderDiamondLeftX, borderDiamondLeftY],
                [borderDiamondEndX, borderDiamondEndY],
                [borderDiamondRightX, borderDiamondRightY]
            ];
            dc.fillPolygon(borderPoints);
        }
        
        // 绘制小指针主体（明日配色）
        dc.setColor(tipColor, Graphics.COLOR_TRANSPARENT);
        var miniPointerPoints = [
            [diamondStartX, diamondStartY],  // 菱形头部
            [diamondLeftX, diamondLeftY],    // 菱形左侧
            [diamondEndX, diamondEndY],      // 菱形尾部
            [diamondRightX, diamondRightY]   // 菱形右侧
        ];
        dc.fillPolygon(miniPointerPoints);
    }
    
    /**
     * FR255专用三层空心中心圆点绘制 - 移植自FR965，增强抗锯齿效果
     */
    private function drawFR255CenterCircles(dc as Graphics.Dc, hourColor as Number, minuteColor as Number, secondColor as Number) as Void {
        // 绘制外层圆（时针）- 多层绘制提供抗锯齿效果
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT); // 外层阴影
        dc.setPenWidth(3);
        dc.drawCircle(centerX, centerY, 7);
        
        dc.setColor(hourColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(centerX, centerY, 6);
        
        // 绘制中层圆（分针）
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT); // 中层阴影
        dc.setPenWidth(2);
        dc.drawCircle(centerX, centerY, 5);
        
        dc.setColor(minuteColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(centerX, centerY, 4);
        
        // 绘制内层圆（秒针）
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT); // 内层阴影
        dc.setPenWidth(1);
        dc.drawCircle(centerX, centerY, 3);
        
        dc.setColor(secondColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(centerX, centerY, 2);
    }
}