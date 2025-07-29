import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

/**
 * 设备适配器 - 专门为FR255设备提供独立的适配支持
 * 与FR965设备完全隔离，确保互不影响
 */
class DeviceAdapter {
    
    // 设备规格定义
    private var deviceSpecs as Dictionary = {
        "fr965" => {
            "screenWidth" => 454,
            "screenHeight" => 454,
            "isAMOLED" => true,
            "isSmallScreen" => false,
            "scaleRatio" => 1.0,
            "fontScale" => 1.0,
            "handLengthRatio" => {
                "hour" => 0.5,
                "minute" => 0.7,
                "second" => 0.85
            }
        },
        "fr255" => {
            "screenWidth" => 260,
            "screenHeight" => 260,
            "isAMOLED" => false,
            "isSmallScreen" => true,
            "scaleRatio" => 1.0,
            "fontScale" => 0.8,
            "handLengthRatio" => {
                "hour" => 0.45,
                "minute" => 0.65,
                "second" => 0.8
            }
        }
    };
    
    // 私有变量
    private var screenWidth as Number = 454;
    private var screenHeight as Number = 454;
    private var currentDeviceId as String = "fr965";
    private var currentSpecs as Dictionary or Null = null;
    private var scaleRatio as Float = 1.0;
    
    /**
     * 构造函数
     */
    function initialize() {
        // 默认构造函数
    }
    
    /**
     * 设置适配器参数
     * @param sW 屏幕宽度
     * @param sH 屏幕高度
     */
    public function setup(sW as Number, sH as Number) as Void {
        screenWidth = sW;
        screenHeight = sH;
        currentDeviceId = getCurrentDeviceId();
        currentSpecs = getDeviceSpecs(currentDeviceId);
        scaleRatio = calculateScaleRatio();
    }
    
    /**
     * 获取当前设备ID
     * @return 设备ID字符串
     */
    private function getCurrentDeviceId() as String {
        // 基于屏幕尺寸判断设备类型
        if (screenWidth == 260 && screenHeight == 260) {
            return "fr255";
        } else if (screenWidth == 454 && screenHeight == 454) {
            return "fr965";
        } else {
            // 默认返回FR965
            return "fr965";
        }
    }
    
    /**
     * 获取设备规格
     * @param deviceId 设备ID
     * @return 设备规格字典
     */
    private function getDeviceSpecs(deviceId as String) as Dictionary {
        if (deviceSpecs.hasKey(deviceId)) {
            return deviceSpecs[deviceId];
        } else {
            return deviceSpecs["fr965"]; // 默认规格
        }
    }
    
    /**
     * 计算缩放比例
     * @return 缩放比例
     */
    private function calculateScaleRatio() as Float {
        if (currentSpecs != null && currentSpecs.hasKey("scaleRatio")) {
            var ratio = currentSpecs["scaleRatio"];
            if (ratio instanceof Float) {
                return ratio;
            } else if (ratio instanceof Number) {
                return ratio.toFloat();
            }
        }
        return 1.0;
    }
    
    /**
     * 获取缩放比例
     * @return 缩放比例
     */
    public function getScaleRatio() as Float {
        return scaleRatio;
    }
    
    /**
     * 获取设备ID
     * @return 设备ID
     */
    public function getDeviceId() as String {
        return currentDeviceId;
    }
    
    /**
     * 获取设备规格
     * @return 设备规格字典
     */
    public function getSpecs() as Dictionary or Null {
        return currentSpecs;
    }
    
    /**
     * 是否为小屏幕设备
     * @return 是否为小屏幕
     */
    public function isSmallScreen() as Boolean {
        if (currentSpecs != null && currentSpecs.hasKey("isSmallScreen")) {
            return currentSpecs["isSmallScreen"];
        }
        return false;
    }
    
    /**
     * 是否为AMOLED屏幕
     * @return 是否为AMOLED
     */
    public function isAMOLED() as Boolean {
        if (currentSpecs != null && currentSpecs.hasKey("isAMOLED")) {
            return currentSpecs["isAMOLED"];
        }
        return false;
    }
    
    /**
     * 缩放数值
     * @param value 原始数值
     * @return 缩放后的数值
     */
    public function scaleValue(value as Number) as Number {
        return (value * scaleRatio).toNumber();
    }
    
    /**
     * 缩放浮点数
     * @param value 原始浮点数
     * @return 缩放后的浮点数
     */
    public function scaleFloat(value as Float) as Float {
        return value * scaleRatio;
    }
    
    /**
     * 获取适配的字体
     * @param baseFont 基础字体
     * @return 适配后的字体
     */
    public function getAdaptedFont(baseFont as Graphics.FontType) as Graphics.FontType {
        if (currentDeviceId.equals("fr255")) {
            // FR255专用字体适配
            switch (baseFont) {
                case Graphics.FONT_LARGE:
                    return Graphics.FONT_MEDIUM;
                case Graphics.FONT_MEDIUM:
                    return Graphics.FONT_SMALL;
                case Graphics.FONT_SMALL:
                    return Graphics.FONT_TINY;
                case Graphics.FONT_TINY:
                    return Graphics.FONT_XTINY;
                default:
                    return Graphics.FONT_SMALL;
            }
        } else {
            // FR965使用原始字体
            return baseFont;
        }
    }
    
    /**
     * 获取适配的线宽
     * @param baseWidth 基础线宽
     * @return 适配后的线宽
     */
    public function getAdaptedLineWidth(baseWidth as Number) as Number {
        if (currentDeviceId.equals("fr255")) {
            // FR255使用更细的线条
            return (baseWidth * 0.7).toNumber();
        } else {
            return baseWidth;
        }
    }
    
    /**
     * 获取指针长度比例
     * @param handType 指针类型
     * @return 长度比例
     */
    public function getHandLengthRatio(handType as String) as Float {
        if (currentSpecs != null && currentSpecs.hasKey("handLengthRatio")) {
            var ratios = currentSpecs["handLengthRatio"];
            if (ratios.hasKey(handType)) {
                var ratio = ratios[handType];
                if (ratio instanceof Float) {
                    return ratio;
                } else if (ratio instanceof Number) {
                    return ratio.toFloat();
                }
            }
        }
        // 默认比例
        switch (handType) {
            case "hour":
                return 0.5;
            case "minute":
                return 0.7;
            case "second":
                return 0.85;
            default:
                return 0.7;
        }
    }
    
    /**
     * 获取适配的偏移量
     * @param baseOffset 基础偏移量
     * @return 适配后的偏移量
     */
    public function getAdaptedOffset(baseOffset as Number) as Number {
        return scaleValue(baseOffset);
    }
    
    /**
     * 获取时间位置偏移
     * @return Y轴偏移量
     */
    public function getTimePositionOffset() as Number {
        if (currentDeviceId.equals("fr255")) {
            return -75; // FR255专用时间位置
        } else {
            return -130; // FR965原始位置
        }
    }
    
    /**
     * 获取日期位置偏移
     * @return Y轴偏移量
     */
    public function getDatePositionOffset() as Number {
        if (currentDeviceId.equals("fr255")) {
            return -50; // FR255专用日期位置
        } else {
            return -100; // FR965原始位置
        }
    }
}