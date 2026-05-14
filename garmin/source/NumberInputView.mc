import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Anneau : 0 en haut (12h), puis 1-9, virgule, effacement, validation
const INPUT_CHARS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "<", "OK"] as Array<String>;

class NumberInputView extends WatchUi.View {

    var inputStr  as String          = "";
    var charIndex as Number          = 0;   // démarre sur "0"
    var tracker   as Lang.Dictionary;
    var state     as Number          = 0;   // 0=saisie, 1=succès, 2=erreur
    var statusMsg as String          = "";
    var _cx       as Number          = 227; // mis à jour dans onUpdate pour onTap
    var _cy       as Number          = 227;

    function initialize(t as Lang.Dictionary) {
        View.initialize();
        tracker = t;
    }

    function onLayout(dc as Graphics.Dc) as Void {}

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        _cx = w / 2;
        _cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (state == 1) {
            _drawSuccess(dc, cx, cy);
            return;
        }
        if (state == 2) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_SMALL, statusMsg,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Nom du tracker en haut
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 22, Graphics.FONT_XTINY, tracker["nom"] as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Valeur composée au centre sur fond coloré
        var bgColor = _hexToColor(tracker["color"] as String);
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 60, cy - 26, 120, 52, 10);
        dc.setColor(_contrastColor(bgColor), Graphics.COLOR_TRANSPARENT);
        var display = inputStr.equals("") ? "0" : inputStr;
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_MILD, display,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Anneau de 13 caractères
        var radius = 148;
        for (var i = 0; i < 13; i++) {
            var angleDeg = i * 360.0 / 13.0 - 90.0;
            var angleRad = angleDeg * (Math.PI / 180.0);
            var x = cx + (radius.toFloat() * Math.cos(angleRad)).toNumber();
            var y = cy + (radius.toFloat() * Math.sin(angleRad)).toNumber();

            if (i == charIndex) {
                dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, y, Graphics.FONT_MEDIUM, INPUT_CHARS[i],
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, y, Graphics.FONT_XTINY, INPUT_CHARS[i],
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    private function _drawSuccess(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0x00CC66, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - 20, 48);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_MEDIUM, "OK",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 42, Graphics.FONT_SMALL, tracker["nom"] as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (!statusMsg.equals("")) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 70, Graphics.FONT_XTINY, statusMsg,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
