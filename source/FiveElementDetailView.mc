import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.Application.Storage;

/**
 * 五行配色表盘详细信息视图
 * 显示更详细的健康和环境数据
 */
class FiveElementDetailView extends WatchUi.View {

    // 页面常量
    const TOTAL_PAGES = 3;
    const PAGE_HEALTH = 0;
    const PAGE_WEATHER = 1;
    const PAGE_ELEMENT = 2;
    
    // 布局常量
    const LINE_HEIGHT = 35;
    const START_Y = 70;
    const MARGIN_X = 30;
    const INDICATOR_RADIUS = 3;
    
    // 阈值常量
    const STEP_GOAL_DEFAULT = 10000;
    const CALORIE_GOAL_DEFAULT = 2000;
    const ACTIVE_GOAL_DEFAULT = 30;
    const HEART_RATE_REST_MAX = 60;
    const HEART_RATE_LIGHT_MAX = 100;
    const HEART_RATE_MODERATE_MAX = 140;
    const HEART_RATE_VIGOROUS_MAX = 170;
    
    private var _currentPage as Lang.Number = 0;
    private var _totalPages as Lang.Number = TOTAL_PAGES;

    /**
     * 初始化详细视图
     */
    function initialize() {
        View.initialize();
    }

    /**
     * 加载资源
     * @param dc 绘图上下文
     */
    function onLayout(dc as Graphics.Dc) as Void {
        // 设置布局
    }

    /**
     * 绘制详细信息界面
     * @param dc 绘图上下文
     */
    function onUpdate(dc as Graphics.Dc) as Void {
        // 清除屏幕
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var deviceSettings = System.getDeviceSettings();
        var width = deviceSettings.screenWidth;
        var height = deviceSettings.screenHeight;
        
        // 绘制页面指示器
        _drawPageIndicator(dc, width, height);
        
        // 根据当前页面绘制不同内容
        switch (_currentPage) {
            case 0:
                _drawHealthPage(dc, width, height);
                break;
            case 1:
                _drawEnvironmentPage(dc, width, height);
                break;
            case 2:
                _drawFiveElementPage(dc, width, height);
                break;
        }
        
        // 绘制底部导航提示
        _drawNavigationHints(dc, width, height);
    }

