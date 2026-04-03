import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../utils/fa_icon_helper.dart';

class NewTrackerScreen extends StatefulWidget {
  final String token;
  final VoidCallback onCreated;

  const NewTrackerScreen({
    super.key,
    required this.token,
    required this.onCreated,
  });

  @override
  State<NewTrackerScreen> createState() => _NewTrackerScreenState();
}

class _NewTrackerScreenState extends State<NewTrackerScreen> {
  final _nomController = TextEditingController();
  final _iconSearchController = TextEditingController();

  String? _selectedIconName; // ex: "briefcase-medical"
  Color _selectedColor = const Color(0xFF2196F3);
  bool _loading = false;
  String? _error;

  List<MapEntry<String, IconData>> _filteredIcons = [];

  static const _palette = [
    Color(0xFFE53935), Color(0xFFD81B60), Color(0xFF8E24AA),
    Color(0xFF5E35B1), Color(0xFF1E88E5), Color(0xFF039BE5),
    Color(0xFF00ACC1), Color(0xFF00897B), Color(0xFF43A047),
    Color(0xFF7CB342), Color(0xFFFB8C00), Color(0xFFF4511E),
    Color(0xFF6D4C41), Color(0xFF546E7A), Color(0xFF212121),
  ];

  @override
  void initState() {
    super.initState();
    _filteredIcons = faIconMap.entries.toList();
    _iconSearchController.addListener(_filterIcons);
  }

  void _filterIcons() {
    final q = _iconSearchController.text.toLowerCase();
    setState(() {
      _filteredIcons = q.isEmpty
          ? faIconMap.entries.toList()
          : faIconMap.entries.where((e) => e.key.contains(q)).toList();
    });
  }

  Future<void> _submit() async {
    final nom = _nomController.text.trim();
    if (nom.isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final colorHex = '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      final icone = _selectedIconName != null ? 'fas,$_selectedIconName' : '';
      await ApiService(widget.token).createTracker(
        nom: nom,
        icone: icone,
        color: colorHex,
      );
      if (mounted) {
        widget.onCreated();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prévisualisation
                  Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: _selectedColor,
                      child: _selectedIconName != null
                          ? buildFaIcon('fas,$_selectedIconName',
                              color: Colors.white, size: 28)
                          : const FaIcon(FontAwesomeIcons.circleDot,
                              color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nom
                  TextField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  // Palette de couleurs
                  Text('Couleur', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palette.map((c) {
                      final selected = _selectedColor == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Recherche d'icône
                  Text('Icône', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _iconSearchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher (ex: heart, run, food…)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _iconSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _iconSearchController.clear();
                                _filterIcons();
                              },
                            )
                          : null,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Grille d'icônes
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final entry = _filteredIcons[i];
                  final selected = _selectedIconName == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconName = entry.key),
                    child: Tooltip(
                      message: entry.key,
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? _selectedColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: _selectedColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: FaIcon(
                            entry.value,
                            size: 20,
                            color: selected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _filteredIcons.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _iconSearchController.dispose();
    super.dispose();
  }
}
