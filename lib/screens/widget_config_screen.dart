import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import '../models/tracker.dart';
import '../services/api_service.dart';
import '../utils/fa_icon_helper.dart';

/// Écran lancé quand l'utilisateur ajoute un widget sur le home screen.
/// Il permet de choisir quel tracker assigner à cette instance de widget.
class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  static const _channel = MethodChannel('tracker_widget/config');

  final _storage = const FlutterSecureStorage();
  List<Tracker> _trackers = [];
  bool _loading = true;
  String? _error;
  int? _appWidgetId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // L'id du widget en cours de config est stocké par WidgetConfigActivity
    _appWidgetId = await HomeWidget.getWidgetData<int>('pending_widget_id');
    await _loadTrackers();
  }

  Future<void> _loadTrackers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Essaie d'abord le cache local
      final cache = await HomeWidget.getWidgetData<String>('trackers_cache');
      if (cache != null) {
        final list = jsonDecode(cache) as List<dynamic>;
        setState(() => _trackers = list
            .map((e) => Tracker.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      // Rafraîchit depuis l'API si token disponible
      final token = await _storage.read(key: 'api_token');
      if (token != null) {
        final trackers = await ApiService(token).fetchTrackers();
        await HomeWidget.saveWidgetData<String>(
          'trackers_cache',
          jsonEncode(trackers.map((t) => t.toJson()).toList()),
        );
        setState(() => _trackers = trackers);
      } else if (cache == null) {
        setState(() =>
            _error = 'Ouvre d\'abord l\'app pour configurer ton token API.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _assignTracker(Tracker tracker) async {
    final widgetId = _appWidgetId;
    if (widgetId == null) return;

    // Stocke les données du tracker pour ce widget
    await HomeWidget.saveWidgetData<String>(
      'tracker_$widgetId',
      jsonEncode(tracker.toJson()),
    );

    // Met à jour l'affichage du widget
    await HomeWidget.updateWidget(
      androidName: 'TrackerWidgetProvider',
    );

    // Signale à WidgetConfigActivity de terminer avec RESULT_OK
    await _channel.invokeMethod('finishConfig', {'appWidgetId': widgetId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: _loadTrackers,
                            child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _trackers.length,
                  itemBuilder: (_, i) {
                    final t = _trackers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.backgroundColor,
                        child: buildFaIcon(t.icone, color: t.foregroundColor),
                      ),
                      title: Text(t.name),
                      onTap: () => _assignTracker(t),
                    );
                  },
                ),
    );
  }
}
