import Toybox.Lang;
import Toybox.Math;
import Toybox.Timer;
import Toybox.WatchUi;

class NumberInputDelegate extends WatchUi.InputDelegate {

    private var _view  as NumberInputView;
    private var _timer as Timer.Timer?;

    function initialize(view as NumberInputView) {
        InputDelegate.initialize();
        _view = view;
    }

    // Crown rotation / physical up-down buttons
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (_view.state != 0) {
            if (key == WatchUi.KEY_ESC) {
                if (_timer != null) { (_timer as Timer.Timer).stop(); }
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
            return true;
        }
        if (key == WatchUi.KEY_UP) {
            _view.charIndex = (_view.charIndex + 12) % 13;
            WatchUi.requestUpdate();
        } else if (key == WatchUi.KEY_DOWN) {
            _view.charIndex = (_view.charIndex + 1) % 13;
            WatchUi.requestUpdate();
        } else if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _insert();
        } else if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }

    // Direct tap on a digit of the ring
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (_view.state != 0) { return true; }
        var coords = clickEvent.getCoordinates();
        var tx = coords[0] as Number;
        var ty = coords[1] as Number;
        var radius  = 148;
        var closest = -1;
        var minDist = 40 * 40; // 40px tolerance
        for (var i = 0; i < 13; i++) {
            var angleDeg = i * 360.0 / 13.0 - 90.0;
            var angleRad = angleDeg * (Math.PI / 180.0);
            var dx = _view._cx + (radius.toFloat() * Math.cos(angleRad)).toNumber() - tx;
            var dy = _view._cy + (radius.toFloat() * Math.sin(angleRad)).toNumber() - ty;
            var dist2 = dx * dx + dy * dy;
            if (dist2 < minDist) { minDist = dist2; closest = i; }
        }
        if (closest >= 0) {
            _view.charIndex = closest;
            _insert();
        }
        return true;
    }

    private function _insert() as Void {
        if (_view.state != 0) { return; }
        var ch = INPUT_CHARS[_view.charIndex] as String;
        if (ch.equals("OK")) {
            _sendTrack();
        } else if (ch.equals("<")) {
            if (_view.inputStr.length() > 0) {
                _view.inputStr = _view.inputStr.substring(0, _view.inputStr.length() - 1) as String;
                WatchUi.requestUpdate();
            }
        } else if (ch.equals(".")) {
            if (_view.inputStr.find(".") == null && _view.inputStr.length() < 8) {
                _view.inputStr += ".";
                WatchUi.requestUpdate();
            }
        } else {
            if (_view.inputStr.length() < 8) {
                _view.inputStr += ch;
                WatchUi.requestUpdate();
            }
        }
    }

    private function _parseValue() as Float {
        if (!_view.inputStr.equals("")) {
            var parsed = _view.inputStr.toFloat();
            if (parsed != null) { return parsed as Float; }
        }
        return 0.0f;
    }

    private function _sendTrack() as Void {
        apiService().postTrack(_view.tracker["id"] as Number, _parseValue(), method(:onPostResponse));
    }

    function onPostResponse(responseCode as Number, data as Lang.Dictionary?) as Void {
        if (responseCode == 200 || responseCode == 201) {
            _view.state     = 1;
            _view.statusMsg = "";
            vibrate();
        } else if (responseCode < 0) {
            enqueueTrack(_view.tracker["id"] as Number, _parseValue());
            _view.state     = 1;
            _view.statusMsg = "en attente sync";
            vibrate();
        } else {
            _view.state     = 2;
            _view.statusMsg = "Erreur " + responseCode.toString();
        }
        WatchUi.requestUpdate();
        _timer = new Timer.Timer();
        _timer.start(method(:onTimeout), 2000, false);
    }

    function onTimeout() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
