import 'package:flutter_test/flutter_test.dart';
import 'package:trackers_widget/models/track.dart';

void main() {
  group('Track.fromJson', () {
    test('parse les champs de base', () {
      final track = Track.fromJson({
        'id': 42,
        'datetime': '2024-03-15T10:30:00Z',
        'commentaire': 'test',
      });

      expect(track.id, 42);
      expect(track.commentaire, 'test');
    });

    test('convertit datetime en heure locale', () {
      final track = Track.fromJson({
        'id': 1,
        'datetime': '2024-03-15T10:30:00Z',
        'commentaire': '',
      });

      expect(track.datetime.isUtc, isFalse);
    });

    test('commentaire vide par défaut si absent', () {
      final track = Track.fromJson({
        'id': 1,
        'datetime': '2024-03-15T10:30:00Z',
      });

      expect(track.commentaire, '');
    });
  });
}
