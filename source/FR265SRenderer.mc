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
 * FR265S专用渲染器 - 基于FR965显示代码的独立渲染架构
 * 与FR965和FR255设备完全隔离，确保互不影响
 */
class FR265SRenderer {
    
    private var deviceAdapter as DeviceAdapter or Null = null;
    private var centerX as Number = 180;
    private var centerY as Number = 180;
    private var radius as Number = 170;
    private var screenWidth as Number = 360;
    private var screenHeight as Number = 360;
    
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
        
        // 加载中文字体资源
        try {
            chineseFont = WatchUi.loadResource(Rez.Fonts.chinese_font);
            chineseFontSmall = WatchUi.loadResource(Rez.Fonts.chinese_font_small);
        } catch (ex) {
            // 字体加载失败时使用系统字体
            chineseFont = null;
            chineseFontSmall = null;
        }
    }
    
    /**
     * 渲染FR265S表盘 - 使用FR965的显示逻辑
     * @param dc 绘图上下文
     * @param elementColors 五行配色方案
     * @param settings 用户设置参数
     */
    public function renderWatchFace(dc as Graphics.Dc, elementColors as Dictionary, settings as Dictionary or Null) as Void {
        // 清空屏幕
        dc.setColor(elementColors["backgroundColor"], Graphics.COLOR_TRANSPARENT);
        dc.clear();
        
        // 获取当前时间
        var clockTime = Time.now();
        
        // 绘制表盘背景
        drawFR265SBackground(dc, elementColors);
        
        // 绘制时间刻度
        drawFR265STimeMarks(dc, elementColors);
        
        // 绘制数字
        drawFR265SNumbers(dc, elementColors);
        
        // 绘制健康数据
        drawFR265SHealthData(dc, elementColors, settings);
        
        // 绘制日期信息
        drawFR265SDateInfo(dc, clockTime, elementColors, settings);
        
        // 绘制指针
        drawFR265SPointers(dc, clockTime, elementColors);
        
        // 绘制中心圆点 - 使用默认配色
        var defaultHourColor = 0x00FF00;   // 绿色
        var defaultMinuteColor = 0xFF0000; // 红色
        var defaultSecondColor = 0xFFFFFF; // 白色
        drawFR265SCenterCircles(dc, defaultHourColor, defaultMinuteColor, defaultSecondColor);
    }
    
    /**
     * 绘制FR265S背景
     * @param dc 绘图上下文
     * @param elementColors 配色方案
     */
    private function drawFR265SBackground(dc as Graphics.Dc, elementColors as Dictionary) as Void {
        // System.println("[FR265S] 开始绘制背景");
        // System.println("[FR265S] 背景颜色: " + elementColors["backgroundColor"]);
        // System.println("[FR265S] 中心坐标: (" + centerX + ", " + centerY + "), 半径: " + radius);
        
        // 使用FR965的背景绘制逻辑 - 不绘制白色圆圈边框（与FR965保持一致）
        dc.setColor(elementColors["backgroundColor"], elementColors["backgroundColor"]);
        dc.clear();
        
        // System.println("[FR265S] 背景绘制完成，已移除白色边框");
    }
    
    /**
     * 绘制FR265S时间刻度
     * @param dc 绘图上下文
     * @param elementColors 配色方案
     */
    private function drawFR265STimeMarks(dc as Graphics.Dc, elementColors as Dictionary) as Void {
        // 使用FR965的时间刻度绘制逻辑
        
        for (var i = 0; i < 60; i++) {
            var angle = i * 6.0 * Math.PI / 180.0; // 每个刻度6度
            var isMainMark = (i % 5 == 0); // 主要刻度（12个小时）
            
            // FR265S专用：主要刻度(12,3,6,9)使用与数字相同的颜色
            var isMainNumber = (i == 0 || i == 15 || i == 30 || i == 45); // 对应12,3,6,9点位置
            var markColor;
            if (isMainMark && isMainNumber) {
                markColor = elementColors["mainNumbers"]; // 与主要数字颜色一致
            } else {
                markColor = elementColors["primaryColor"]; // 其他刻度使用默认颜色
            }
            
            dc.setColor(markColor, Graphics.COLOR_TRANSPARENT);
            
            var outerRadius = radius - 10;
            var innerRadius = isMainMark ? radius - 25 : radius - 15;
            var lineWidth = isMainMark ? 3 : 1;
            
            var x1 = centerX + outerRadius * Math.sin(angle);
            var y1 = centerY - outerRadius * Math.cos(angle);
            var x2 = centerX + innerRadius * Math.sin(angle);
            var y2 = centerY - innerRadius * Math.cos(angle);
            
            dc.setPenWidth(lineWidth);
            dc.drawLine(x1, y1, x2, y2);
        }
    }
    
    /**
     * 绘制FR265S数字 - 缩小字体为原来的三分之一
     * @param dc 绘图上下文
     * @param elementColors 配色方案
     */
    private function drawFR265SNumbers(dc as Graphics.Dc, elementColors as Dictionary) as Void {
        // FR265S专用：使用较小的字体
        var numberRadius = radius - 40;
        var font = Graphics.FONT_SMALL; // 从FONT_MEDIUM改为FONT_SMALL，进一步缩小字体
        
        // System.println("[FR265S] 绘制小时数字，使用字体: FONT_SMALL");
        
        for (var i = 1; i <= 12; i++) {
            var angle = (i * 30.0 - 90.0) * Math.PI / 180.0; // 12点为0度
            var x = centerX + numberRadius * Math.cos(angle);
            var y = centerY + numberRadius * Math.sin(angle);
            
            // 主要数字使用不同颜色
            var isMainNumber = (i == 12 || i == 3 || i == 6 || i == 9);
            var color = isMainNumber ? elementColors["mainNumbers"] : elementColors["otherNumbers"];
            
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, i.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        
        // System.println("[FR265S] 小时数字绘制完成");
    }
    
    /**
     * 绘制FR265S健康数据 - 使用FR965的布局和图标绘制方式
     * @param dc 绘图上下文
     * @param elementColors 配色方案
     */
    /**
     * 绘制FR265S健康数据 - 根据设置显示
     * @param dc 绘图上下文
     * @param elementColors 五行配色方案
     * @param settings 用户设置参数
     */
    private function drawFR265SHealthData(dc as Graphics.Dc, elementColors as Dictionary, settings as Dictionary or Null) as Void {
        try {
            // 计算健康数据位置 - FR265S专用：心率和步数向下移动6像素
            var iconSize = 16;
            
            // 心率位置 (左上方) - 向左移动8像素，向下移动8像素
            var heartRateX = centerX - 68; // 从-60向左移动8像素到-68
            var heartRateY = centerY - 12; // 从-17再向下移动5像素到-12
            
            // 步数位置 (右上方) - 向右移动8像素，向下移动8像素
            var stepsX = centerX + 68; // 从60向右移动8像素到68
            var stepsY = centerY - 12; // 从-17再向下移动5像素到-12
            
            // 卡路里位置 (左下方)
            var caloriesX = centerX - 60;
            var caloriesY = centerY + 40;
            
            // 天气位置 (右下方)
            var weatherX = centerX + 60;
            var weatherY = centerY + 40;
            
            // 电量位置 (底部中间) - 向下移动6像素
            var batteryX = centerX;
            var batteryY = centerY + 92; // 从+86再向下移动6像素到+92
            
            // 1. 绘制心率数据 (左上方) - 根据设置显示
            var showHeartRate = true;
            if (settings != null && settings.hasKey("showHeartRate")) {
                showHeartRate = settings["showHeartRate"];
            }
            
            if (showHeartRate) {
                var heartRate = getHeartRate();
                
                // 绘制心形图标
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                drawFR265SHeartIcon(dc, heartRateX, heartRateY - 8, iconSize);
                
                // 绘制心率数值
                var heartRateValue = heartRate.toString();
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(heartRateX, heartRateY + 6, Graphics.FONT_SYSTEM_XTINY, heartRateValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 2. 绘制步数数据 (右上方) - 根据设置显示
            var showSteps = true;
            if (settings != null && settings.hasKey("showSteps")) {
                showSteps = settings["showSteps"];
            }
            
            if (showSteps) {
                var steps = getSteps();
                var stepsValue = steps.toString();
                
                // 绘制脚印图标
                dc.setColor(0xFF9900, Graphics.COLOR_TRANSPARENT); // 橙色
                drawFR265SFootprintIcon(dc, stepsX, stepsY - 8, iconSize);
                
                // 绘制步数数值
                dc.setColor(0xFF9900, Graphics.COLOR_TRANSPARENT);
                dc.drawText(stepsX, stepsY + 6, Graphics.FONT_SYSTEM_XTINY, stepsValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 3. 绘制卡路里数据 (左下方) - 根据设置显示
            var showCalories = true;
            if (settings != null && settings.hasKey("showCalories")) {
                showCalories = settings["showCalories"];
            }
            
            if (showCalories) {
                var calories = getCalories();
                var caloriesValue = calories.toString();
                
                // 绘制火焰图标
                dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT); // 火焰色
                drawFR265SFireIcon(dc, caloriesX, caloriesY - 8, iconSize);
                
                // 绘制卡路里数值
                dc.setColor(0xFF6600, Graphics.COLOR_TRANSPARENT);
                dc.drawText(caloriesX, caloriesY + 6, Graphics.FONT_SYSTEM_XTINY, caloriesValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 4. 绘制天气数据 (右下方) - 根据设置显示
            var showWeather = true;
            if (settings != null && settings.hasKey("showWeather")) {
                showWeather = settings["showWeather"];
            }
            
            if (showWeather) {
                var weatherData = getWeatherData();
                
                // 格式化温度显示
                var temperature = weatherData[:temperature];
                var weatherValue;
                if (temperature != null) {
                    if (temperature instanceof Float || temperature instanceof Double) {
                        var roundedTemp = Math.round(temperature).toNumber();
                        weatherValue = roundedTemp.toString() + "°";
                    } else {
                        weatherValue = temperature.toString() + "°";
                    }
                } else {
                    weatherValue = "--°";
                }
                
                var weatherCondition = weatherData[:condition];
                // 确保weatherCondition不为null
                if (weatherCondition == null) {
                    weatherCondition = Weather.CONDITION_CLEAR;
                }
                
                // 绘制天气图标
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                drawFR265SWeatherIcon(dc, weatherX, weatherY - 8, iconSize, weatherCondition);
                
                // 绘制天气数值
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(weatherX, weatherY + 6, Graphics.FONT_SYSTEM_XTINY, weatherValue, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // 5. 绘制电量数据 (底部中间) - 根据设置显示
            var showBattery = true;
            if (settings != null && settings.hasKey("showBattery")) {
                showBattery = settings["showBattery"];
            }
            
            if (showBattery) {
                var battery = getBattery();
                var batteryValue = battery.toString() + "%";
                
                // 绘制电池图标 (平躺) - 精确控制间距
                var batteryIconX = batteryX - iconSize;
                var batteryTextX = batteryX;
                
                // 绘制电池图标
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                drawFR265SBatteryIcon(dc, batteryIconX, batteryY, iconSize);
                
                // 绘制电量数值
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(batteryTextX, batteryY, Graphics.FONT_SYSTEM_XTINY, batteryValue, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            
        } catch (ex) {
            // 静默处理异常
        }
    }
    
    /**
     * 绘制FR265S中心时间和日期信息 - 完全使用FR965的显示逻辑
     * @param dc 绘图上下文
     * @param clockTime 时间信息
     * @param elementColors 配色方案
     */
    /**
     * 绘制FR265S日期信息 - 根据设置显示
     * @param dc 绘图上下文
     * @param clockTime 时间信息
     * @param elementColors 五行配色方案
     * @param settings 用户设置参数
     */
    private function drawFR265SDateInfo(dc as Graphics.Dc, clockTime as Time.Moment, elementColors as Dictionary, settings as Dictionary or Null) as Void {
        // System.println("[FR265S] 开始绘制中心时间和日期信息");
        
        try {
            var clockTimeInfo = System.getClockTime();
            var today = Gregorian.info(clockTime, Time.FORMAT_MEDIUM);
            
            // System.println("[FR265S] 获取时间信息: " + clockTimeInfo.hour + ":" + clockTimeInfo.min + ":" + clockTimeInfo.sec);
            // System.println("[FR265S] 获取日期信息: " + today.year + "-" + today.month + "-" + today.day);
            
            // 绘制大号时间 - 24小时格式
            var hour = clockTimeInfo.hour.toNumber();
            var min = clockTimeInfo.min.toNumber();
            var hourStr = hour < 10 ? "0" + hour.toString() : hour.toString();
            var minStr = min < 10 ? "0" + min.toString() : min.toString();
            var timeText = hourStr + ":" + minStr;
            
            // System.println("[FR265S] 时间文本: " + timeText);
            
            // 绘制时间文本 - FR265S专用：缩小字体，向下移动8像素
            var timeY = centerY - 94; // 从-102再向下移动8像素到-94
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, timeY, Graphics.FONT_XTINY, timeText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // System.println("[FR265S] 时间绘制完成，位置: (" + centerX + ", " + timeY + ")，字体: FONT_XTINY");
            
            // 绘制日期信息
            var currentYear = today.year;
            var currentMonth = today.month;
            var currentDay = today.day;
            
            // System.println("[FR265S] 原始日期数据: 年=" + currentYear + ", 月=" + currentMonth + ", 日=" + currentDay);
            
            // 转换月份
            var monthNum = convertMonthToNumber(currentMonth);
            var dayNum = (currentDay != null && currentDay instanceof Number) ? currentDay : 27;
            var yearNum = (currentYear != null && currentYear instanceof Number) ? currentYear : getCurrentYear();
            
            // System.println("[FR265S] 转换后日期数据: 年=" + yearNum + ", 月=" + monthNum + ", 日=" + dayNum);
            
            var monthStr = monthNum < 10 ? "0" + monthNum.toString() : monthNum.toString();
            var dayStr = dayNum < 10 ? "0" + dayNum.toString() : dayNum.toString();
            
            // 计算星期
            var dayOfWeekNum = calculateDayOfWeek(yearNum, monthNum, dayNum);
            var weekdayIndex = dayOfWeekNum - 1;
            if (weekdayIndex < 0 || weekdayIndex >= 7) {
                weekdayIndex = 0;
            }
            
            // System.println("[FR265S] 星期计算: dayOfWeekNum=" + dayOfWeekNum + ", weekdayIndex=" + weekdayIndex);
            
            var dateString = monthStr + "月" + dayStr;
            var weekNames = ["日", "一", "二", "三", "四", "五", "六"];
            var weekText = "星期" + weekNames[weekdayIndex];
            
            // 计算农历 - 使用转换后的年份数据
            var lunarDate = convertToLunar(yearNum, monthNum, dayNum);
            if (lunarDate == null || lunarDate.equals("")) {
                lunarDate = "农历未知";
            }
            
            // System.println("[FR265S] 显示文本: 日期=" + dateString + ", 农历=" + lunarDate + ", 星期=" + weekText);
            
            // 使用中文字体
            var fontToUse = (chineseFont != null) ? chineseFont : Graphics.FONT_TINY;
            
            // 计算布局 - FR265S专用：向下移动5像素
            var dateWidth = dc.getTextWidthInPixels(dateString, fontToUse);
            var lunarWidth = dc.getTextWidthInPixels(lunarDate, fontToUse);
            var weekWidth = dc.getTextWidthInPixels(weekText, fontToUse);
            var spacing = 8;
            var totalWidth = dateWidth + lunarWidth + weekWidth + spacing * 2;
            var startX = centerX - totalWidth / 2 + 3; // 向右移动3像素
            var dateWeekY = centerY - 55; // 从-65再向下移动10像素到-55
            
            // System.println("[FR265S] 布局计算: 总宽度=" + totalWidth + ", 起始X=" + startX + ", Y=" + dateWeekY);
            
            // 绘制日期信息 - 根据设置显示
            var showDateInfo = true;
            if (settings != null && settings.hasKey("showDateInfo")) {
                showDateInfo = settings["showDateInfo"];
            }
            
            if (showDateInfo) {
                // 设置文本颜色为绿色
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                
                // 绘制日期
                var dateX = startX + dateWidth / 2;
                dc.drawText(dateX, dateWeekY, fontToUse, dateString, Graphics.TEXT_JUSTIFY_CENTER);
                
                // 绘制农历
                var lunarX = startX + dateWidth + spacing + lunarWidth / 2;
                dc.drawText(lunarX, dateWeekY, fontToUse, lunarDate, Graphics.TEXT_JUSTIFY_CENTER);
                
                // 绘制星期
                var weekX = startX + dateWidth + spacing + lunarWidth + spacing + weekWidth / 2;
                dc.drawText(weekX, dateWeekY, fontToUse, weekText, Graphics.TEXT_JUSTIFY_CENTER);
            }
            
            // System.println("[FR265S] 中心时间和日期信息绘制完成");
            
        } catch (ex) {
            // System.println("[FR265S] 中心时间和日期信息绘制异常: " + ex.getErrorMessage());
        }
    }
    
    /**
     * 绘制FR265S指针 - 完全使用FR965的五行配色逻辑
     * @param dc 绘图上下文
     * @param clockTime 时间信息
     * @param elementColors 配色方案
     */
    private function drawFR265SPointers(dc as Graphics.Dc, clockTime as Time.Moment, elementColors as Dictionary) as Void {
        // System.println("[FR265S] 开始绘制指针");
        
        try {
            var clockTimeInfo = System.getClockTime();
            
            // 安全获取时间值并进行null检查
            var hour = 0;
            var min = 0;
            var sec = 0;
            
            if (clockTimeInfo.hour != null) {
                hour = clockTimeInfo.hour.toNumber();
            }
            if (clockTimeInfo.min != null) {
                min = clockTimeInfo.min.toNumber();
            }
            if (clockTimeInfo.sec != null) {
                sec = clockTimeInfo.sec.toNumber();
            }
            
            // System.println("[FR265S] 时间值: " + hour + ":" + min + ":" + sec);
            
            // 计算指针角度
            var hourAngle = ((hour % 12) * 30 + min * 0.5) * Math.PI / 180;
            var minuteAngle = min * 6 * Math.PI / 180;
            var secondAngle = sec * 6 * Math.PI / 180;
            
            // System.println("[FR265S] 指针角度计算完成");
            
            // 获取今日和明日的五行配色
            var todayColors = calculateDailyFiveElementColors(null);
            var tomorrowColors = calculateTomorrowFiveElementColors();
            
            var hourColor = todayColors[0];      // 大吉色
            var minuteColor = todayColors[1];    // 次吉色
            var secondColor = todayColors[2];    // 平平色
            
            var tomorrowHourColor = tomorrowColors[0];
            var tomorrowMinuteColor = tomorrowColors[1];
            var tomorrowSecondColor = tomorrowColors[2];
            
            // System.println("[FR265S] 今日配色: 时针=" + hourColor + ", 分针=" + minuteColor + ", 秒针=" + secondColor);
            // System.println("[FR265S] 明日配色: 时针=" + tomorrowHourColor + ", 分针=" + tomorrowMinuteColor + ", 秒针=" + tomorrowSecondColor);
            
            // 计算指针长度 - 使用FR965的比例
            var originalHourLength = radius * 0.6;
            var originalMinuteLength = radius * 0.8;
            var originalSecondLength = radius * 0.9;
            
            // 按FR965的调整比例
            var hourLength = ((originalHourLength * 2 / 3 - 8) * 5 / 6 + 10).toNumber();
            var secondLength = (originalSecondLength - 24).toNumber();
            var minuteLength = ((hourLength + secondLength) / 2 + 5).toNumber();
            
            // 指针宽度
            var hourWidth = 24;
            var minuteWidth = 19;
            var secondWidth = 11;
            
            // System.println("[FR265S] 指针尺寸: 时针长度=" + hourLength + ", 分针长度=" + minuteLength + ", 秒针长度=" + secondLength);
            
            // 绘制时针
            // System.println("[FR265S] 开始绘制时针");
            drawFR265SArrowHand(dc, hourAngle, hourLength, hourWidth, 12, hourColor, tomorrowHourColor, "hour");
            
            // 绘制分针
            // System.println("[FR265S] 开始绘制分针");
            drawFR265SArrowHand(dc, minuteAngle, minuteLength, minuteWidth, 8, minuteColor, tomorrowMinuteColor, "minute");
            
            // 绘制秒针
            // System.println("[FR265S] 开始绘制秒针");
            drawFR265SArrowHand(dc, secondAngle, secondLength, secondWidth, 4, secondColor, tomorrowSecondColor, "second");
            
            // 绘制三层空心中心圆点
            // System.println("[FR265S] 开始绘制中心圆点");
            drawFR265SCenterCircles(dc, hourColor, minuteColor, secondColor);
            
            // System.println("[FR265S] 指针绘制完成");
            
        } catch (ex) {
            // System.println("[FR265S] 指针绘制异常: " + ex.getErrorMessage());
        }
    }
    
    /**
     * 绘制FR265S中心圆点 - 三层空心设计
     * @param dc 绘图上下文
     * @param hourColor 时针颜色
     * @param minuteColor 分针颜色
     * @param secondColor 秒针颜色
     */
    private function drawFR265SCenterCircles(dc as Graphics.Dc, hourColor as Number, minuteColor as Number, secondColor as Number) as Void {
        // System.println("[FR265S] 绘制三层中心圆点");
        
        // 外层圆（时针）
        dc.setColor(hourColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(centerX, centerY, 8);
        
        // 中层圆（分针）
        dc.setColor(minuteColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(centerX, centerY, 5);
        
        // 内层圆（秒针）
        dc.setColor(secondColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(centerX, centerY, 2);
        
        // System.println("[FR265S] 中心圆点绘制完成");
    }
    
    /**
     * 绘制FR265S箭头指针
     * @param dc 绘图上下文
     * @param angle 指针角度
     * @param length 指针长度
     * @param width 指针宽度
     * @param arrowSize 箭头尖端大小
     * @param bodyColor 主体颜色（今日配色）
     * @param tipColor 尖端颜色（明日配色）
     * @param type 指针类型
     */
    private function drawFR265SArrowHand(dc as Graphics.Dc, angle as Float, length as Number, width as Number, arrowSize as Number, bodyColor as Number, tipColor as Number, type as String) as Void {
        // System.println("[FR265S] 绘制" + type + "指针: 角度=" + angle + ", 长度=" + length + ", 宽度=" + width);
        
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
        
        // 指针形状参数
        var baseLength = length * 0.75;  // 主体长度
        var tipLength = length * 0.25;   // 尖端长度
        var tailWidth = width * 0.3;     // 尾部宽度
        var maxWidth = width;             // 最大宽度
        
        // 计算关键点坐标
        var tipX = centerX + (length * sin).toNumber();
        var tipY = centerY - (length * cos).toNumber();
        
        var baseEndX = centerX + (baseLength * sin).toNumber();
        var baseEndY = centerY - (baseLength * cos).toNumber();
        
        // 尾部点
        var leftTailX = centerX + (tailWidth / 2 * perpSin).toNumber();
        var leftTailY = centerY - (tailWidth / 2 * perpCos).toNumber();
        var rightTailX = centerX - (tailWidth / 2 * perpSin).toNumber();
        var rightTailY = centerY + (tailWidth / 2 * perpCos).toNumber();
        
        // 最宽处点
        var leftMaxX = baseEndX + (maxWidth / 2 * perpSin).toNumber();
        var leftMaxY = baseEndY - (maxWidth / 2 * perpCos).toNumber();
        var rightMaxX = baseEndX - (maxWidth / 2 * perpSin).toNumber();
        var rightMaxY = baseEndY + (maxWidth / 2 * perpCos).toNumber();
        
        // 绘制指针主体（今日配色）
        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        var pointerPoints = [
            [leftTailX, leftTailY],    // 尾部左侧
            [rightTailX, rightTailY],  // 尾部右侧
            [rightMaxX, rightMaxY],    // 最宽处右侧
            [tipX, tipY],              // 三角形尖端
            [leftMaxX, leftMaxY]       // 最宽处左侧
        ];
        dc.fillPolygon(pointerPoints);
        
        // 绘制明日配色小指针（菱形）
        drawFR265STomorrowMiniPointer(dc, angle, length, width, bodyColor, tipColor, sin, cos, perpSin, perpCos);
        
        // System.println("[FR265S] " + type + "指针绘制完成");
    }
    
    /**
     * 绘制FR265S明日配色小指针 - 菱形形状，从指针尖端向内5像素开始
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
    private function drawFR265STomorrowMiniPointer(dc as Graphics.Dc, angle as Float, length as Number, width as Number, bodyColor as Number, tipColor as Number, sin as Float, cos as Float, perpSin as Float, perpCos as Float) as Void {
        // 始终绘制明日配色小指针，无论今日配色与明日配色是否相同
        
        // 小指针的尺寸参数（按主指针比例缩小六分之一）
        var miniScale = 5.0 / 6.0; // 缩小六分之一
        var miniLength = (length * miniScale).toNumber();
        var miniWidth = (width * 0.4).toNumber(); // 宽度设为主指针的40%
        
        // 菱形小指针参数（与FR965保持一致）
        var diamondLength = 30; // 菱形长度
        var diamondWidth = miniWidth; // 菱形最大宽度（与FR965一致，不增加50%）
        var offsetFromTip = 5; // 从指针尖端向内的偏移距离
        
        // 计算菱形的关键点坐标
        // 菱形起始点（从指针尖端向内5像素）
        var diamondStartX = centerX + ((miniLength - offsetFromTip) * sin).toNumber();
        var diamondStartY = centerY - ((miniLength - offsetFromTip) * cos).toNumber();
        
        // 菱形结束点（向内延伸diamondLength像素）
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
        
        // 根据今日配色与明日配色的关系选择边框策略
        var borderOffset = 2;
        var borderDiamondHalfWidth = diamondHalfWidth + borderOffset;
        
        // 计算边框菱形的关键点
        var borderDiamondStartX = centerX + ((miniLength - offsetFromTip + borderOffset) * sin).toNumber();
        var borderDiamondStartY = centerY - ((miniLength - offsetFromTip + borderOffset) * cos).toNumber();
        
        var borderDiamondEndX = centerX + ((miniLength - offsetFromTip - diamondLength - borderOffset) * sin).toNumber();
        var borderDiamondEndY = centerY - ((miniLength - offsetFromTip - diamondLength - borderOffset) * cos).toNumber();
        
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
            
            var strokeDiamondStartX = centerX + ((miniLength - offsetFromTip + strokeOffset) * sin).toNumber();
            var strokeDiamondStartY = centerY - ((miniLength - offsetFromTip + strokeOffset) * cos).toNumber();
            
            var strokeDiamondEndX = centerX + ((miniLength - offsetFromTip - diamondLength - strokeOffset) * sin).toNumber();
            var strokeDiamondEndY = centerY - ((miniLength - offsetFromTip - diamondLength - strokeOffset) * cos).toNumber();
            
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
    
    // 辅助方法 - 获取健康数据
    private function getSteps() as Number {
        try {
            var activityInfo = ActivityMonitor.getInfo();
            if (activityInfo != null && activityInfo.steps != null) {
                return activityInfo.steps.toNumber();
            }
        } catch (ex) {
            // 获取失败时返回默认值
        }
        return 0;
    }
    
    private function getHeartRate() as Number {
        try {
            var hrHistory = ActivityMonitor.getHeartRateHistory(1, true);
            if (hrHistory != null && hrHistory.next() != null) {
                var sample = hrHistory.next();
                if (sample != null && sample.heartRate != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return sample.heartRate.toNumber();
                }
            }
        } catch (ex) {
            // 获取失败时返回默认值
        }
        return 72; // 默认心率
    }
    
    private function getCalories() as Number {
        try {
            var activityInfo = ActivityMonitor.getInfo();
            if (activityInfo != null && activityInfo.calories != null) {
                return activityInfo.calories.toNumber();
            }
        } catch (ex) {
            // 获取失败时返回默认值
        }
        return 0;
    }
    
    private function getBattery() as Number {
        try {
            var stats = System.getSystemStats();
            if (stats != null && stats.battery != null) {
                return stats.battery.toNumber();
            }
        } catch (ex) {
            // 类型转换失败时返回默认值
        }
        return 100; // 默认电量
    }
    
    private function getWeatherData() as Dictionary {
        // // System.println("[FR265S] 开始获取天气数据");
        
        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null) {
                // // System.println("[FR265S] 获取到天气条件对象");
                
                var temperature = 25; // 默认温度
                var condition = Weather.CONDITION_CLEAR; // 默认晴天
                
                if (conditions.temperature != null) {
                    temperature = conditions.temperature.toNumber();
                    // // System.println("[FR265S] 获取到温度: " + temperature);
                } else {
                    // // System.println("[FR265S] 温度为null，使用默认值");
                }
                
                if (conditions.condition != null) {
                    condition = conditions.condition;
                    // // System.println("[FR265S] 获取到天气条件: " + condition);
                } else {
                    // // System.println("[FR265S] 天气条件为null，使用默认值");
                }
                
                return {
                    :temperature => temperature,
                    :condition => condition
                };
            } else {
                // // System.println("[FR265S] 天气条件对象为null");
            }
        } catch (ex) {
            // // System.println("[FR265S] 获取天气数据异常: " + ex.getErrorMessage());
        }
        
        // 返回默认天气数据，确保condition不为null
        // System.println("[FR265S] 返回默认天气数据");
        return {
            :temperature => 25,
            :condition => Weather.CONDITION_CLEAR
        };
    }
    
    private function getWeatherIcon(condition as Number) as String {
        switch (condition) {
            case Weather.CONDITION_CLEAR:
                return "☀️";
            case Weather.CONDITION_PARTLY_CLOUDY:
                return "⛅";
            case Weather.CONDITION_CLOUDY:
                return "☁️";
            case Weather.CONDITION_RAIN:
                return "🌧️";
            case Weather.CONDITION_SNOW:
                return "❄️";
            default:
                return "☀️";
        }
    }
    
    /**
     * 绘制FR265S专用心形图标 (基于FR965的设计)
     */
    private function drawFR265SHeartIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        
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
     * 绘制FR265S专用脚印图标 (基于FR965的设计)
     */
    private function drawFR265SFootprintIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        var eighthSize = size / 8;
        
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
     * 绘制FR265S专用火焰图标 (基于FR965的设计)
     */
    private function drawFR265SFireIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        var eighthSize = size / 8;
        
        // 绘制火焰主体外层
        var outerFlame = [
            [x - halfSize + 1, y + halfSize],
            [x - quarterSize, y],
            [x - eighthSize, y - quarterSize + 2],
            [x, y - halfSize + 1],
            [x + eighthSize, y - quarterSize + 2],
            [x + quarterSize, y],
            [x + halfSize - 1, y + halfSize]
        ];
        dc.fillPolygon(outerFlame);
        
        // 绘制火焰中层 (橙红色)
        dc.setColor(0xFF4400, Graphics.COLOR_TRANSPARENT);
        var middleFlame = [
            [x - quarterSize + 2, y + quarterSize],
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
    }
    
    /**
     * 绘制FR265S专用天气图标 (基于FR965的设计)
     */
    private function drawFR265SWeatherIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number, condition as Number) as Void {
        var halfSize = size / 2;
        var quarterSize = size / 4;
        
        // 根据天气条件绘制不同图标
        if (condition != null) {
            switch (condition) {
                case Weather.CONDITION_CLEAR:
                case Weather.CONDITION_FAIR:
                case Weather.CONDITION_PARTLY_CLEAR:
                    // 绘制太阳
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
                    break;
                    
                case Weather.CONDITION_CLOUDY:
                case Weather.CONDITION_MOSTLY_CLOUDY:
                case Weather.CONDITION_PARTLY_CLOUDY:
                    // 绘制云朵
                    dc.setColor(0xCCCCCC, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(x - quarterSize, y, quarterSize);
                    dc.fillCircle(x + quarterSize, y, quarterSize);
                    dc.fillCircle(x, y - quarterSize/2, quarterSize);
                    break;
                    
                default:
                    // 默认绘制太阳
                    dc.setColor(0xFFDD00, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(x, y, halfSize - 1);
                    dc.setColor(0xFFFF44, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(x, y, quarterSize);
                    break;
            }
        } else {
            // condition为null时，绘制问号
            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, Graphics.FONT_SYSTEM_XTINY, "?", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
    
    /**
     * 绘制FR265S专用电池图标 (基于FR965的设计)
     */
    private function drawFR265SBatteryIcon(dc as Graphics.Dc, x as Number, y as Number, size as Number) as Void {
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
        
        // 绘制电池内部电量指示 (绿色渐变效果)
        var innerWidth = width - 6;
        var innerHeight = height - 6;
        dc.setColor(0x66FF66, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x - innerWidth/2, y - innerHeight/2, innerWidth * 0.8, innerHeight);
    }
    
    // ========== 辅助方法 ==========
    
    /**
     * 转换月份枚举为数字
     * @param monthEnum 月份枚举值
     * @return 月份数字(1-12)
     */
     /**
      * 获取动态当前年份，避免硬编码
      * @return 当前年份
      */
     private function getCurrentYear() as Number {
         var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
         var year = today.year;
         return (year != null && year instanceof Number) ? year : 2026;
     }
     
     /**
      * 使用蔡勒公式计算任意日期是星期几
      * @param year 年份
      * @param month 月份 (1-12)
      * @param day 日期 (1-31)
      * @return 星期几 (1=星期日, 2=星期一, ..., 7=星期六)
      */
     private function calculateZellerWeekday(year as Number, month as Number, day as Number) as Number {
         // 蔡勒公式：1月和2月视为上一年的13月和14月
         var m = month;
         var y = year;
         
         if (m == 1 || m == 2) {
             m = m + 12;
             y = y - 1;
         }
         
         var c = y / 100;  // 世纪数
         var y_mod = y % 100;  // 年份后两位
         
         // 蔡勒公式
         var w = (y_mod + y_mod / 4 + c / 4 - 2 * c + 26 * (m + 1) / 10 + day - 1) % 7;
         
         // 转换为我们的格式：1=星期日, 2=星期一, ..., 7=星期六
         if (w <= 0) {
             w = w + 7;
         }
         
         return w + 1;  // 调整为1-7范围
     }
     
     private function convertMonthToNumber(monthEnum) as Number {
        // System.println("[FR265S] convertMonthToNumber输入: " + monthEnum);
        
        // 优先处理数字类型（真机环境常见）
        if (monthEnum instanceof Number) {
            var numValue = monthEnum.toNumber();
            // System.println("[FR265S] 数字类型月份: " + numValue);
            
            // 检测月份范围并进行相应转换
            if (numValue >= 1 && numValue <= 12) {
                // 标准1-12范围，直接返回
                // System.println("[FR265S] 标准范围月份: " + numValue);
                return numValue;
            } else if (numValue >= 0 && numValue <= 11) {
                // 0-11范围（真机常见），转换为1-12
                var convertedValue = numValue + 1;
                // System.println("[FR265S] 0-11范围转换: " + numValue + " -> " + convertedValue);
                return convertedValue;
            } else {
                // 超出范围，使用默认值
                // System.println("[FR265S] 超出范围，使用默认值7");
                return 7;
            }
        }
        
        // 处理字符串类型
        if (monthEnum instanceof String) {
            var monthStr = monthEnum.toString();
            // System.println("[FR265S] 字符串类型月份: " + monthStr);
            
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
                    // System.println("[FR265S] 字符串转数字: " + numFromStr);
                    return numFromStr;
                }
            } catch (ex) {
                // 转换失败，继续其他处理
            }
        }
        
        // 默认返回7月
        // System.println("[FR265S] 无法识别月份类型，返回默认值7");
        return 7;
    }
    
    /**
     * 计算指定日期是星期几 - 使用与FR965相同的基准日期算法
     * @param year 年份
     * @param month 月份(1-12)
     * @param day 日期
     * @return 星期几(1=星期日, 2=星期一, ..., 7=星期六)
     */
    private function calculateDayOfWeek(year as Number, month as Number, day as Number) as Number {
        // System.println("[FR265S] calculateDayOfWeek输入: " + year + "-" + month + "-" + day);
        
        // 使用基于已知基准日期的相对计算方法（与FR965相同）
        // 使用动态基准日期，避免每年修改
        var currentYear = getCurrentYear();
        
        // 动态计算基准日期：使用当前年份的1月1日
        var baseYear = currentYear;
        var baseMonth = 1;
        var baseDay = 1;
        var baseDayOfWeek = calculateZellerWeekday(baseYear, baseMonth, baseDay);
        
        // 计算目标日期与基准日期的天数差
        var targetDays = calculateDaysSince1900(year, month, day);
        var baseDays = calculateDaysSince1900(baseYear, baseMonth, baseDay);
        var daysDiff = targetDays - baseDays;
        
        // 计算星期（使用正确的模运算）
        var dayOfWeek = ((baseDayOfWeek - 1 + daysDiff) % 7) + 1;
        
        // 确保结果在1-7范围内
        if (dayOfWeek <= 0) {
            dayOfWeek += 7;
        }
        
        // System.println("[FR265S] 星期计算调试: targetDays=" + targetDays + ", baseDays=" + baseDays + ", daysDiff=" + daysDiff + ", baseDayOfWeek=" + baseDayOfWeek + ", dayOfWeek=" + dayOfWeek);
        
        // System.println("[FR265S] 星期计算结果: " + dayOfWeek);
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
     * 转换为农历日期 - 使用与FR965相同的精确算法
     * @param year 公历年份
     * @param month 公历月份
     * @param day 公历日期
     * @return 农历日期字符串
     */
    private function convertToLunar(year as Number, month as Number, day as Number) as String {
        System.println("[FR265S] convertToLunar输入: " + year + "-" + month + "-" + day);
        
        // 农历月份名称
        var lunarMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"];
        
        // 农历日期名称
        var lunarDays = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ];
        
        // 使用与FR965相同的精确农历算法
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
        
        // System.println("[FR265S] 农历计算结果: " + finalResult);
        return finalResult;
    }
    
    /**
     * 计算农历日期的核心算法 - 基于6tail/lunar标准算法
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
        
        // 标准农历年份数据（1900-2100年）
        var lunarInfo = [
            0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
            0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
            0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
            0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
            0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
            0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,
            0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
            0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6,
            0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
            0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,
            0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
            0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
            0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea66,0x0d530,
            0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
            0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
            0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,
            0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
            0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
            0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
            0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
            0x0d520
        ];
        
        // 基准日期：1900年1月31日 = 农历1900年正月初一
        var baseYear = 1900;
        var baseMonth = 1;
        var baseDay = 31;
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
     * 计算儒略日数
     */
    private function getJulianDay(year as Number, month as Number, day as Number) as Number {
        if (month <= 2) {
            month += 12;
            year -= 1;
        }
        
        var a = year / 100;
        var b = 2 - a + a / 4;
        
        var jd = (365.25 * (year + 4716)).toNumber() + (30.6001 * (month + 1)).toNumber() + day + b - 1524;
        
        return jd;
    }
    
    /**
     * 计算农历年的总天数
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
        
        // 计算12个普通月的额外天数
        for (var month = 1; month <= 12; month++) {
            if (((yearData >> (16 - month)) & 0x1) != 0) {
                totalDays += 1;
            }
        }
        
        // 处理闰月
        var leapMonth = getLeapMonth(year, lunarYearData);
        if (leapMonth > 0) {
            var leapDays = ((yearData & 0x10000) != 0) ? 30 : 29;
            totalDays += leapDays;
        }
        
        return totalDays;
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
        return ((info >> (16 - lunarMonth)) & 0x1) ? 30 : 29;
    }
    
    /**
     * 获取农历年的闰月月份
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
     * 计算一年中的第几天
     * @param month 月份
     * @param day 日期
     * @param year 年份
     * @return 一年中的第几天
     */
    private function getDayOfYear(month as Number, day as Number, year as Number) as Number {
        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        
        // 检查闰年
        if (isLeapYear(year)) {
            daysInMonth[1] = 29;
        }
        
        var totalDays = 0;
        for (var m = 1; m < month; m++) {
            totalDays += daysInMonth[m - 1];
        }
        totalDays += day;
        
        return totalDays;
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
     * 计算指定日期的五行配色
     * @param today 日期信息对象，如果为null则使用当前日期
     * @return 包含时针、分针、秒针颜色的数组 [大吉色, 次吉色, 平平色]
     */
    private function calculateDailyFiveElementColors(today) as Array {
        try {
            // System.println("[FR265S] 开始计算五行配色");
            
            // 如果没有传入日期参数，则使用当前日期
            if (today == null) {
                today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            }
            
            // 获取当前日期
            var year = today.year;
            var month = today.month;
            var day = today.day;
            
            // 安全转换为数字类型
            var yearNum = (year != null && year instanceof Number) ? year : 2026;
            var monthNum = convertMonthToNumber(month);
            var dayNum = (day != null && day instanceof Number) ? day : 29;
            
            System.println("[FR265S] 日期: " + yearNum + "-" + monthNum + "-" + dayNum);
            
            // 使用精确的儒略日算法计算日干支
            var jd = getJulianDay(yearNum, monthNum, dayNum);
            
            // 修正值 +18 是基于 2026-01-02 (乙巳, JD 2461043) 推算得出的
            // JD 2461043 % 60 = 23
            // 乙巳 = 41
            // (23 + 18) % 60 = 41
            var ganZhiIndex = (jd + 18) % 60;
            if (ganZhiIndex < 0) {
                ganZhiIndex += 60;
            }
            
            var dayDiZhi = ganZhiIndex % 12;
            
            System.println("[FR265S] 日地支: " + dayDiZhi);
            
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
            
            System.println("[FR265S] 日五行: " + dayElement);
            
            // 根据五行相生理论计算配色
            // 大吉：生我者（印）。火日，木（绿）生火。
            // 次吉：克我者（官杀）。火日，水（黑）克火。
            // 平平：我生者（食伤）。火日，火生土（黄）。
            var mostLucky = (dayElement + 4) % 5;        // 大吉：生我者
            var secondLucky = (dayElement + 3) % 5;      // 次吉：克我者
            var normalLucky = (dayElement + 1) % 5;      // 平平：我生者
            
            // 定义五行颜色映射
            var elementColorMap = [
                0x00FF00,  // 木 - 绿色
                0xFF0000,  // 火 - 红色
                0xFFFF00,  // 土 - 黄色
                0xFFFFFF,  // 金 - 白色
                0x000000   // 水 - 纯黑色
            ];
            
            var colors = [
                elementColorMap[mostLucky],    // 时针颜色（大吉）
                elementColorMap[secondLucky],  // 分针颜色（次吉）
                elementColorMap[normalLucky]   // 秒针颜色（平平）
            ];
            
            // System.println("[FR265S] 五行配色计算完成: [" + colors[0] + ", " + colors[1] + ", " + colors[2] + "]");
            
            return colors;
        } catch (ex) {
            // System.println("[FR265S] 五行配色计算异常: " + ex.getErrorMessage());
            // 默认返回黄红黑配色
            return [0xFFFF00, 0xFF0000, 0x000000];
        }
    }
    
    /**
     * 获取明日的五行配色
     * @return 包含明日时针、分针、秒针颜色的数组 [大吉色, 次吉色, 平平色]
     */
    private function calculateTomorrowFiveElementColors() as Array {
        try {
            // System.println("[FR265S] 开始计算明日五行配色");
            
            // 获取明日的日期
            var tomorrow = new Time.Moment(Time.now().value() + 24 * 60 * 60);
            var tomorrowInfo = Gregorian.info(tomorrow, Time.FORMAT_MEDIUM);
            
            // 计算明日的五行配色
            return calculateDailyFiveElementColors(tomorrowInfo);
        } catch (ex) {
            // System.println("[FR265S] 明日五行配色计算异常: " + ex.getErrorMessage());
            // 如果出错，返回默认配色
            return calculateDailyFiveElementColors(null);
        }
    }
}