    /**
     * 绘制页面指示器
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawPageIndicator(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        var centerX = width / 2;
        var y = 15;
        var dotSize = 4;
        var spacing = 12;
        
        for (var i = 0; i < _totalPages; i++) {
            var x = centerX - ((_totalPages - 1) * spacing / 2) + (i * spacing);
            
            if (i == _currentPage) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotSize);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(x, y, dotSize);
            }
        }
    }

    /**
     * 绘制健康数据页面
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawHealthPage(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        // 页面标题
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            35,
            Graphics.FONT_SMALL,
            "健康数据",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var startY = START_Y;
        var lineHeight = LINE_HEIGHT;
        
        // 获取活动监测数据
        var activityInfo = ActivityMonitor.getInfo();
        
        // 步数详情
        var steps = activityInfo.steps != null ? activityInfo.steps : 0;
        var stepGoal = activityInfo.stepGoal != null ? activityInfo.stepGoal : STEP_GOAL_DEFAULT;
        var stepProgress = (steps.toFloat() / stepGoal.toFloat() * 100).toNumber();
        
        _drawDetailItem(dc, "🚶 " + Application.loadResource(Rez.Strings.Steps), steps.toString() + " / " + stepGoal.toString(), 
                       stepProgress.toString() + "%", MARGIN_X, startY, width);
        
        // 卡路里详情
        var calories = activityInfo.calories != null ? activityInfo.calories : 0;
        var calorieGoal = activityInfo.activeMinutesWeek != null ? 
                         activityInfo.activeMinutesWeek.total * 10 : CALORIE_GOAL_DEFAULT;
        var calorieProgress = calories > 0 ? (calories.toFloat() / calorieGoal.toFloat() * 100).toNumber() : 0;
        
        _drawDetailItem(dc, "🔥 " + Application.loadResource(Rez.Strings.Calories), calories.toString() + " / " + calorieGoal.toString(), 
                       calorieProgress.toString() + "%", MARGIN_X, startY + lineHeight, width);
        
        // 心率详情
        var heartRate = _getHeartRate();
        var heartRateZone = _getHeartRateZone(heartRate);
        
        _drawDetailItem(dc, Application.loadResource(Rez.Strings.HeartRate), heartRate.toString() + " bpm", 
                       heartRateZone, 30, startY + lineHeight * 2, width);
        
        // 活动时间
        var activeMinutes = activityInfo.activeMinutesDay != null ? 
                           activityInfo.activeMinutesDay.total : 0;
        var activeGoal = 30; // 默认目标30分钟
        var activeProgress = (activeMinutes.toFloat() / activeGoal.toFloat() * 100).toNumber();
        
        _drawDetailItem(dc, "活动时间", activeMinutes.toString() + " 分钟", 
                       activeProgress.toString() + "%", 30, startY + lineHeight * 3, width);
        
        // 睡眠质量（如果可用）
        if (activityInfo has :sleepScore && activityInfo.sleepScore != null) {
            var sleepScore = activityInfo.sleepScore;
            var sleepQuality = _getSleepQuality(sleepScore);
            
            _drawDetailItem(dc, "睡眠质量", sleepScore.toString() + " 分", 
                           sleepQuality, 30, startY + lineHeight * 4, width);
        }
    }

    /**
     * 绘制环境数据页面
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawEnvironmentPage(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        // 页面标题
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            35,
            Graphics.FONT_SMALL,
            "环境信息",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var startY = 70;
        var lineHeight = 35;
        
        // 获取天气信息
        var temperature = _getWeatherTemperature();
        var weatherCondition = _getWeatherCondition();
        
        _drawDetailItem(dc, "温度", temperature.toString() + "°C", 
                       weatherCondition, 30, startY, width);
        
        // 湿度（模拟数据）
        var humidity = 65; // 模拟湿度数据
        var humidityLevel = _getHumidityLevel(humidity);
        
        _drawDetailItem(dc, "湿度", humidity.toString() + "%", 
                       humidityLevel, 30, startY + lineHeight, width);
        
        // 紫外线指数（模拟数据）
        var uvIndex = 3; // 模拟UV指数
        var uvLevel = _getUVLevel(uvIndex);
        
        _drawDetailItem(dc, "紫外线", "指数 " + uvIndex.toString(), 
                       uvLevel, 30, startY + lineHeight * 2, width);
        
        // 空气质量（模拟数据）
        var airQuality = 85; // 模拟空气质量指数
        var airLevel = _getAirQualityLevel(airQuality);
        
        _drawDetailItem(dc, "空气质量", "AQI " + airQuality.toString(), 
                       airLevel, 30, startY + lineHeight * 3, width);
        
        // 日出日落时间
        var sunriseTime = "06:30";
        var sunsetTime = "18:45";
        
        _drawDetailItem(dc, "日出时间", sunriseTime, 
                       "日落 " + sunsetTime, 30, startY + lineHeight * 4, width);
    }

    /**
     * 绘制五行配色页面
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawFiveElementPage(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        // 页面标题
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            35,
            Graphics.FONT_SMALL,
            "五行配色",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var centerX = width / 2;
        var centerY = height / 2;
        
        // 获取当前五行配色
        var elementIndex = Storage.getValue("elementIndex");
        if (elementIndex == null) { elementIndex = 0; }
        
        var elements = ["木", "火", "土", "金", "水"];
        var colors = [
            [Graphics.COLOR_GREEN, Graphics.COLOR_DK_GREEN],
            [Graphics.COLOR_RED, Graphics.COLOR_DK_RED],
            [Graphics.COLOR_YELLOW, Graphics.COLOR_ORANGE],
            [Graphics.COLOR_WHITE, Graphics.COLOR_LT_GRAY],
            [Graphics.COLOR_BLUE, Graphics.COLOR_DK_BLUE]
        ];
        var descriptions = [
            "生机盎然，适合运动",
            "热情活力，充满能量",
            "稳重踏实，平衡发展",
            "清净明亮，专注思考",
            "深邃宁静，内心平和"
        ];
        
        // 绘制当前五行元素
        dc.setColor(colors[elementIndex][0], Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY - 20, 40);
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY - 30,
            Graphics.FONT_LARGE,
            elements[elementIndex],
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // 绘制描述
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY + 30,
            Graphics.FONT_SMALL,
            descriptions[elementIndex],
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // 绘制五行相生相克关系
        _drawFiveElementRelation(dc, centerX, centerY + 80, elementIndex);
        
        // 绘制配色建议
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var suggestion = _getColorSuggestion(elementIndex);
        dc.drawText(
            centerX,
            height - 40,
            Graphics.FONT_XTINY,
            suggestion,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    /**
     * 绘制详细数据项
     * @param dc 绘图上下文
     * @param label 标签
     * @param value 值
     * @param extra 额外信息
     * @param x X坐标
     * @param y Y坐标
     * @param width 宽度
     */
    private function _drawDetailItem(dc as Graphics.Dc, label as Lang.String, value as Lang.String,
                                    extra as Lang.String, x as Lang.Number, y as Lang.Number, width as Lang.Number) as Void {
        // 绘制标签
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);
        
