import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

/**
 * 五行配色表盘设置委托类
 * 处理设置界面的用户交互
 */
class FiveElementSettingsDelegate extends WatchUi.BehaviorDelegate {

    private var _view as FiveElementSettingsView?;

    /**
     * 初始化设置委托
     */
    function initialize() {
        BehaviorDelegate.initialize();
    }

    /**
     * 设置关联的视图
     * @param view 设置视图
     */
    function setView(view as FiveElementSettingsView) as Void {
        _view = view;
    }

    /**
     * 处理按键事件
     * @param keyEvent 按键事件
     * @return 是否处理了事件
     */
    function onKey(keyEvent as KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        
        if (keyEvent.getType() == WatchUi.PRESS_TYPE_ACTION) {
            switch (key) {
                case WatchUi.KEY_UP:
                    // 向上移动选择
                    if (_view != null) {
                        _view.moveUp();
                    }
                    return true;
                    
                case WatchUi.KEY_DOWN:
                    // 向下移动选择
                    if (_view != null) {
                        _view.moveDown();
                    }
                    return true;
                    
                case WatchUi.KEY_ENTER:
                case WatchUi.KEY_START:
                    // 确认选择
                    if (_view != null) {
                        _view.executeSelected();
                        
                        // 触觉反馈
                        if (Attention has :vibrate) {
                            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
                        }
                    }
                    return true;
                    
                case WatchUi.KEY_ESC:
                case WatchUi.KEY_LAP:
                    // 退出设置
                    WatchUi.popView(WatchUi.SLIDE_DOWN);
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
        var y = coordinates[1];
        
        var deviceSettings = System.getDeviceSettings();
        var height = deviceSettings.screenHeight;
        
        // 计算点击的菜单项
        var startY = 60;
        var itemHeight = 30;
        var maxItems = 6;
        
        for (var i = 0; i < maxItems; i++) {
            var itemY = startY + (i * itemHeight);
            if (y >= itemY && y <= itemY + itemHeight) {
                // 点击了菜单项
                if (_view != null) {
                    // 如果点击的是当前选中项，执行操作
                    if (i == _view.getSelectedIndex()) {
                        _view.executeSelected();
                        
                        // 触觉反馈
                        if (Attention has :vibrate) {
                            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
                        }
                    } else {
                        // 否则移动选择到该项
                        while (_view.getSelectedIndex() != i) {
                            if (_view.getSelectedIndex() < i) {
                                _view.moveDown();
                            } else {
                                _view.moveUp();
                            }
                        }
                    }
                }
                return true;
            }
        }
        
        // 检查是否点击了底部区域（退出）
        if (y > height - 50) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
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
            case WatchUi.SWIPE_UP:
                // 向上滑动 - 向上移动选择
                if (_view != null) {
                    _view.moveUp();
                }
                return true;
                
            case WatchUi.SWIPE_DOWN:
                // 向下滑动 - 向下移动选择或退出
                if (_view != null) {
                    if (_view.getSelectedIndex() == 5) { // 最后一项时退出
                        WatchUi.popView(WatchUi.SLIDE_DOWN);
                    } else {
                        _view.moveDown();
                    }
                }
                return true;
                
            case WatchUi.SWIPE_LEFT:
                // 向左滑动 - 执行当前选择
                if (_view != null) {
                    _view.executeSelected();
                    
                    // 触觉反馈
                    if (Attention has :vibrate) {
                        Attention.vibrate([new Attention.VibeProfile(50, 100)]);
                    }
                }
                return true;
                
            case WatchUi.SWIPE_RIGHT:
                // 向右滑动 - 退出设置
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
        }
        
        return false;
    }

    /**
     * 处理返回事件
     * @return 是否处理了事件
     */
    function onBack() as Lang.Boolean {
        // 退出设置界面
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    /**
     * 处理菜单事件
     * @return 是否处理了事件
     */
    function onMenu() as Lang.Boolean {
        // 在设置界面中，菜单键也用于退出
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    /**
     * 处理选择事件
     * @return 是否处理了事件
     */
    function onSelect() as Lang.Boolean {
        // 执行当前选择的设置项
        if (_view != null) {
            _view.executeSelected();
            
            // 触觉反馈
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(50, 100)]);
            }
        }
        return true;
    }

    /**
     * 处理下一页事件
     * @return 是否处理了事件
     */
    function onNextPage() as Lang.Boolean {
        // 向下移动选择
        if (_view != null) {
            _view.moveDown();
        }
        return true;
    }

    /**
     * 处理上一页事件
     * @return 是否处理了事件
     */
    function onPreviousPage() as Lang.Boolean {
        // 向上移动选择
        if (_view != null) {
            _view.moveUp();
        }
        return true;
    }
}