import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

/**
 * 五行配色表盘应用主类
 */
class FiveElementWatchFaceApp extends Application.AppBase {

    /**
     * 初始化应用
     */
    function initialize() {
        AppBase.initialize();
    }

    /**
     * 应用启动时调用
     */
    function onStart(state as Dictionary?) as Void {
        // 应用启动处理
    }

    /**
     * 应用停止时调用
     */
    function onStop(state as Dictionary?) as Void {
        // 应用停止处理
    }

    /**
     * 获取初始视图
     * @return 视图和委托数组
     */
    function getInitialView() {
        var view = new FiveElementWatchFaceView();
        var delegate = new FiveElementWatchFaceDelegate();
        return [view, delegate];
    }

    // 移除了手表端设置功能，所有设置通过Connect IQ应用进行

    /**
     * 应用程序设置更改时调用
     */
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}