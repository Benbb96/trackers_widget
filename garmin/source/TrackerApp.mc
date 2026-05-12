import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        apiService().replayQueue();
    }

    function onStop(state as Lang.Dictionary?) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new TrackerListView();
        return [view, new TrackerListDelegate(view)];
    }
}

function getApp() as TrackerApp {
    return Application.getApp() as TrackerApp;
}
