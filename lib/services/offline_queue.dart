import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import 'api_service.dart';

class PendingTrack {
  final String localId;
  final int trackerId;
  final DateTime datetime;
  final String commentaire;
  final double? valeur;

  const PendingTrack({
    required this.localId,
    required this.trackerId,
    required this.datetime,
    required this.commentaire,
    this.valeur,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'trackerId': trackerId,
        'datetime': datetime.toIso8601String(),
        'commentaire': commentaire,
        if (valeur != null) 'valeur': valeur,
      };

  factory PendingTrack.fromJson(Map<String, dynamic> json) => PendingTrack(
        localId: json['localId'] as String,
        trackerId: json['trackerId'] as int,
        datetime: DateTime.parse(json['datetime'] as String).toLocal(),
        commentaire: json['commentaire'] as String? ?? '',
        valeur: (json['valeur'] as num?)?.toDouble(),
      );
}

class OfflineQueue {
  static const _key = 'offline_track_queue';

  static Future<List<PendingTrack>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => PendingTrack.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> add(PendingTrack pt) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(pt.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> remove(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['localId'] == localId;
    });
    await prefs.setStringList(_key, raw);
  }

  /// Rejoue tous les tracks en attente.
  /// Retourne la liste des (localId → Track serveur) pour les envois réussis.
  static Future<List<(String, Track)>> replay(ApiService api) async {
    final pending = await getAll();
    final results = <(String, Track)>[];
    for (final pt in pending) {
      try {
        final track = await api.postTrack(
          pt.trackerId,
          commentaire: pt.commentaire,
          datetime: pt.datetime,
          valeur: pt.valeur,
        );
        await remove(pt.localId);
        results.add((pt.localId, track));
      } catch (_) {
        // Garde dans la queue, sera retenté à la prochaine connexion
      }
    }
    return results;
  }
}
