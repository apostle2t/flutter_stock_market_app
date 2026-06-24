import 'package:flutter/material.dart';

import 'screens/auth/sign_in_screen.dart';
import 'screens/home/main_navigation.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AetherVestApp());
}

/// Root of the AetherVest stock-tracking app.
class AetherVestApp extends StatelessWidget {
  const AetherVestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AetherVest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainNavigation(), // TEMP: verify live portfolio total
    );
  }
}
