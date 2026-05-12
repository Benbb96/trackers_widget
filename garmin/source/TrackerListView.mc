import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Ecran principal : liste scrollable des trackers
class TrackerListView extends WatchUi.View {

    var trackers  as Lang.Array   = [] as Lang.Array;
    var selIndex  as Number       = 0;
    var isLoading as Boolean      = true;
    var isOffline as Boolean      = false;
    var statusMsg as String       = "";

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {}

    function onShow() as Void {
        var cached = getCachedTrackers();
        if (cached != null && cached.size() > 0) {
            trackers  = cached;
            isLoading = false;
        }
        apiService().fetchTrackers(method(:onTrackersReceived));
        WatchUi.requestUpdate();
    }

    function onTrackersReceived(responseCode as Number, data as Lang.Dictionary?) as Void {
        isLoading = false;
        statusMsg = "HTTP " + responseCode.toString(); // debug temporaire
        if (responseCode == 200) {
            var list = _parseList(data);
            cacheTrackers(list);
            trackers  = list;
            isOffline = false;
            statusMsg = "";
            apiService().replayQueue();
        } else if (responseCode < 0) {
            isOffline = true;
            statusMsg = "offline " + responseCode.toString();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Titre
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 18, Graphics.FONT_XTINY, "TRACKERS",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Status / debug
        if (!statusMsg.equals("")) {
            dc.setColor(isOffline ? Graphics.COLOR_ORANGE : Graphics.COLOR_YELLOW,
                        Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h - 22, Graphics.FONT_XTINY, statusMsg,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        if (isLoading && trackers.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_MEDIUM, "...",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (trackers.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_SMALL, "Aucun tracker",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Liste : affiche l'élément sélectionné au centre + voisins atténués
        var itemH = 44;
        for (var offset = -1; offset <= 2; offset++) {
            var idx = selIndex + offset;
            if (idx < 0 || idx >= trackers.size()) { continue; }

            var t    = trackers[idx] as Lang.Dictionary;
            var name = t["nom"] as String;
            var y    = cy + offset * itemH;

            if (offset == 0) {
                var bgColor = _hexToColor(t["color"] as String);
                dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(30, y - 22, w - 60, 44, 10);
                dc.setColor(_contrastColor(bgColor), Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_MEDIUM, name,
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                // Badge type mesure : coin droit du rect
                if ((t["type"] as String).equals("mesure")) {
                    dc.drawText(w - 42, y, Graphics.FONT_XTINY, "#",
                                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_SMALL, name,
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Flèches de navigation
        if (selIndex > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 42, Graphics.FONT_XTINY, "▲",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (selIndex < trackers.size() - 1) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h - 42, Graphics.FONT_XTINY, "▼",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
