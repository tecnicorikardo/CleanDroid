import 'package:flutter/material.dart';

import 'src/services/cleanup_scheduler.dart';
import 'src/ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CleanupScheduler().initialize();
  runApp(const CleanDroidApp());
}

class CleanDroidApp extends StatelessWidget {
  const CleanDroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F8B8D);

    return MaterialApp(
      title: 'CleanDroid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}
