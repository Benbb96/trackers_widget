import Toybox.Lang;
import Toybox.WatchUi;

class TrackerListDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TrackerListView;

    function initialize(view as TrackerListView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Bouton haut / molette vers le haut
    function onPreviousPage() as Boolean {
        if (_view.selIndex > 0) {
            _view.selIndex -= 1;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // Bouton bas / molette vers le bas
    function onNextPage() as Boolean {
        if (_view.selIndex < _view.trackers.size() - 1) {
            _view.selIndex += 1;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // Bouton START / tap central = sélectionner le tracker
    function onSelect() as Boolean {
        if (_view.trackers.size() == 0) { return true; }
        var t = _view.trackers[_view.selIndex] as Lang.Dictionary;
        var trackView     = new TrackView(t);
        var trackDelegate = new TrackDelegate(trackView);
        WatchUi.pushView(trackView, trackDelegate, WatchUi.SLIDE_LEFT);
        return true;
    }

    // Bouton BACK = quitter l'app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
