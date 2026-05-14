import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class TrackerListDelegate extends WatchUi.BehaviorDelegate {

    private var _view         as TrackerListView;
    private var _lastScrollMs as Number = 0;

    function initialize(view as TrackerListView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    private function _scroll(delta as Number) as Void {
        var now   = System.getTimer();
        var elapsed = now - _lastScrollMs;
        _lastScrollMs = now;
        var step = elapsed < 150 ? 3 : (elapsed < 300 ? 2 : 1);
        var last = _view.trackers.size() - 1;
        _view.selIndex += delta * step;
        if (_view.selIndex < 0)    { _view.selIndex = 0; }
        if (_view.selIndex > last) { _view.selIndex = last; }
        WatchUi.requestUpdate();
    }

    function onPreviousPage() as Boolean {
        _scroll(-1);
        return true;
    }

    function onNextPage() as Boolean {
        _scroll(1);
        return true;
    }

    // Swipe = scroll rapide (3 items) — horizontal car le vertical est intercepté par l'OS
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var dir  = swipeEvent.getDirection();
        var last = _view.trackers.size() - 1;
        if (dir == WatchUi.SWIPE_UP || dir == WatchUi.SWIPE_LEFT) {
            _view.selIndex += 3;
            if (_view.selIndex > last) { _view.selIndex = last; }
            WatchUi.requestUpdate();
        } else if (dir == WatchUi.SWIPE_DOWN || dir == WatchUi.SWIPE_RIGHT) {
            _view.selIndex -= 3;
            if (_view.selIndex < 0) { _view.selIndex = 0; }
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onSelect() as Boolean {
        if (_view.trackers.size() == 0) { return true; }
        var t = _view.trackers[_view.selIndex] as Lang.Dictionary;
        if ((t["type"] as String).equals("mesure")) {
            var numView = new NumberInputView(t);
            var numDel  = new NumberInputDelegate(numView);
            WatchUi.pushView(numView, numDel, WatchUi.SLIDE_LEFT);
        } else {
            var trackView = new TrackView(t);
            var trackDel  = new TrackDelegate(trackView);
            WatchUi.pushView(trackView, trackDel, WatchUi.SLIDE_LEFT);
        }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
