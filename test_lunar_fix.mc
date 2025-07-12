// 测试修复后的农历算法
// 验证2025年7月11日是否正确计算为农历六月十七

using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

/**
 * 修正的儒略日计算函数
 */
function getJulianDay(year as Number, month as Number, day as Number) as Number {
    var a = (14 - month) / 12;
    var y = year - a;
    var m = month + 12 * a - 3;
    
    // 修正的儒略日公式，调整常数项以匹配万年历
    var jd = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 + 1721120;
    
    return jd;
}

/**
 * 获取农历某月的天数
 */
function getLunarMonthDays(year as Number, month as Number, lunarYearData as Array) as Number {
    if (year < 1900 || year > 2100 || month < 1 || month > 12) {
        return 29;
    }
    
    var yearIndex = year - 1900;
    if (yearIndex >= lunarYearData.size()) {
        return 29;
    }
    
    var yearData = lunarYearData[yearIndex];
    var bitPosition = 17 - month;
    var mask = 1 << (bitPosition - 1);
    return ((yearData & mask) != 0) ? 30 : 29;
}

/**
 * 获取农历年的闰月月份
 */
function getLeapMonth(year as Number, lunarYearData as Array) as Number {
    if (year < 1900 || year > 2100) {
        return 0;
    }
    
    var yearIndex = year - 1900;
    if (yearIndex >= lunarYearData.size()) {
        return 0;
    }
    
    var yearData = lunarYearData[yearIndex];
    return (yearData & 0xf);
}

/**
 * 计算农历年的总天数
 */
function getLunarYearDays(year as Number, lunarYearData as Array) as Number {
    if (year < 1900 || year > 2100) {
        return 354;
    }
    
    var yearIndex = year - 1900;
    if (yearIndex >= lunarYearData.size()) {
        return 354;
    }
    
    var yearData = lunarYearData[yearIndex];
    var totalDays = 0;
    
    // 计算12个普通月的天数
    for (var i = 1; i <= 12; i++) {
        var bitPosition = 17 - i;
        var mask = 1 << (bitPosition - 1);
        totalDays += ((yearData & mask) != 0) ? 30 : 29;
    }
    
    // 处理闰月
    var leapMonth = getLeapMonth(year, lunarYearData);
    if (leapMonth > 0) {
        totalDays += ((yearData & 0x10000) != 0) ? 30 : 29;
    }
    
    return totalDays;
}

/**
 * 测试农历计算
 */
function testLunarCalculation() {
    System.println("=== 测试修复后的农历算法 ===");
    
    // 2025年农历数据
    var lunarYearData = [
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
    
    // 测试2025年7月11日
    var year = 2025;
    var month = 7;
    var day = 11;
    
    System.println("测试日期: " + year + "年" + month + "月" + day + "日");
    
    // 计算儒略日
    var baseJulian = 2415020; // 修正基准儒略日
    var targetJulian = getJulianDay(year, month, day);
    var totalDays = targetJulian - baseJulian;
    
    System.println("基准儒略日: " + baseJulian);
    System.println("目标儒略日: " + targetJulian);
    System.println("相差天数: " + totalDays);
    
    // 逐年计算到2025年
    var lunarYear = 1900;
    var remainingDays = totalDays;
    
    while (lunarYear < 2025) {
        var yearDays = getLunarYearDays(lunarYear, lunarYearData);
        remainingDays -= yearDays;
        lunarYear++;
    }
    
    System.println("进入2025年，剩余天数: " + remainingDays);
    
    // 2025年逐月计算
    var lunarMonth = 1;
    var isLeapMonth = false;
    var leapMonth = getLeapMonth(2025, lunarYearData);
    
    System.println("2025年闰月: " + leapMonth);
    
    while (lunarMonth <= 12) {
        var currentMonthDays = getLunarMonthDays(2025, lunarMonth, lunarYearData);
        System.println("农历" + lunarMonth + "月天数: " + currentMonthDays + ", 剩余天数: " + remainingDays);
        
        // 检查是否在当前正常月份中
        if (remainingDays < currentMonthDays) {
            isLeapMonth = false;
            System.println("结果: 农历" + lunarMonth + "月" + (remainingDays + 1) + "日 (正常月)");
            break;
        }
        
        remainingDays -= currentMonthDays;
        
        // 处理闰月
        if (lunarMonth == leapMonth && leapMonth > 0) {
            var yearIndex = 2025 - 1900;
            var leapMonthDays = ((lunarYearData[yearIndex] & 0x10000) != 0) ? 30 : 29;
            System.println("闰" + lunarMonth + "月天数: " + leapMonthDays + ", 剩余天数: " + remainingDays);
            
            if (remainingDays < leapMonthDays) {
                isLeapMonth = true;
                System.println("结果: 闰" + lunarMonth + "月" + (remainingDays + 1) + "日 (闰月)");
                break;
            }
            
            remainingDays -= leapMonthDays;
        }
        
        lunarMonth++;
    }
    
    System.println("=== 测试完成 ===");
}

// 运行测试
testLunarCalculation();