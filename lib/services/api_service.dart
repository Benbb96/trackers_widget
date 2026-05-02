import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tracker.dart';
import '../models/track.dart';

class ApiService {
  static const _baseUrl = 'https://www.benbb96.com/fr';

  final String token;
  final http.Client _client;

  ApiService(this.token, {http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

  Future<List<Tracker>> fetchTrackers() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/tracker/api/tracker'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
    final data = jsonDecode(response.body);
    final List<dynamic> items = data is List ? data : data['results'] ?? [];
    return (items.map((e) => Tracker.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order)));
  }

  Future<Track> postTrack(
    int trackerId, {
    String? commentaire,
    DateTime? datetime,
    double? valeur,
  }) async {
    final body = <String, dynamic>{'tracker': trackerId};
    if (commentaire != null && commentaire.isNotEmpty) {
      body['commentaire'] = commentaire;
    }
    if (datetime != null) {
      body['datetime'] = datetime.toIso8601String();
    }
    if (valeur != null) body['valeur'] = valeur;
    final response = await _client.post(
      Uri.parse('$_baseUrl/tracker/api/track'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
    return Track.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Track> updateTrack(
    int trackId, {
    String? commentaire,
    DateTime? datetime,
    double? valeur,
  }) async {
    final body = <String, dynamic>{};
    if (commentaire != null) body['commentaire'] = commentaire;
    if (datetime != null) body['datetime'] = datetime.toIso8601String();
    if (valeur != null) body['valeur'] = valeur;
    final response = await _client.patch(
      Uri.parse('$_baseUrl/tracker/api/track/$trackId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
    return Track.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteTrack(int trackId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/tracker/api/track/$trackId'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> deleteTracker(int trackerId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/tracker/api/tracker/$trackerId'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
  }

  Future<void> reorderTrackers(List<int> ids) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/tracker/api/tracker/reorder'),
      headers: _headers,
      body: jsonEncode({'ids': ids}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
  }

  Future<Tracker> createTracker({
    required String nom,
    required String icone,
    required String color,
    String type = 'evenement',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/tracker/api/tracker'),
      headers: _headers,
      body: jsonEncode({'nom': nom, 'icone': icone, 'color': color, 'type': type}),
    );
    if (response.statusCode != 201) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
    return Tracker.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
