import 'package:flutter/material.dart';
import '../models/track.dart';
import '../models/tracker.dart';
import '../services/api_service.dart';
import '../utils/fa_icon_helper.dart';

class TrackSheet extends StatefulWidget {
  final Tracker tracker;
  final String token;
  final void Function(Track) onSuccess;
  final Track? editTrack;

  const TrackSheet({
    super.key,
    required this.tracker,
    required this.token,
    required this.onSuccess,
    this.editTrack,
  });

  @override
  State<TrackSheet> createState() => _TrackSheetState();
}

class _TrackSheetState extends State<TrackSheet> {
  late DateTime _dateTime;
  late final TextEditingController _commentController;
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.editTrack != null;

  @override
  void initState() {
    super.initState();
    _dateTime = widget.editTrack?.datetime ?? DateTime.now();
    _commentController = TextEditingController(
      text: widget.editTrack?.commentaire ?? '',
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService(widget.token);
      final Track result;
      if (_isEditing) {
        result = await api.updateTrack(
          widget.editTrack!.id,
          commentaire: _commentController.text.trim(),
          datetime: _dateTime,
        );
      } else {
        result = await api.postTrack(
          widget.tracker.id,
          commentaire: _commentController.text.trim(),
          datetime: _dateTime,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(result);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
      '  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom + mq.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.tracker.backgroundColor,
                child: buildFaIcon(widget.tracker.icone,
                    color: widget.tracker.foregroundColor),
              ),
              const SizedBox(width: 12),
              Text(
                _isEditing ? 'Modifier le track' : widget.tracker.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(_formatDateTime(_dateTime)),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLength: 255,
            maxLines: 2,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: widget.tracker.backgroundColor,
              foregroundColor: widget.tracker.foregroundColor,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? 'Enregistrer' : 'Tracker !'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
