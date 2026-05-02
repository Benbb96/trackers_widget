import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import '../models/tracker.dart';
import '../services/api_service.dart';
import '../utils/fa_icon_helper.dart';
import '../widgets/track_sheet.dart';
import 'new_tracker_screen.dart';
import 'tracks_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _tokenController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  List<Tracker> _trackers = [];
  bool _loading = false;
  String? _error;
  String? _token;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await _storage.read(key: 'api_token');
    if (token != null) {
      _tokenController.text = token;
      _token = token;
      _fetchTrackers(token);
    }
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    await _storage.write(key: 'api_token', value: token);
    await HomeWidget.saveWidgetData<String>('api_token', token);
    setState(() => _token = token);
    await _fetchTrackers(token);
    if (mounted) setState(() => _tabIndex = 0);
  }

  Future<void> _fetchTrackers(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trackers = await ApiService(token).fetchTrackers();
      await HomeWidget.saveWidgetData<String>(
        'trackers_cache',
        jsonEncode(trackers.map((t) => t.toJson()).toList()),
      );
      setState(() => _trackers = trackers);
    } on SocketException {
      setState(() => _error = 'Pas de connexion et aucun cache disponible.\nConnecte-toi une première fois pour activer le mode offline.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteTracker(Tracker tracker) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce tracker ?'),
        content: Text('« ${tracker.name} » et tous ses tracks seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || _token == null) return;
    try {
      await ApiService(_token!).deleteTracker(tracker.id);
      _fetchTrackers(_token!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _reorderTrackers(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _trackers.removeAt(oldIndex);
      _trackers.insert(newIndex, item);
    });
    if (_token == null) return;
    try {
      await ApiService(_token!).reorderTrackers(
        _trackers.map((t) => t.id).toList(),
      );
    } catch (_) {
      _fetchTrackers(_token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _TrackerListTab(
            trackers: _trackers,
            loading: _loading,
            error: _error,
            token: _token,
            onRefresh: _token != null ? () => _fetchTrackers(_token!) : null,
            onReorder: _token != null ? _reorderTrackers : null,
            onDelete: _token != null ? _deleteTracker : null,
          ),
          _SettingsTab(
            controller: _tokenController,
            onSave: _saveToken,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.track_changes), label: 'Trackers'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}

// ── Onglet trackers ──────────────────────────────────────────────────────────

class _TrackerListTab extends StatelessWidget {
  final List<Tracker> trackers;
  final bool loading;
  final String? error;
  final String? token;
  final VoidCallback? onRefresh;
  final void Function(int, int)? onReorder;
  final void Function(Tracker)? onDelete;

  const _TrackerListTab({
    required this.trackers,
    required this.loading,
    required this.error,
    required this.token,
    required this.onRefresh,
    this.onReorder,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (onRefresh != null && !loading)
            IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: token != null
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewTrackerScreen(
                    token: token!,
                    onCreated: onRefresh ?? () {},
                  ),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }

    if (token == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Configure ton token API dans l\'onglet Réglages pour voir tes trackers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (trackers.isEmpty) {
      return const Center(child: Text('Aucun tracker.'));
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: trackers.length,
        onReorder: onReorder ?? (oldIndex, newIndex) {},
        itemBuilder: (_, i) => _TrackerTile(
          key: ValueKey(trackers[i].id),
          tracker: trackers[i],
          token: token!,
          onRefresh: onRefresh ?? () {},
          onDelete: onDelete != null ? () => onDelete!(trackers[i]) : () {},
        ),
      ),
    );
  }
}

// ── Onglet réglages ──────────────────────────────────────────────────────────

class _SettingsTab extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _SettingsTab({required this.controller, required this.onSave});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Token API', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: widget.controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Token Django REST Framework',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ajoute un widget sur le home screen et sélectionne le tracker à lui assigner.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile tracker ─────────────────────────────────────────────────────────────

class _TrackerTile extends StatelessWidget {
  final Tracker tracker;
  final String token;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _TrackerTile({
    super.key,
    required this.tracker,
    required this.token,
    required this.onRefresh,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return 'aujourd\'hui ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String get _subtitle {
    final count = '${tracker.nbTracks} track${tracker.nbTracks != 1 ? 's' : ''}';
    final last = tracker.lastTrackDate;
    return last != null ? '$count · dernier : ${_formatDate(last)}' : '$count · jamais tracké';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tracker.backgroundColor,
          child: buildFaIcon(tracker.icone, color: tracker.foregroundColor),
        ),
        title: Text(tracker.name),
        subtitle: Text(_subtitle),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TracksScreen(
              tracker: tracker,
              token: token,
              onChanged: onRefresh,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: tracker.backgroundColor,
                foregroundColor: tracker.foregroundColor,
              ),
              onPressed: () => _showTrackSheet(context),
            ),
            PopupMenuButton<String>(
              onSelected: (v) { if (v == 'delete') onDelete(); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrackSheet(
        tracker: tracker,
        token: token,
        onSuccess: (_) => onRefresh(),
      ),
    );
  }
}
