# 五行配色API使用指南

## 概述

经过优化后的五行配色系统现在支持获取任意日期的配色信息，为未来功能扩展提供了强大的基础。

## 核心方法

### 1. calculateDailyFiveElementColors(today)

**功能**: 计算指定日期的五行配色

**参数**:
- `today`: 日期信息对象（Gregorian.info返回的对象），如果为null则使用当前日期

**返回值**: 
- Array[3] - 包含时针、分针、秒针颜色的数组
  - [0]: 时针颜色（大吉色）
  - [1]: 分针颜色（次吉色）  
  - [2]: 秒针颜色（平平色）

**使用示例**:
```monkey-c
// 获取当前日期的五行配色
var todayColors = calculateDailyFiveElementColors(null);

// 获取指定日期的五行配色
var specificDate = Gregorian.info(someTimeObject, Time.FORMAT_MEDIUM);
var specificColors = calculateDailyFiveElementColors(specificDate);
```

### 2. getTomorrowFiveElementColors()

**功能**: 获取明日的五行配色

**参数**: 无

**返回值**: Array[3] - 明日的时针、分针、秒针颜色数组

**使用示例**:
```monkey-c
// 获取明日配色
var tomorrowColors = getTomorrowFiveElementColors();
var tomorrowHourColor = tomorrowColors[0];   // 明日时针颜色
var tomorrowMinuteColor = tomorrowColors[1]; // 明日分针颜色
var tomorrowSecondColor = tomorrowColors[2]; // 明日秒针颜色
```

### 3. getFiveElementColorsByOffset(dayOffset)

**功能**: 获取指定日期偏移的五行配色

**参数**:
- `dayOffset`: Number - 日期偏移量
  - 0 = 今天
  - 1 = 明天
  - -1 = 昨天
  - 2 = 后天
  - -2 = 前天
  - 以此类推...

**返回值**: Array[3] - 指定日期的时针、分针、秒针颜色数组

**使用示例**:
```monkey-c
// 获取各种日期的配色
var todayColors = getFiveElementColorsByOffset(0);     // 今天
var tomorrowColors = getFiveElementColorsByOffset(1);  // 明天
var yesterdayColors = getFiveElementColorsByOffset(-1); // 昨天
var dayAfterTomorrowColors = getFiveElementColorsByOffset(2); // 后天

// 获取一周后的配色
var nextWeekColors = getFiveElementColorsByOffset(7);
```

## 五行颜色映射

| 五行元素 | 索引 | 颜色值 | 颜色名称 | 寓意 |
|---------|------|--------|----------|------|
| 木 | 0 | 0x00FF00 | 绿色 | 生机勃勃，充满活力 |
| 火 | 1 | 0xFF0000 | 红色 | 热情奔放，能量充沛 |
| 土 | 2 | 0xFFFF00 | 黄色 | 稳重踏实，平衡发展 |
| 金 | 3 | 0xFFFFFF | 白色 | 清晰明亮，专注思考 |
| 水 | 4 | 0x000000 | 黑色 | 深邃宁静，内心平和 |

## 配色分配策略

基于五行相生相克理论：

- **时针（大吉色）**: 日五行所生的五行颜色，最为吉利
- **分针（次吉色）**: 日五行本身的颜色，次之吉利
- **秒针（平平色）**: 克制日五行的颜色，平平无奇

## 实际应用场景

### 1. 明日预览功能
```monkey-c
// 在设置页面显示明日配色预览
function showTomorrowPreview() {
    var tomorrowColors = getTomorrowFiveElementColors();
    
    // 绘制明日配色预览
    dc.setColor(tomorrowColors[0], Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, Graphics.FONT_SMALL, "明日时针", Graphics.TEXT_JUSTIFY_CENTER);
    
    dc.setColor(tomorrowColors[1], Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y + 20, Graphics.FONT_SMALL, "明日分针", Graphics.TEXT_JUSTIFY_CENTER);
    
    dc.setColor(tomorrowColors[2], Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y + 40, Graphics.FONT_SMALL, "明日秒针", Graphics.TEXT_JUSTIFY_CENTER);
}
```

### 2. 一周配色日历
```monkey-c
// 显示一周的配色预览
function showWeeklyColors() {
    var weekDays = ["今", "明", "后", "大", "四", "五", "六"];
    
    for (var i = 0; i < 7; i++) {
        var dayColors = getFiveElementColorsByOffset(i);
        
        // 绘制每日的主色调（时针颜色）
        dc.setColor(dayColors[0], Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(startX + i * spacing, centerY, radius);
        
        // 绘制日期标签
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + i * spacing, centerY + radius + 5, 
                   Graphics.FONT_TINY, weekDays[i], Graphics.TEXT_JUSTIFY_CENTER);
    }
}
```

### 3. 特殊日期配色查询
```monkey-c
// 查询生日当天的配色
function getBirthdayColors(birthdayMoment) {
    var birthdayInfo = Gregorian.info(birthdayMoment, Time.FORMAT_MEDIUM);
    return calculateDailyFiveElementColors(birthdayInfo);
}

// 查询节日配色
function getHolidayColors(holidayMoment) {
    var holidayInfo = Gregorian.info(holidayMoment, Time.FORMAT_MEDIUM);
    return calculateDailyFiveElementColors(holidayInfo);
}
```

## 优化亮点

### 1. 向后兼容
- 原有的调用方式完全不变
- 传入null参数即可获取当前日期配色

### 2. 灵活扩展
- 支持任意日期的配色计算
- 为未来功能提供强大基础

### 3. 错误处理
- 完善的异常处理机制
- 出错时自动回退到安全配色

### 4. 性能优化
- 算法高效，计算复杂度低
- 支持批量日期计算

## 未来扩展建议

1. **配色缓存**: 缓存近期计算的配色结果，提高性能
2. **节气适配**: 结合二十四节气调整配色强度
3. **个人定制**: 允许用户自定义五行颜色映射
4. **配色动画**: 在日期切换时添加平滑的颜色过渡动画
5. **配色统计**: 统计用户最喜欢的配色组合

## 注意事项

1. **时区处理**: 确保日期计算考虑用户所在时区
2. **边界情况**: 处理月末、年末的日期偏移
3. **内存管理**: 避免创建过多的临时对象
4. **用户体验**: 配色变化应该平滑自然，不突兀

---

通过这次优化，五行配色系统变得更加灵活和强大，为未来的功能扩展奠定了坚实的基础！