import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Application.Storage;

/**
 * 五行配色表盘设置视图
 * 提供配色、数据显示等配置选项
 */
class FiveElementSettingsView extends WatchUi.View {

    // 菜单常量
    const MAX_ITEMS = 6;
    const MENU_ITEM_HEIGHT = 40;
    const MENU_START_Y = 60;
    const MENU_MARGIN_X = 20;
    
    // 选择器常量
    const SELECTOR_WIDTH = 4;
    const SELECTOR_MARGIN = 10;
    
    // 颜色常量
    const SELECTED_COLOR = Graphics.COLOR_WHITE;
    const NORMAL_COLOR = Graphics.COLOR_LT_GRAY;
    const BACKGROUND_COLOR = Graphics.COLOR_BLACK;
    
    private var _selectedIndex as Lang.Number = 0;
    private var _menuItems as Array<String>;
    // 最大项目数
    private var _maxItems as Lang.Number = MAX_ITEMS;

    /**
     * 初始化设置视图
     */
    function initialize() {
        View.initialize();
        
        _menuItems = [
            "五行配色",
            "数据显示",
            "亮度调节",
            "颜色主题",
            "显示选项",
            "恢复默认"
        ];
    }

    /**
     * 加载资源
     * @param dc 绘图上下文
     */
    function onLayout(dc as Graphics.Dc) as Void {
        // 设置布局
    }

    /**
     * 绘制设置界面
     * @param dc 绘图上下文
     */
    function onUpdate(dc as Graphics.Dc) as Void {
        // 清除屏幕
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var deviceSettings = System.getDeviceSettings();
        var width = deviceSettings.screenWidth;
        var height = deviceSettings.screenHeight;
        
        // 绘制标题
        _drawTitle(dc, width, height);
        
        // 绘制菜单项
        _drawMenuItems(dc, width, height);
        
        // 绘制选择指示器
        _drawSelector(dc, width, height);
        
        // 绘制底部提示
        _drawInstructions(dc, width, height);
    }

