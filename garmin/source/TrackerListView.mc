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

        // Liste : 3 items au début, jusqu'à 5 en milieu de liste
        var itemH      = 48;
        var minOffset  = selIndex >= 2 ? -2 : -selIndex;
        var maxItems   = trackers.size() - 1 - selIndex;
        var maxOffset  = maxItems >= 2 ? 2 : maxItems;
        for (var offset = minOffset; offset <= maxOffset; offset++) {
            var idx = selIndex + offset;
            if (idx < 0 || idx >= trackers.size()) { continue; }

            var t    = trackers[idx] as Lang.Dictionary;
            var name = t["nom"] as String;
            var y    = cy + offset * itemH;

            var pending  = getQueueCountForTracker(t["id"] as Number);
            var isMesure = (t["type"] as String).equals("mesure");
            if (offset == 0) {
                var bgColor = _hexToColor(t["color"] as String);
                dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(30, y - 22, w - 60, 44, 10);
                var iconColor = _contrastColor(bgColor);
                var tw        = dc.getTextWidthInPixels(name, Graphics.FONT_MEDIUM);
                dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_MEDIUM, name,
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                // Icône mesure : mini bar chart à gauche du texte
                if (isMesure) {
                    var ix = cx - tw / 2 - 26;
                    dc.fillRoundedRectangle(ix,      y - 1, 5, 8,  1);
                    dc.fillRoundedRectangle(ix + 8,  y - 5, 5, 12, 1);
                    dc.fillRoundedRectangle(ix + 16, y - 3, 5, 10, 1);
                }
                // Badge queue : à droite du texte, clampe avant le bord droit du rect
                if (pending > 0) {
                    var bx   = cx + tw / 2 + 12;
                    var maxBx = isMesure ? w - 58 : w - 38;
                    if (bx > maxBx) { bx = maxBx; }
                    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(bx, y, 9);
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(bx, y, Graphics.FONT_XTINY, pending.toString(),
                                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            } else {
                var tw = dc.getTextWidthInPixels(name, Graphics.FONT_SMALL);
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_SMALL, name,
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                if (isMesure) {
                    var ix = cx - tw / 2 - 20;
                    dc.fillRoundedRectangle(ix,      y - 1, 4, 6, 1);
                    dc.fillRoundedRectangle(ix + 6,  y - 4, 4, 9, 1);
                    dc.fillRoundedRectangle(ix + 12, y - 2, 4, 7, 1);
                }
                if (pending > 0) {
                    var bx = cx + tw / 2 + 10;
                    if (bx > w - 20) { bx = w - 20; }
                    dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(bx, y, 5);
                }
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
