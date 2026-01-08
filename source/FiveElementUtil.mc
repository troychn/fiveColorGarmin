import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;

/**
 * 五行算法工具类
 * 集中管理五行计算逻辑，避免代码重复
 */
class FiveElementUtil {

    // 纳音五行表 (0:木, 1:火, 2:土, 3:金, 4:水)
    // 对应甲子乙丑金(3), 丙寅丁卯火(1)...
    // 这是一个静态常量数组，覆盖60甲子
    // 注：纳音五行用于八字推算，不用于五行穿衣指南
    static const NA_YIN_ELEMENTS = [
        3, 3, 1, 1, 0, 0, 2, 2, 3, 3, // 0-9
        1, 1, 4, 4, 2, 2, 3, 3, 0, 0, // 10-19
        4, 4, 2, 2, 1, 1, 0, 0, 4, 4, // 20-29
        3, 3, 1, 1, 0, 0, 2, 2, 3, 3, // 30-39
        1, 1, 4, 4, 2, 2, 3, 3, 0, 0, // 40-49
        4, 4, 2, 2, 1, 1, 0, 0, 4, 4  // 50-59
    ];

    // 地支五行表 (0:木, 1:火, 2:土, 3:金, 4:水)
    // 五行穿衣指南根据地支五行确定日五行
    // 地支五行: 子(0)-木, 丑(1)-土, 寅(2)-木, 卯(3)-火, 辰(4)-土, 巳(5)-火
    //           午(6)-火, 未(7)-土, 申(8)-金, 酉(9)-金, 戌(10)-土, 亥(11)-木
    // 60甲子地支每12个一循环，每循环对应的地支五行为: 0,2,0,1,2,1,1,2,3,3,2,0
    static const ZHI_ELEMENTS = [
        0, 2, 0, 1, 2, 1, 1, 2, 3, 3, 2, 0,  // 0-11
        0, 2, 0, 1, 2, 1, 1, 2, 3, 3, 2, 0,  // 12-23
        0, 2, 0, 1, 2, 1, 1, 2, 3, 3, 2, 0,  // 24-35
        0, 2, 0, 1, 2, 1, 1, 2, 3, 3, 2, 0,  // 36-47
        0, 2, 0, 1, 2, 1, 1, 2, 3, 3, 2, 0   // 48-59
    ];

    // 五行颜色映射
    static const ELEMENT_COLOR_MAP = [
        0x00FF00,  // 木 - 绿色
        0xFF0000,  // 火 - 红色
        0xFFFF00,  // 土 - 黄色
        0xFFFFFF,  // 金 - 白色
        0x000000   // 水 - 纯黑色
    ];

    /**
     * 计算指定日期的五行配色
     * @param dateInfo Gregorian.Info 对象 (包含 year, month, day)
     * @return [大吉色, 次吉色, 平平色, 日五行索引]
     */
    static function calculateColors(dateInfo) as Array<Number> {
        try {
            if (dateInfo == null) {
                dateInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            }

            var year = dateInfo.year;
            var month = dateInfo.month;
            var day = dateInfo.day;
            
            // 安全转换为数字类型
            var yearNum = year;
            var monthNum = month; // 假设传入的已经是数字，如果不是需转换，但在MonkeyC中Gregorian.info返回的通常是数字或根据上下文
            // 注意：Gregorian.info 返回的 month 可能是 Number
            
            // 如果 month 是对象或字符串，需要转换 (为了兼容旧代码逻辑，这里保留防御性转换)
            if (!(monthNum instanceof Number)) {
                 // 简单的映射或假设
                 monthNum = 1; 
            }
            
            var jd = getJulianDay(yearNum, monthNum, day);
            
            // 修正值 +49 是基于 2026-01-03 (丁丑, JD 2461044) 推算得出的
            // JD 2461044 % 60 = 24
            // 丁丑 = 13
            // (24 + 49) % 60 = 73 % 60 = 13
            var ganZhiIndex = (jd + 49) % 60;
            if (ganZhiIndex < 0) {
                ganZhiIndex += 60;
            }
            
            // 使用地支五行作为日五行（五行穿衣指南使用地支五行，而非纳音五行）
            var dayElement = ZHI_ELEMENTS[ganZhiIndex];

            // 根据五行相生相克理论计算配色
            // 大吉：被日五行生（日生我）。
            // 次吉：与日五行相同。
            // 平平：克制日五行的颜色（这个颜色主动克制日五行）。
            // 五行相克：木克土、土克水、水克火、火克金、金克木
            // "克日五行"理解：克制日五行的颜色（木克土，所以木色克制土日）
            var mostLucky = (dayElement + 1) % 5;        // 大吉：被日生
            var secondLucky = dayElement;                // 次吉：同日五行
            var normalLucky = 0;                        // 平平：克日五行
            if (dayElement == 0) { normalLucky = 3; }   // 木日：克木者金 → 金
            else if (dayElement == 1) { normalLucky = 4; } // 火日：克火者水 → 水
            else if (dayElement == 2) { normalLucky = 0; } // 土日：克土者木 → 木
            else if (dayElement == 3) { normalLucky = 1; } // 金日：克金者火 → 火
            else if (dayElement == 4) { normalLucky = 2; } // 水日：克水者土 → 土
            
            return [
                ELEMENT_COLOR_MAP[mostLucky],    // 时针颜色（大吉）
                ELEMENT_COLOR_MAP[secondLucky],  // 分针颜色（次吉）
                ELEMENT_COLOR_MAP[normalLucky],  // 秒针颜色（平平）
                dayElement                       // 日五行索引
            ];
            
        } catch (ex) {
            // 出错时返回默认配色 (土日配色: 红/绿/白)
            return [0xFF0000, 0x00FF00, 0xFFFFFF, 2];
        }
    }

    /**
     * 计算儒略日数
     */
    static function getJulianDay(year as Number, month as Number, day as Number) as Number {
        if (month <= 2) {
            month += 12;
            year -= 1;
        }
        
        var a = year / 100;
        var b = 2 - a + a / 4;
        
        var jd = (365.25 * (year + 4716)).toNumber() + (30.6001 * (month + 1)).toNumber() + day + b - 1524;
        
        return jd;
    }
}
