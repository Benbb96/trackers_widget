import 'package:flutter_test/flutter_test.dart';
import 'package:trackers_widget/models/tracker.dart';

Map<String, dynamic> _baseTrackerJson({
  int id = 1,
  String nom = 'Sport',
  String icone = 'fas,dumbbell',
  String color = '#E53935',
  String contrastColor = '#FFFFFF',
  int order = 0,
  int? nbTracks,
  List<dynamic> tracks = const [],
}) =>
    {
      'id': id,
      'nom': nom,
      'icone': icone,
      'color': color,
      'contrast_color': contrastColor,
      'order': order,
      'nb_tracks': nbTracks,
      'tracks': tracks,
    };

void main() {
  group('Tracker.fromJson', () {
    test('parse les champs de base', () {
      final tracker = Tracker.fromJson(_baseTrackerJson());

      expect(tracker.id, 1);
      expect(tracker.name, 'Sport');
      expect(tracker.icone, 'fas,dumbbell');
      expect(tracker.order, 0);
    });

    test('parse les couleurs depuis hex', () {
      final tracker = Tracker.fromJson(
        _baseTrackerJson(color: '#E53935', contrastColor: '#FFFFFF'),
      );

      expect(tracker.backgroundColor.toARGB32(), 0xFFE53935);
      expect(tracker.foregroundColor.toARGB32(), 0xFFFFFFFF);
    });

    test('couleur par défaut si absente', () {
      final json = _baseTrackerJson()..remove('color');
      final tracker = Tracker.fromJson(json);

      expect(tracker.color, '#2196F3');
    });

    test('nb_tracks depuis le champ API', () {
      final tracker = Tracker.fromJson(_baseTrackerJson(nbTracks: 42));

      expect(tracker.nbTracks, 42);
    });

    test('nb_tracks fallback sur tracks.length si champ absent', () {
      final tracker = Tracker.fromJson(_baseTrackerJson(
        tracks: [
          {'id': 1, 'datetime': '2024-01-01T00:00:00Z', 'commentaire': ''},
          {'id': 2, 'datetime': '2024-01-02T00:00:00Z', 'commentaire': ''},
        ],
      ));

      expect(tracker.nbTracks, 2);
    });

    test('tracks triés par datetime décroissant', () {
      final tracker = Tracker.fromJson(_baseTrackerJson(
        tracks: [
          {'id': 1, 'datetime': '2024-01-01T00:00:00Z', 'commentaire': ''},
          {'id': 3, 'datetime': '2024-03-01T00:00:00Z', 'commentaire': ''},
          {'id': 2, 'datetime': '2024-02-01T00:00:00Z', 'commentaire': ''},
        ],
      ));

      expect(tracker.tracks[0].id, 3);
      expect(tracker.tracks[1].id, 2);
      expect(tracker.tracks[2].id, 1);
    });

    test('lastTrackDate est le premier track trié', () {
      final tracker = Tracker.fromJson(_baseTrackerJson(
        tracks: [
          {'id': 1, 'datetime': '2024-01-01T00:00:00Z', 'commentaire': ''},
          {'id': 2, 'datetime': '2024-06-01T00:00:00Z', 'commentaire': ''},
        ],
      ));

      expect(tracker.lastTrackDate, tracker.tracks.first.datetime);
    });

    test('lastTrackDate null si aucun track', () {
      final tracker = Tracker.fromJson(_baseTrackerJson());

      expect(tracker.lastTrackDate, isNull);
    });
  });
}
