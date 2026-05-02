import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/tracker.dart';
import '../models/track.dart';
import '../services/api_service.dart';
import '../services/offline_queue.dart';
import '../widgets/track_sheet.dart';

class TracksScreen extends StatefulWidget {
  final Tracker tracker;
  final String token;
  final VoidCallback? onChanged;

  const TracksScreen({
    super.key,
    required this.tracker,
    required this.token,
    this.onChanged,
  });

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  final _scrollController = ScrollController();
  String _floatingDate = '';
  bool _showFloatingDate = false;
  late List<Track> _tracks;
  late List<_ListItem> _items;
  late int _totalCount;
  bool _refreshing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _tracks = List.of(widget.tracker.tracks);
    _items = _buildItems(_tracks);
    _totalCount = widget.tracker.nbTracksTotal;
    _scrollController.addListener(_onScroll);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork) _replayAndRefresh();
  }

  Future<void> _replayAndRefresh() async {
    final pending = await OfflineQueue.getAll();
    if (pending.isEmpty) return;
    final replayed = await OfflineQueue.replay(ApiService(widget.token));
    if (replayed.isEmpty || !mounted) return;
    // Remplace les tracks pending par les tracks serveur
    for (final (localId, serverTrack) in replayed) {
      final idx = _tracks.indexWhere((t) => t.localId == localId);
      if (idx != -1) _tracks[idx] = serverTrack;
    }
    _rebuildItems();
    widget.onChanged?.call();
  }

  void _rebuildItems() {
    setState(() => _items = _buildItems(_tracks));
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final trackers = await ApiService(widget.token).fetchTrackers();
      final updated = trackers.firstWhere(
        (t) => t.id == widget.tracker.id,
        orElse: () => widget.tracker,
      );
      _tracks = List.of(updated.tracks);
      setState(() => _totalCount = updated.nbTracksTotal);
      _rebuildItems();
      widget.onChanged?.call();
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pas de connexion — données non mises à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Construit une liste plate alternant headers de date et items de track.
  List<_ListItem> _buildItems(List<Track> tracks) {
    final items = <_ListItem>[];
    String? lastDay;
    for (final track in tracks) {
      final day = _dayKey(track.datetime);
      if (day != lastDay) {
        items.add(_ListItem.header(track.datetime));
        lastDay = day;
      }
      items.add(_ListItem.track(track));
    }
    return items;
  }

  String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatHeaderDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun',
                    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    if (dt.year == now.year) {
      return '${dt.day} ${months[dt.month - 1]}';
    }
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent == 0) return;

    final ratio = offset / maxExtent;
    final approxIndex = (ratio * _items.length).floor().clamp(0, _items.length - 1);

    for (int i = approxIndex; i >= 0; i--) {
      if (_items[i].isHeader) {
        setState(() => _floatingDate = _formatHeaderDate(_items[i].date!));
        return;
      }
    }
  }

  void _showTrackSheet({Track? editTrack}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrackSheet(
        tracker: widget.tracker,
        token: widget.token,
        editTrack: editTrack,
        onSuccess: (track) {
          if (editTrack != null) {
            final idx = _tracks.indexWhere((t) => t.id == track.id);
            if (idx != -1) _tracks[idx] = track;
          } else {
            _tracks.insert(0, track);
            _tracks.sort((a, b) => b.datetime.compareTo(a.datetime));
            setState(() => _totalCount++);
          }
          _rebuildItems();
          widget.onChanged?.call();
        },
      ),
    );
  }

  Future<void> _confirmDelete(Track track) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce track ?'),
        content: Text(_formatTime(track.datetime) +
            (track.commentaire.isNotEmpty ? '\n${track.commentaire}' : '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService(widget.token).deleteTrack(track.id);
      _tracks.removeWhere((t) => t.id == track.id);
      setState(() => _totalCount--);
      _rebuildItems();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tracker.name),
            Text(
              '$_totalCount track${_totalCount != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: widget.tracker.backgroundColor,
        foregroundColor: widget.tracker.foregroundColor,
        actions: [
          if (!_refreshing)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.tracker.backgroundColor,
        foregroundColor: widget.tracker.foregroundColor,
        onPressed: () => _showTrackSheet(),
        child: const Icon(Icons.add),
      ),
      body: _tracks.isEmpty
          ? const Center(child: Text('Aucun track pour ce tracker.'))
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollStartNotification) {
                  setState(() => _showFloatingDate = true);
                } else if (n is ScrollEndNotification) {
                  setState(() => _showFloatingDate = false);
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: Stack(
                children: [
                  Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _items.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        if (item.isHeader) {
                          return _DateHeader(label: _formatHeaderDate(item.date!));
                        }
                        return _TrackTile(
                          track: item.track!,
                          formatTime: _formatTime,
                          onEdit: () => _showTrackSheet(editTrack: item.track),
                          onDelete: () => _confirmDelete(item.track!),
                        );
                      },
                    ),
                  ),
                  if (_showFloatingDate && _floatingDate.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 48,
                      child: AnimatedOpacity(
                        opacity: _showFloatingDate ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _floatingDate,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Modèle interne ────────────────────────────────────────────────────────────

class _ListItem {
  final bool isHeader;
  final DateTime? date;
  final Track? track;

  const _ListItem.header(this.date)
      : isHeader = true,
        track = null;

  const _ListItem.track(this.track)
      : isHeader = false,
        date = null;
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final String Function(DateTime) formatTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TrackTile({
    required this.track,
    required this.formatTime,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatValeur(double v) =>
      v == v.truncateToDouble() ? v.truncate().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final valeurStr =
        track.valeur != null ? ' — ${_formatValeur(track.valeur!)}' : '';
    return ListTile(
      leading: track.isPending
          ? const Tooltip(
              message: 'En attente de synchronisation',
              child: Icon(Icons.schedule, color: Colors.orange),
            )
          : const Icon(Icons.check_circle_outline),
      title: Text('${formatTime(track.datetime)}$valeurStr'),
      subtitle: track.commentaire.isNotEmpty ? Text(track.commentaire) : null,
      dense: true,
      trailing: track.isPending
          ? null
          : PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
    );
  }
}
