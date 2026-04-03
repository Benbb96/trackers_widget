import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackers_widget/services/api_service.dart';

const _token = 'test-token';

http.Response _json(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _trackerJson({
  int id = 1,
  String nom = 'Sport',
  int order = 0,
  int nbTracks = 0,
}) =>
    {
      'id': id,
      'nom': nom,
      'icone': 'fas,dumbbell',
      'color': '#E53935',
      'contrast_color': '#FFFFFF',
      'order': order,
      'nb_tracks': nbTracks,
      'tracks': [],
    };

Map<String, dynamic> _trackJson({
  int id = 10,
  String datetime = '2024-03-15T10:30:00Z',
  String commentaire = '',
}) =>
    {'id': id, 'datetime': datetime, 'commentaire': commentaire};

void main() {
  // ── fetchTrackers ──────────────────────────────────────────────────────────

  group('fetchTrackers', () {
    test('parse une réponse liste', () async {
      final client = MockClient((_) async => _json([
            _trackerJson(id: 1, order: 2),
            _trackerJson(id: 2, order: 1),
          ]));
      final service = ApiService(_token, client: client);

      final trackers = await service.fetchTrackers();

      expect(trackers.length, 2);
      expect(trackers[0].id, 2); // trié par order
      expect(trackers[1].id, 1);
    });

    test('parse une réponse paginée (results)', () async {
      final client = MockClient((_) async => _json({
            'count': 1,
            'results': [_trackerJson(id: 5)],
          }));
      final service = ApiService(_token, client: client);

      final trackers = await service.fetchTrackers();

      expect(trackers.length, 1);
      expect(trackers[0].id, 5);
    });

    test('envoie le bon header Authorization', () async {
      http.Request? captured;
      final client = MockClient((req) async {
        captured = req;
        return _json([]);
      });
      await ApiService(_token, client: client).fetchTrackers();

      expect(captured?.headers['Authorization'], 'Token $_token');
    });

    test('lève une exception sur non-200', () async {
      final client = MockClient((_) async => http.Response('Forbidden', 403));
      final service = ApiService(_token, client: client);

      expect(service.fetchTrackers(), throwsException);
    });
  });

  // ── postTrack ──────────────────────────────────────────────────────────────

  group('postTrack', () {
    test('envoie tracker_id dans le body', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_trackJson(id: 99), status: 201);
      });
      await ApiService(_token, client: client).postTrack(7);

      expect(body?['tracker'], 7);
    });

    test('inclut commentaire si non vide', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_trackJson(), status: 201);
      });
      await ApiService(_token, client: client)
          .postTrack(1, commentaire: 'bravo');

      expect(body?['commentaire'], 'bravo');
    });

    test('omet commentaire si vide', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_trackJson(), status: 201);
      });
      await ApiService(_token, client: client).postTrack(1, commentaire: '');

      expect(body?.containsKey('commentaire'), isFalse);
    });

    test('inclut datetime si fourni', () async {
      Map<String, dynamic>? body;
      final dt = DateTime(2024, 3, 15, 10, 30);
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_trackJson(), status: 201);
      });
      await ApiService(_token, client: client).postTrack(1, datetime: dt);

      expect(body?.containsKey('datetime'), isTrue);
    });

    test('retourne le Track créé', () async {
      final client = MockClient((_) async =>
          _json(_trackJson(id: 99, commentaire: 'ok'), status: 201));
      final track =
          await ApiService(_token, client: client).postTrack(1);

      expect(track.id, 99);
    });

    test('lève une exception sur non-201/200', () {
      final client = MockClient((_) async => http.Response('error', 400));
      expect(ApiService(_token, client: client).postTrack(1), throwsException);
    });
  });

  // ── updateTrack ────────────────────────────────────────────────────────────

  group('updateTrack', () {
    test('envoie une requête PATCH à la bonne URL', () async {
      Uri? url;
      final client = MockClient((req) async {
        url = req.url;
        return _json(_trackJson(id: 5));
      });
      await ApiService(_token, client: client).updateTrack(5);

      expect(url?.path, contains('/tracker/api/track/5'));
    });

    test('retourne le Track mis à jour', () async {
      final client = MockClient((_) async =>
          _json(_trackJson(id: 5, commentaire: 'modifié')));
      final track =
          await ApiService(_token, client: client).updateTrack(5);

      expect(track.commentaire, 'modifié');
    });

    test('lève une exception sur non-200', () {
      final client = MockClient((_) async => http.Response('error', 400));
      expect(
          ApiService(_token, client: client).updateTrack(5), throwsException);
    });
  });

  // ── deleteTrack ────────────────────────────────────────────────────────────

  group('deleteTrack', () {
    test('envoie une requête DELETE à la bonne URL', () async {
      Uri? url;
      String? method;
      final client = MockClient((req) async {
        url = req.url;
        method = req.method;
        return http.Response('', 204);
      });
      await ApiService(_token, client: client).deleteTrack(3);

      expect(method, 'DELETE');
      expect(url?.path, contains('/tracker/api/track/3'));
    });

    test('accepte 204 comme succès', () async {
      final client = MockClient((_) async => http.Response('', 204));
      expect(ApiService(_token, client: client).deleteTrack(1),
          completes);
    });

    test('lève une exception sur non-204/200', () {
      final client = MockClient((_) async => http.Response('error', 404));
      expect(
          ApiService(_token, client: client).deleteTrack(1), throwsException);
    });
  });

  // ── deleteTracker ──────────────────────────────────────────────────────────

  group('deleteTracker', () {
    test('envoie DELETE à /tracker/api/tracker/{id}', () async {
      Uri? url;
      final client = MockClient((req) async {
        url = req.url;
        return http.Response('', 204);
      });
      await ApiService(_token, client: client).deleteTracker(7);

      expect(url?.path, contains('/tracker/api/tracker/7'));
    });

    test('lève une exception sur non-204/200', () {
      final client = MockClient((_) async => http.Response('error', 404));
      expect(ApiService(_token, client: client).deleteTracker(7),
          throwsException);
    });
  });

  // ── reorderTrackers ────────────────────────────────────────────────────────

  group('reorderTrackers', () {
    test('envoie PATCH avec la liste des ids', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({});
      });
      await ApiService(_token, client: client).reorderTrackers([3, 1, 2]);

      expect(body?['ids'], [3, 1, 2]);
    });

    test('lève une exception sur non-200', () {
      final client = MockClient((_) async => http.Response('error', 400));
      expect(ApiService(_token, client: client).reorderTrackers([1]),
          throwsException);
    });
  });

  // ── createTracker ──────────────────────────────────────────────────────────

  group('createTracker', () {
    test('envoie nom, icone et color', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_trackerJson(), status: 201);
      });
      await ApiService(_token, client: client).createTracker(
        nom: 'Running',
        icone: 'fas,person-running',
        color: '#43A047',
      );

      expect(body?['nom'], 'Running');
      expect(body?['icone'], 'fas,person-running');
      expect(body?['color'], '#43A047');
    });

    test('retourne le Tracker créé', () async {
      final client = MockClient((_) async =>
          _json(_trackerJson(id: 42, nom: 'Running'), status: 201));
      final tracker = await ApiService(_token, client: client).createTracker(
        nom: 'Running',
        icone: '',
        color: '#000000',
      );

      expect(tracker.id, 42);
      expect(tracker.name, 'Running');
    });

    test('lève une exception sur non-201', () {
      final client = MockClient((_) async => http.Response('error', 400));
      expect(
        ApiService(_token, client: client)
            .createTracker(nom: 'x', icone: '', color: '#000000'),
        throwsException,
      );
    });
  });
}
