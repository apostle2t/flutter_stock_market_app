// Tab widgets are intentionally created fresh on each build (not const) so they
// rebuild when the theme toggles — see _MainNavigationState.build.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../news/news_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import '../local/local_screen.dart';

/// Bottom-navigation for the 5 main tabs.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole tab host (and its screens) when the theme changes, so
    // widgets that read AppColors directly pick up the new palette. The tab
    // widgets are recreated here (non-const) so they actually re-render; their
    // State — and thus any fetched data — is preserved across the rebuild.
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final tabs = <Widget>[
          HomeScreen(),
          PortfolioScreen(),
          LocalScreen(),
          NewsScreen(),
          ProfileScreen(),
        ];
        return Scaffold(
          body: IndexedStack(index: _index, children: tabs),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_outline_rounded),
                  activeIcon: Icon(Icons.pie_chart_rounded),
                  label: 'Portfolio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_outlined),
                  activeIcon: Icon(Icons.location_on_rounded),
                  label: 'Local',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article_outlined),
                  activeIcon: Icon(Icons.article_rounded),
                  label: 'News',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
