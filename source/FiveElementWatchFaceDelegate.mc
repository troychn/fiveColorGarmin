import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Storage;

/**
 * 五行配色表盘输入委托类
 * 处理用户交互和按键事件
 */
class FiveElementWatchFaceDelegate extends WatchUi.WatchFaceDelegate {

    /**
     * 初始化输入委托
     */
    function initialize() {
        WatchFaceDelegate.initialize();
    }

    /**
     * 处理按键按下事件
     * @param keyEvent 按键事件
     * @return 是否处理了事件
     */
    function onKey(keyEvent as KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        
        if (keyEvent.getType() == WatchUi.PRESS_TYPE_ACTION) {
            switch (key) {
                case WatchUi.KEY_ENTER:
                case WatchUi.KEY_START:
                    // 切换五行配色
                    _cycleFiveElementColor();
                    WatchUi.requestUpdate();
                    return true;
                    
                case WatchUi.KEY_UP:
                    // 增加亮度或其他功能
                    _adjustBrightness(true);
                    return true;
                    
                case WatchUi.KEY_DOWN:
                    // 减少亮度或其他功能
                    _adjustBrightness(false);
                    return true;
                    
                case WatchUi.KEY_ESC:
                case WatchUi.KEY_LAP:
                    // 重置配色或返回默认
                    _resetToDefaultColor();
                    WatchUi.requestUpdate();
                    return true;
            }
        }
        
        return false;
    }

    /**
     * 处理触摸事件
     * @param touchEvent 触摸事件
     * @return 是否处理了事件
     */
    function onTap(touchEvent as ClickEvent) as Lang.Boolean {
        var coordinates = touchEvent.getCoordinates();
        var x = coordinates[0];
        var y = coordinates[1];
        
        var deviceSettings = System.getDeviceSettings();
        var centerX = deviceSettings.screenWidth / 2;
        var centerY = deviceSettings.screenHeight / 2;
        
        // 检测点击区域
        if (_isInFiveElementArea(x, y)) {
            // 点击五行配色区域
            _cycleFiveElementColor();
            WatchUi.requestUpdate();
            return true;
        } else if (_isInCenterArea(x, y, centerX, centerY)) {
            // 点击中心区域
            _showDetailedInfo();
            return true;
        } else if (_isInDataArea(x, y)) {
            // 点击数据区域
            _cycleDataDisplay();
            WatchUi.requestUpdate();
            return true;
        }
        
        return false;
    }

    /**
     * 处理滑动事件
     * @param swipeEvent 滑动事件
     * @return 是否处理了事件
     */
    function onSwipe(swipeEvent as SwipeEvent) as Lang.Boolean {
        var direction = swipeEvent.getDirection();
        
        switch (direction) {
            case WatchUi.SWIPE_LEFT:
                // 向左滑动 - 下一个配色方案
                _cycleFiveElementColor();
                WatchUi.requestUpdate();
                return true;
                
            case WatchUi.SWIPE_RIGHT:
                // 向右滑动 - 上一个配色方案
                _cycleFiveElementColorReverse();
                WatchUi.requestUpdate();
                return true;
                
            case WatchUi.SWIPE_UP:
                // 向上滑动 - 显示更多信息
                _showExtendedInfo();
                return true;
                
            case WatchUi.SWIPE_DOWN:
                // 向下滑动 - 隐藏信息
                _hideExtendedInfo();
                return true;
        }
        
        return false;
    }

    /**
     * 处理菜单事件
     * @return 是否处理了事件
     */
    function onMenu() as Lang.Boolean {
        // 打开设置菜单
        WatchUi.pushView(
            new FiveElementSettingsView(),
            new FiveElementSettingsDelegate(),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    /**
     * 检测是否点击在五行配色区域
     * @param x X坐标
     * @param y Y坐标
     * @return 是否在区域内
     */
    private function _isInFiveElementArea(x as Lang.Number, y as Lang.Number) as Lang.Boolean {
        // 五行配色区域大约在顶部
        return y >= 25 && y <= 75;
    }

    /**
     * 检测是否点击在中心区域
     * @param x X坐标
     * @param y Y坐标
     * @param centerX 中心X坐标
     * @param centerY 中心Y坐标
     * @return 是否在区域内
     */
    private function _isInCenterArea(x as Lang.Number, y as Lang.Number, centerX as Lang.Number, centerY as Lang.Number) as Lang.Boolean {
        var distance = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
        return distance <= 50; // 中心50像素半径内
    }

    /**
     * 检测是否点击在数据显示区域
     * @param x X坐标
     * @param y Y坐标
     * @return 是否在区域内
     */
    private function _isInDataArea(x as Lang.Number, y as Lang.Number) as Lang.Boolean {
        // 数据区域在左右两侧
        return (x <= 120 || x >= 160) && y >= 160 && y <= 280;
    }

    /**
     * 循环切换五行配色
     */
    private function _cycleFiveElementColor() as Void {
        var currentIndex = Storage.getValue("elementIndex");
        if (currentIndex == null) {
            currentIndex = 0;
        }
        
        currentIndex = (currentIndex + 1) % 5;
        Storage.setValue("elementIndex", currentIndex);
        
        // 触觉反馈
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }

    /**
     * 反向循环切换五行配色
     */
    private function _cycleFiveElementColorReverse() as Void {
        var currentIndex = Storage.getValue("elementIndex");
        if (currentIndex == null) {
            currentIndex = 0;
        }
        
        currentIndex = (currentIndex - 1 + 5) % 5;
        Storage.setValue("elementIndex", currentIndex);
        
        // 触觉反馈
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }

    /**
     * 重置为默认配色
     */
    private function _resetToDefaultColor() as Void {
        Storage.setValue("elementIndex", 0);
        
        // 触觉反馈
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 200)]);
        }
    }

    /**
     * 调整亮度
     * @param increase 是否增加亮度
     */
    private function _adjustBrightness(increase as Lang.Boolean) as Void {
        var currentBrightness = Storage.getValue("brightness");
        if (currentBrightness == null) {
            currentBrightness = 50;
        }
        
        if (increase && currentBrightness < 100) {
            currentBrightness += 10;
        } else if (!increase && currentBrightness > 10) {
            currentBrightness -= 10;
        }
        
        Storage.setValue("brightness", currentBrightness);
    }

    /**
     * 显示详细信息
     */
    private function _showDetailedInfo() as Void {
        // 可以推送一个详细信息视图
        WatchUi.pushView(
            new FiveElementDetailView(),
            new FiveElementDetailDelegate(),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    /**
     * 循环切换数据显示
     */
    private function _cycleDataDisplay() as Void {
        var displayMode = Storage.getValue("dataDisplayMode");
        if (displayMode == null) {
            displayMode = 0;
        }
        
        displayMode = (displayMode + 1) % 3; // 假设有3种显示模式
        Storage.setValue("dataDisplayMode", displayMode);
    }

    /**
     * 显示扩展信息
     */
    private function _showExtendedInfo() as Void {
        Storage.setValue("showExtended", true);
        WatchUi.requestUpdate();
    }

    /**
     * 隐藏扩展信息
     */
    private function _hideExtendedInfo() as Void {
        Storage.setValue("showExtended", false);
        WatchUi.requestUpdate();
    }
}