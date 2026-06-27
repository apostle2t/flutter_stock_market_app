import 'package:flutter/material.dart';

import 'screens/auth/sign_in_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the saved light/dark choice (and apply its palette) before first paint.
  await ThemeController.instance.load();
  runApp(const AetherVestApp());
}

/// Root of the AetherVest stock-tracking app.
class AetherVestApp extends StatelessWidget {
  const AetherVestApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app (with a matching theme) whenever the user toggles
    // between light and dark.
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) => MaterialApp(
        title: 'AetherVest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.current,
        // Switch themes instantly: by default MaterialApp cross-fades theme
        // changes (~200ms), which would lag behind the AppColors-driven cards
        // that flip immediately. Zero duration makes background + items change
        // together, in one snap.
        themeAnimationDuration: Duration.zero,
        home: const SignInScreen(),
      ),
    );
  }
}