        // 绘制值
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + 12, Graphics.FONT_SMALL, value, Graphics.TEXT_JUSTIFY_LEFT);
        
        // 绘制额外信息
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 30, y + 12, Graphics.FONT_XTINY, extra, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    /**
     * 绘制五行关系
     * @param dc 绘图上下文
     * @param centerX 中心X坐标
     * @param centerY 中心Y坐标
     * @param currentElement 当前元素索引
     */
    private function _drawFiveElementRelation(dc as Graphics.Dc, centerX as Lang.Number, centerY as Lang.Number, currentElement as Lang.Number) as Void {
        var elements = ["木", "火", "土", "金", "水"];
        var colors = [
            Graphics.COLOR_GREEN, Graphics.COLOR_RED, Graphics.COLOR_YELLOW,
            Graphics.COLOR_WHITE, Graphics.COLOR_BLUE
        ];
        
        var radius = 25;
        var positions = [
            [centerX, centerY - radius],           // 木 - 上
            [centerX + radius, centerY - radius/2], // 火 - 右上
            [centerX + radius, centerY + radius/2], // 土 - 右下
            [centerX, centerY + radius],           // 金 - 下
            [centerX - radius, centerY]           // 水 - 左
        ];
        
        // 绘制五个元素
        for (var i = 0; i < 5; i++) {
            if (i == currentElement) {
                dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(positions[i][0], positions[i][1], 8);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(positions[i][0], positions[i][1], 6);
            }
            
            dc.drawText(
                positions[i][0],
                positions[i][1] - 6,
                Graphics.FONT_XTINY,
                elements[i],
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    /**
     * 绘制导航提示
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawNavigationHints(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(20, height - 25, width - 20, height - 25);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height - 20,
            Graphics.FONT_XTINY,
            "左右切换页面 返回退出",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // 辅助方法
    private function _getHeartRate() as Lang.Number {
        // 尝试获取心率数据，如果不可用则返回默认值
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

    private function _getHeartRateZone(heartRate as Lang.Number) as Lang.String {
        if (heartRate < 60) { return "休息"; }
        else if (heartRate < 100) { return "轻度"; }
        else if (heartRate < 140) { return "中度"; }
        else if (heartRate < 170) { return "剧烈"; }
        else { return "极限"; }
    }

    private function _getSleepQuality(score as Lang.Number) as Lang.String {
        if (score >= 80) { return "优秀"; }
        else if (score >= 60) { return "良好"; }
        else if (score >= 40) { return "一般"; }
        else { return "较差"; }
    }

    private function _getWeatherTemperature() as Lang.Number {
        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null && conditions.temperature != null) {
                return conditions.temperature;
            }
        } catch (ex) {
            // 忽略异常，返回默认值
        }
        return 24; // 默认温度
    }

    private function _getWeatherCondition() as Lang.String {
        try {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null && conditions.condition != null) {
                return _mapWeatherConditionToString(conditions.condition);
            }
        } catch (ex) {
            // 忽略异常，返回默认值
        }
        return Application.loadResource(Rez.Strings.WeatherSunny); // 默认天气状况
    }

    /**
     * 将Garmin天气状况映射为中文描述
     * @param condition Garmin天气状况
     * @return 对应的中文描述
     */
    private function _mapWeatherConditionToString(condition as Lang.Number) as Lang.String {
        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_PARTLY_CLEAR:
                return "晴朗";
            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
                return "多云";
            case Weather.CONDITION_PARTLY_CLOUDY:
                return "局部多云";
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
                return "有雨";
            case Weather.CONDITION_LIGHT_RAIN:
                return "小雨";
            case Weather.CONDITION_HEAVY_RAIN:
                return "大雨";
            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_CHANCE_OF_SNOW:
                return "有雪";
            case Weather.CONDITION_LIGHT_SNOW:
                return "小雪";
            case Weather.CONDITION_HEAVY_SNOW:
                return "大雪";
            default:
                return "晴朗";
        }
    }

    private function _getHumidityLevel(humidity as Lang.Number) as Lang.String {
        if (humidity < 30) { return "干燥"; }
        else if (humidity < 60) { return "舒适"; }
        else if (humidity < 80) { return "潮湿"; }
        else { return "很潮湿"; }
    }

    private function _getUVLevel(uvIndex as Lang.Number) as Lang.String {
        if (uvIndex <= 2) { return "低"; }
        else if (uvIndex <= 5) { return "中等"; }
        else if (uvIndex <= 7) { return "高"; }
        else if (uvIndex <= 10) { return "很高"; }
        else { return "极高"; }
    }

    private function _getAirQualityLevel(aqi as Lang.Number) as Lang.String {
        if (aqi <= 50) { return "优"; }
        else if (aqi <= 100) { return "良"; }
        else if (aqi <= 150) { return "轻度污染"; }
        else if (aqi <= 200) { return "中度污染"; }
        else { return "重度污染"; }
    }

    private function _getColorSuggestion(elementIndex as Lang.Number) as Lang.String {
        var suggestions = [
            "今日宜穿：绿色系服装",
            "今日宜穿：红色系服装",
            "今日宜穿：黄色系服装",
            "今日宜穿：白色系服装",
            "今日宜穿：蓝色系服装"
        ];
        return suggestions[elementIndex];
    }

    /**
     * 切换到下一页
     */
    function nextPage() as Void {
        _currentPage = (_currentPage + 1) % _totalPages;
        WatchUi.requestUpdate();
    }

    /**
     * 切换到上一页
     */
    function previousPage() as Void {
        _currentPage = (_currentPage - 1 + _totalPages) % _totalPages;
        WatchUi.requestUpdate();
    }

    /**
     * 获取当前页面
     * @return 当前页面索引
     */
    function getCurrentPage() as Lang.Number {
        return _currentPage;
    }
}