    /**
     * 绘制标题
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawTitle(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            20,
            Graphics.FONT_SMALL,
            "表盘设置",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // 绘制分隔线
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(20, 45, width - 20, 45);
    }

    /**
     * 绘制菜单项
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawMenuItems(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        var startY = 60;
        var itemHeight = 30;
        
        for (var i = 0; i < _menuItems.size(); i++) {
            var y = startY + (i * itemHeight);
            
            // 设置颜色
            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            
            // 绘制菜单项文本
            dc.drawText(
                30,
                y,
                Graphics.FONT_SMALL,
                _menuItems[i],
                Graphics.TEXT_JUSTIFY_LEFT
            );
            
            // 绘制当前值
            _drawCurrentValue(dc, i, width - 30, y);
        }
    }

    /**
     * 绘制当前设置值
     * @param dc 绘图上下文
     * @param index 菜单项索引
     * @param x X坐标
     * @param y Y坐标
     */
    private function _drawCurrentValue(dc as Graphics.Dc, index as Lang.Number, x as Lang.Number, y as Lang.Number) as Void {
        var value = "";
        
        switch (index) {
            case 0: // 五行配色
                var elementIndex = Storage.getValue("elementIndex");
                if (elementIndex == null) { elementIndex = 0; }
                var elements = ["木", "火", "土", "金", "水"];
                value = elements[elementIndex];
                break;
                
            case 1: // 数据显示
                var displayMode = Storage.getValue("dataDisplayMode");
                if (displayMode == null) { displayMode = 0; }
                var modes = ["标准", "简洁", "详细"];
                value = modes[displayMode];
                break;
                
            case 2: // 亮度调节
                var brightness = Storage.getValue("brightness");
                if (brightness == null) { brightness = 50; }
                value = brightness.toString() + "%";
                break;
                
            case 3: // 颜色主题
                var theme = Storage.getValue("colorTheme");
                if (theme == null) { theme = 0; }
                var themes = ["经典", "现代", "简约"];
                value = themes[theme];
                break;
                
            case 4: // 显示选项
                var showExtended = Storage.getValue("showExtended");
                value = (showExtended == true) ? "开启" : "关闭";
                break;
                
            case 5: // 恢复默认
                value = "执行";
                break;
        }
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            value,
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    /**
     * 绘制选择指示器
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawSelector(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        var startY = 60;
        var itemHeight = 30;
        var y = startY + (_selectedIndex * itemHeight) + 10;
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [15, y - 5],
            [15, y + 5],
            [25, y]
        ]);
    }

    /**
     * 绘制底部操作提示
     * @param dc 绘图上下文
     * @param width 屏幕宽度
     * @param height 屏幕高度
     */
    private function _drawInstructions(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(20, height - 50, width - 20, height - 50);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height - 40,
            Graphics.FONT_XTINY,
            "上下选择 确认修改 返回退出",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    /**
     * 向上移动选择
     */
    function moveUp() as Void {
        _selectedIndex = (_selectedIndex - 1 + _maxItems) % _maxItems;
        WatchUi.requestUpdate();
    }

    /**
     * 向下移动选择
     */
    function moveDown() as Void {
        _selectedIndex = (_selectedIndex + 1) % _maxItems;
        WatchUi.requestUpdate();
    }

    /**
     * 获取当前选择的索引
     * @return 选择索引
     */
    function getSelectedIndex() as Lang.Number {
        return _selectedIndex;
    }

    /**
     * 执行当前选择的设置项
     */
    function executeSelected() as Void {
        switch (_selectedIndex) {
            case 0: // 五行配色
                _cycleFiveElementSetting();
                break;
                
            case 1: // 数据显示
                _cycleDataDisplaySetting();
                break;
                
            case 2: // 亮度调节
                _adjustBrightnessSetting();
                break;
                
            case 3: // 颜色主题
                _cycleColorThemeSetting();
                break;
                
            case 4: // 显示选项
                _toggleExtendedDisplay();
                break;
                
            case 5: // 恢复默认
                _resetToDefaults();
                break;
        }
        
        WatchUi.requestUpdate();
    }

    /**
     * 循环切换五行配色设置
     */
    private function _cycleFiveElementSetting() as Void {
        var currentIndex = Storage.getValue("elementIndex");
        if (currentIndex == null) { currentIndex = 0; }
        currentIndex = (currentIndex + 1) % 5;
        Storage.setValue("elementIndex", currentIndex);
    }

    /**
     * 循环切换数据显示模式
     */
    private function _cycleDataDisplaySetting() as Void {
        var displayMode = Storage.getValue("dataDisplayMode");
        if (displayMode == null) { displayMode = 0; }
        displayMode = (displayMode + 1) % 3;
        Storage.setValue("dataDisplayMode", displayMode);
    }

    /**
     * 调整亮度设置
     */
    private function _adjustBrightnessSetting() as Void {
        var brightness = Storage.getValue("brightness");
        if (brightness == null) { brightness = 50; }
        brightness = (brightness + 10) % 110;
        if (brightness < 10) { brightness = 10; }
        Storage.setValue("brightness", brightness);
    }

    /**
     * 循环切换颜色主题
     */
    private function _cycleColorThemeSetting() as Void {
        var theme = Storage.getValue("colorTheme");
        if (theme == null) { theme = 0; }
        theme = (theme + 1) % 3;
        Storage.setValue("colorTheme", theme);
    }

    /**
     * 切换扩展显示
     */
    private function _toggleExtendedDisplay() as Void {
        var showExtended = Storage.getValue("showExtended");
        Storage.setValue("showExtended", !showExtended);
    }

    /**
     * 恢复默认设置
     */
    private function _resetToDefaults() as Void {
        Storage.setValue("elementIndex", 0);
        Storage.setValue("dataDisplayMode", 0);
        Storage.setValue("brightness", 50);
        Storage.setValue("colorTheme", 0);
        Storage.setValue("showExtended", false);
    }
}