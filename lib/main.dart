import 'package:flutter/material.dart';
import 'screens/config_screen.dart';
import 'screens/widget_config_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrackersWidgetApp());
}

class TrackersWidgetApp extends StatelessWidget {
  const TrackersWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackers Widget',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const ConfigScreen(),
        '/widget-config': (_) => const WidgetConfigScreen(),
      },
    );
  }
}
