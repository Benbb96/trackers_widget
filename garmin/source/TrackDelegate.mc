import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class TrackDelegate extends WatchUi.BehaviorDelegate {

    private var _view  as TrackView;
    private var _timer as Timer.Timer?;

    function initialize(view as TrackView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Molette / bouton haut → augmente la valeur (mesure seulement)
    function onPreviousPage() as Boolean {
        if (_view.isMesure && _view.state == STATE_INPUT) {
            _view.valeur += _view.step;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // Molette / bouton bas → diminue la valeur
    function onNextPage() as Boolean {
        if (_view.isMesure && _view.state == STATE_INPUT) {
            _view.valeur -= _view.step;
            WatchUi.requestUpdate();
        }
        return true;
    }

    // START = confirmer le track
    function onSelect() as Boolean {
        if (_view.state != STATE_INPUT) { return true; }
        var t         = _view.tracker;
        var trackerId = t["id"] as Number;
        var valeur    = _view.isMesure ? _view.valeur : null;
        apiService().postTrack(trackerId, valeur, method(:onPostResponse));
        return true;
    }

    function onPostResponse(responseCode as Number, data as Lang.Dictionary?) as Void {
        if (responseCode == 200 || responseCode == 201) {
            _view.state     = STATE_SUCCESS;
            _view.statusMsg = "";
            vibrate();
        } else if (responseCode < 0) {
            // Hors ligne → mise en queue
            var t         = _view.tracker;
            var trackerId = t["id"] as Number;
            var valeur    = _view.isMesure ? _view.valeur : null;
            enqueueTrack(trackerId, valeur);
            _view.state     = STATE_SUCCESS;
            _view.statusMsg = "en attente sync";
            vibrate();
        } else {
            _view.state     = STATE_ERROR;
            _view.statusMsg = "Erreur " + responseCode.toString();
        }
        WatchUi.requestUpdate();
        // Retour automatique après 2 secondes
        _timer = new Timer.Timer();
        _timer.start(method(:onTimeout), 2000, false);
    }

    function onTimeout() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    // BACK = annuler
    function onBack() as Boolean {
        if (_timer != null) { (_timer as Timer.Timer).stop(); }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

}
