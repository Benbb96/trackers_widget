import 'dart:ui';
import 'track.dart';

class Tracker {
  final int id;
  final String name;
  final String icone;
  final String color;
  final String contrastColor;
  final List<Track> tracks;
  final int order;
  final int nbTracksTotal;
  final String type;

  const Tracker({
    required this.id,
    required this.name,
    required this.icone,
    required this.color,
    required this.contrastColor,
    this.tracks = const [],
    this.order = 0,
    this.nbTracksTotal = 0,
    this.type = 'evenement',
  });

  bool get isMesure => type == 'mesure';

  factory Tracker.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'] as List<dynamic>? ?? [];
    final tracks = rawTracks
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    return Tracker(
      id: json['id'] as int,
      name: json['nom'] as String,
      icone: json['icone'] as String? ?? '',
      color: json['color'] as String? ?? '#2196F3',
      contrastColor: json['contrast_color'] as String? ?? '#FFFFFF',
      tracks: tracks,
      order: json['order'] as int? ?? 0,
      nbTracksTotal: json['nb_tracks'] as int? ?? tracks.length,
      type: json['type'] as String? ?? 'evenement',
    );
  }

  // toJson minimal pour le cache widget (pas besoin des tracks)
  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': name,
        'icone': icone,
        'color': color,
        'contrast_color': contrastColor,
      };

  int get nbTracks => nbTracksTotal;
  DateTime? get lastTrackDate => tracks.isEmpty ? null : tracks.first.datetime;

  Color get backgroundColor => _colorFromHex(color);
  Color get foregroundColor => _colorFromHex(contrastColor);

  static Color _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x2196F3;
    return Color(0xFF000000 | value);
  }
}
