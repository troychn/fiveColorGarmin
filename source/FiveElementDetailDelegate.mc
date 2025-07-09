import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Storage;

/**
 * 五行配色表盘详细信息委托类
 * 处理详细信息视图的用户交互
 */
class FiveElementDetailDelegate extends WatchUi.BehaviorDelegate {

    private var _view as FiveElementDetailView?;

    /**
     * 初始化详细信息委托
     */
    function initialize() {
        BehaviorDelegate.initialize();
    }

    /**
     * 设置关联的视图
     * @param view 详细信息视图
     */
    function setView(view as FiveElementDetailView) as Void {
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
                    // 向上翻页或其他操作
                    if (_view != null) {
                        _view.previousPage();
                    }
                    return true;
                    
                case WatchUi.KEY_DOWN:
                    // 向下翻页或其他操作
                    if (_view != null) {
                        _view.nextPage();
                    }
                    return true;
                    
                case WatchUi.KEY_ENTER:
                case WatchUi.KEY_START:
                    // 确认或执行操作
                    if (_view != null) {
                        _performPageAction();
                    }
                    return true;
                    
                case WatchUi.KEY_ESC:
                case WatchUi.KEY_LAP:
                    // 退出详细视图
                    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
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
        var width = deviceSettings.screenWidth;
        var height = deviceSettings.screenHeight;
        
        // 检测点击区域
        if (_isInTopArea(y)) {
            // 点击顶部区域 - 页面指示器区域
            if (_view != null) {
                _view.nextPage();
            }
            return true;
        } else if (_isInBottomArea(y, height)) {
            // 点击底部区域 - 退出
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (_isInLeftArea(x, width)) {
            // 点击左侧区域 - 上一页
            if (_view != null) {
                _view.previousPage();
            }
            return true;
        } else if (_isInRightArea(x, width)) {
            // 点击右侧区域 - 下一页
            if (_view != null) {
                _view.nextPage();
            }
            return true;
        } else {
            // 点击中心区域 - 执行页面特定操作
            if (_view != null) {
                _performPageAction();
            }
            return true;
        }
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
                // 向左滑动 - 下一页
                if (_view != null) {
                    _view.nextPage();
                    
                    // 触觉反馈
                    if (Attention has :vibrate) {
                        Attention.vibrate([new Attention.VibeProfile(30, 50)]);
                    }
                }
                return true;
                
            case WatchUi.SWIPE_RIGHT:
                // 向右滑动 - 上一页
                if (_view != null) {
                    _view.previousPage();
                    
                    // 触觉反馈
                    if (Attention has :vibrate) {
                        Attention.vibrate([new Attention.VibeProfile(30, 50)]);
                    }
                }
                return true;
                
            case WatchUi.SWIPE_UP:
                // 向上滑动 - 上一页或特殊操作
                if (_view != null) {
                    _view.previousPage();
                }
                return true;
                
            case WatchUi.SWIPE_DOWN:
                // 向下滑动 - 下一页或退出
                if (_view != null) {
                    if (_view.getCurrentPage() == 2) { // 最后一页时退出
                        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                    } else {
                        _view.nextPage();
                    }
                }
                return true;
        }
        
        return false;
    }

    /**
     * 处理返回事件
     * @return 是否处理了事件
     */
    function onBack() as Lang.Boolean {
        // 退出详细信息界面
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    /**
     * 处理菜单事件
     * @return 是否处理了事件
     */
    function onMenu() as Lang.Boolean {
        // 在详细信息界面中，菜单键用于退出
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    /**
     * 处理选择事件
     * @return 是否处理了事件
     */
    function onSelect() as Lang.Boolean {
        // 执行当前页面的特定操作
        if (_view != null) {
            _performPageAction();
        }
        return true;
    }

    /**
     * 处理下一页事件
     * @return 是否处理了事件
     */
    function onNextPage() as Lang.Boolean {
        // 切换到下一页
        if (_view != null) {
            _view.nextPage();
        }
        return true;
    }

    /**
     * 处理上一页事件
     * @return 是否处理了事件
     */
    function onPreviousPage() as Lang.Boolean {
        // 切换到上一页
        if (_view != null) {
            _view.previousPage();
        }
        return true;
    }

    /**
     * 检测是否点击在顶部区域
     * @param y Y坐标
     * @return 是否在顶部区域
     */
    private function _isInTopArea(y as Lang.Number) as Lang.Boolean {
        return y <= 50;
    }

    /**
     * 检测是否点击在底部区域
     * @param y Y坐标
     * @param height 屏幕高度
     * @return 是否在底部区域
     */
    private function _isInBottomArea(y as Lang.Number, height as Lang.Number) as Lang.Boolean {
        return y >= height - 50;
    }

    /**
     * 检测是否点击在左侧区域
     * @param x X坐标
     * @param width 屏幕宽度
     * @return 是否在左侧区域
     */
    private function _isInLeftArea(x as Lang.Number, width as Lang.Number) as Lang.Boolean {
        return x <= width / 3;
    }

    /**
     * 检测是否点击在右侧区域
     * @param x X坐标
     * @param width 屏幕宽度
     * @return 是否在右侧区域
     */
    private function _isInRightArea(x as Lang.Number, width as Lang.Number) as Lang.Boolean {
        return x >= width * 2 / 3;
    }

    /**
     * 执行当前页面的特定操作
     */
    private function _performPageAction() as Void {
        if (_view == null) {
            return;
        }
        
        var currentPage = _view.getCurrentPage();
        
        switch (currentPage) {
            case 0: // 健康数据页面
                _performHealthPageAction();
                break;
                
            case 1: // 环境信息页面
                _performEnvironmentPageAction();
                break;
                
            case 2: // 五行配色页面
                _performFiveElementPageAction();
                break;
        }
        
        // 触觉反馈
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }

    /**
     * 执行健康数据页面的操作
     */
    private function _performHealthPageAction() as Void {
        // 可以打开健康数据的更详细视图或执行同步操作
        // 这里可以添加具体的健康数据操作逻辑
        
        // 示例：显示提示信息
        if (WatchUi has :showToast) {
            WatchUi.showToast("健康数据已更新", null);
        }
    }

    /**
     * 执行环境信息页面的操作
     */
    private function _performEnvironmentPageAction() as Void {
        // 可以刷新天气数据或打开天气应用
        // 这里可以添加具体的环境数据操作逻辑
        
        // 示例：显示提示信息
        if (WatchUi has :showToast) {
            WatchUi.showToast("环境数据已刷新", null);
        }
    }

    /**
     * 执行五行配色页面的操作
     */
    private function _performFiveElementPageAction() as Void {
        // 可以切换五行配色或打开配色设置
        var currentIndex = Storage.getValue("elementIndex");
        if (currentIndex == null) {
            currentIndex = 0;
        }
        
        currentIndex = (currentIndex + 1) % 5;
        Storage.setValue("elementIndex", currentIndex);
        
        // 更新视图
        WatchUi.requestUpdate();
        
        // 示例：显示提示信息
        var elements = ["木", "火", "土", "金", "水"];
        if (WatchUi has :showToast) {
            WatchUi.showToast("切换到" + elements[currentIndex] + "元素", null);
        }
    }
}