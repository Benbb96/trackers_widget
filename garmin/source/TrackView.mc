import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Etats de l'écran de saisie
enum TrackState {
    STATE_INPUT,    // saisie (ou confirmation pour type événement)
    STATE_SUCCESS,  // track envoyé / mis en queue
    STATE_ERROR     // erreur inattendue
}

class TrackView extends WatchUi.View {

    var tracker   as Lang.Dictionary;
    var isMesure  as Boolean;
    var valeur    as Float   = 0.0;
    var step      as Float   = 1.0;   // incrément molette
    var state     as Number = STATE_INPUT;
    var statusMsg as String  = "";

    function initialize(t as Lang.Dictionary) {
        View.initialize();
        tracker  = t;
        isMesure = (t["type"] as String).equals("mesure");
    }

    function onLayout(dc as Graphics.Dc) as Void {}

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        var name        = tracker["nom"] as String;
        var bgColor     = _hexToColor(tracker["color"] as String);
        var contrastCol = _contrastColor(bgColor);

        if (state == STATE_SUCCESS) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            _drawSuccess(dc, w, h, cx, cy, name);
            return;
        }

        if (state == STATE_ERROR) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_SMALL, statusMsg,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Fond coloré du tracker
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // Nom en haut uniquement pour mesure (pour event il est au centre)
        if (isMesure) {
            dc.setColor(contrastCol, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 28, Graphics.FONT_SMALL, name,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            _drawValueInput(dc, w, h, cx, cy, contrastCol);
        } else {
            _drawConfirm(dc, w, h, cx, cy, contrastCol, name);
        }
    }

    private function _drawValueInput(dc as Graphics.Dc, w as Number, h as Number,
                                     cx as Number, cy as Number,
                                     contrastCol as Graphics.ColorType) as Void {
        dc.setColor(contrastCol, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 10, Graphics.FONT_NUMBER_HOT, _formatVal(valeur),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy - 70, Graphics.FONT_MEDIUM, "▲",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 55, Graphics.FONT_MEDIUM, "▼",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h - 50, Graphics.FONT_XTINY, "START pour confirmer",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawConfirm(dc as Graphics.Dc, w as Number, h as Number,
                                  cx as Number, cy as Number,
                                  contrastCol as Graphics.ColorType,
                                  name as String) as Void {
        dc.setColor(contrastCol, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_MEDIUM, name,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h - 50, Graphics.FONT_XTINY, "START pour tracker",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawSuccess(dc as Graphics.Dc, w as Number, h as Number,
                                  cx as Number, cy as Number, name as String) as Void {
        dc.setColor(0x00CC66, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - 20, 48);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_MEDIUM, "OK",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 42, Graphics.FONT_SMALL, name,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (!statusMsg.equals("")) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 70, Graphics.FONT_XTINY, statusMsg,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Formate la valeur sans décimale inutile
    private function _formatVal(v as Float) as String {
        var rounded = v.toNumber();
        if ((rounded.toFloat() - v).abs() < 0.01f) {
            return rounded.toString();
        }
        // 1 décimale
        var dec = Math.round((v - rounded.toFloat()) * 10).toNumber().abs();
        return rounded.toString() + "." + dec.toString();
    }
}
