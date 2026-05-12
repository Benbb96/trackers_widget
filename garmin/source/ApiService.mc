import Toybox.Application;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// ── Constantes ────────────────────────────────────────────────────────────────

const BASE_URL  = "https://www.benbb96.com/fr";
const KEY_CACHE = "trackers_cache";
const KEY_QUEUE = "offline_queue";

// ── Helpers module-level (pas de callback, pas de self) ───────────────────────

function _pad2(n as Number) as String {
    return n < 10 ? "0" + n.toString() : n.toString();
}

function _isoNow() as String {
    var c = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    return c.year.toString() + "-" + _pad2(c.month) + "-" + _pad2(c.day)
         + "T" + _pad2(c.hour) + ":" + _pad2(c.min) + ":" + _pad2(c.sec);
}

function _apiToken() as String {
    var token = Application.Properties.getValue("apiToken");
    if (token instanceof Lang.String) {
        var s = token as String;
        if (!s.equals("")) { return s; }
    }
    return "";
}

function _headers() as Lang.Dictionary {
    return {
        "Authorization" => "Token " + _apiToken(),
        "Content-Type"  => "application/json"
    };
}

function _hexToColor(hex as String) as Number {
    if (hex.length() < 7) { return 0x005DFF; }
    var result = 0;
    for (var i = 1; i <= 6; i++) {
        var c = hex.substring(i, i + 1).toCharArray()[0];
        var n = c.toNumber();
        var v = 0;
        if      (c >= '0' && c <= '9') { v = n - '0'.toNumber(); }
        else if (c >= 'a' && c <= 'f') { v = n - 'a'.toNumber() + 10; }
        else if (c >= 'A' && c <= 'F') { v = n - 'A'.toNumber() + 10; }
        result = result * 16 + v;
    }
    return result;
}

function _contrastColor(bg as Number) as Graphics.ColorType {
    var r = (bg >> 16) & 0xFF;
    var g = (bg >> 8)  & 0xFF;
    var b =  bg        & 0xFF;
    return ((r * 299 + g * 587 + b * 114) / 1000 > 128)
        ? Graphics.COLOR_BLACK
        : Graphics.COLOR_WHITE;
}

function _parseList(data as Lang.Object?) as Lang.Array {
    if (data == null)                    { return [] as Lang.Array; }
    if (data instanceof Lang.Array)      { return data as Lang.Array; }
    if (data instanceof Lang.Dictionary) {
        var r = (data as Lang.Dictionary)["results"];
        if (r instanceof Lang.Array)     { return r as Lang.Array; }
    }
    return [] as Lang.Array;
}

function cacheTrackers(trackers as Lang.Array) as Void {
    Application.Storage.setValue(KEY_CACHE, trackers);
}

function getCachedTrackers() as Lang.Array? {
    return Application.Storage.getValue(KEY_CACHE) as Lang.Array?;
}

function enqueueTrack(trackerId as Number, valeur as Float?) as Void {
    var queue = Application.Storage.getValue(KEY_QUEUE) as Lang.Array?;
    if (queue == null) { queue = [] as Lang.Array; }
    var entry = { "trackerId" => trackerId, "datetime" => _isoNow() } as Lang.Dictionary;
    if (valeur != null) { entry["valeur"] = valeur; }
    queue.add(entry);
    Application.Storage.setValue(KEY_QUEUE, queue);
}

// ── Singleton ApiService (nécessaire pour method(:callback)) ──────────────────

var _apiInstance as ApiService? = null;

function apiService() as ApiService {
    if (_apiInstance == null) { _apiInstance = new ApiService(); }
    return _apiInstance as ApiService;
}

class ApiService {

    function initialize() {}

    function fetchTrackers(callback as Lang.Method) as Void {
        Communications.makeWebRequest(
            BASE_URL + "/tracker/api/tracker?tracks=0",
            null,
            { :method       => Communications.HTTP_REQUEST_METHOD_GET,
              :headers      => _headers(),
              :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
            callback
        );
    }

    function postTrack(trackerId as Number, valeur as Float?, callback as Lang.Method) as Void {
        var body = { "tracker" => trackerId, "datetime" => _isoNow() } as Lang.Dictionary;
        if (valeur != null) { body["valeur"] = valeur; }
        Communications.makeWebRequest(
            BASE_URL + "/tracker/api/track",
            body,
            { :method       => Communications.HTTP_REQUEST_METHOD_POST,
              :headers      => _headers(),
              :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
            callback
        );
    }

    // Rejoue tous les tracks en attente — fire-and-forget
    function replayQueue() as Void {
        var queue = Application.Storage.getValue(KEY_QUEUE) as Lang.Array?;
        if (queue == null || queue.size() == 0) { return; }
        Application.Storage.deleteValue(KEY_QUEUE);
        for (var i = 0; i < queue.size(); i++) {
            var entry = queue[i] as Lang.Dictionary;
            var body  = { "tracker"  => entry["trackerId"],
                          "datetime" => entry["datetime"] } as Lang.Dictionary;
            if (entry.hasKey("valeur")) { body["valeur"] = entry["valeur"]; }
            Communications.makeWebRequest(
                BASE_URL + "/tracker/api/track",
                body,
                { :method       => Communications.HTTP_REQUEST_METHOD_POST,
                  :headers      => _headers(),
                  :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
                method(:_onReplayResponse)   // ✓ self existe ici
            );
        }
    }

    function _onReplayResponse(responseCode as Number, data as Lang.Dictionary?) as Void {
        // Silencieux
    }
}
