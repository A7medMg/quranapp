import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app/core/theme/app_theme.dart';
import 'package:quran_app/features/dua/presentation/dua_tab.dart';
import 'package:quran_app/features/hadith/presentation/hadith_tab.dart';
import 'package:quran_app/features/home/presentation/home_dashboard.dart';
import 'package:quran_app/features/quran/presentation/quran_tab.dart';
import 'package:quran_app/features/sebha/presentation/sebha_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = 'Home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _homeRefreshVersion = 0;
  String _duaInitialKind = 'dua';
  bool _isExitDialogOpen = false;

  Future<void> _confirmExit() async {
    if (_isExitDialogOpen) return;
    _isExitDialogOpen = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.exit_to_app_rounded),
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد إغلاق التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _isExitDialogOpen = false;
    if (shouldExit == true) await SystemNavigator.pop();
  }

  void _openTab(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _homeRefreshVersion++;
      if (index == 3) _duaInitialKind = 'dua';
    });
  }

  void _openAdhkar() {
    setState(() {
      _selectedIndex = 3;
      _duaInitialKind = 'adhkar';
    });
  }

  void _handleBackNavigation() {
    if (_selectedIndex != 0) {
      _openTab(0);
      return;
    }
    _confirmExit();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final theme = Theme.of(context);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBackNavigation();
      },
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: palette.primary,
            primaryContainer: palette.soft,
            secondary: palette.primary,
            surface: palette.surface,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: palette.background,
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeDashboard(
                  key: ValueKey(_homeRefreshVersion),
                  onOpenTab: _openTab,
                  onOpenAdhkar: _openAdhkar,
                ),
                const Qaurantab(),
                const HadithTab(),
                DuaTab(initialKind: _duaInitialKind),
                const SebhaTab(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              height: 70,
              backgroundColor: palette.surface,
              indicatorColor: palette.soft,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _openTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'القرآن',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books_rounded),
                  label: 'الحديث',
                ),
                NavigationDestination(
                  icon: Icon(Icons.volunteer_activism_outlined),
                  selectedIcon: Icon(Icons.volunteer_activism_rounded),
                  label: 'الدعاء',
                ),
                NavigationDestination(
                  icon: Icon(Icons.spa_outlined),
                  selectedIcon: Icon(Icons.spa_rounded),
                  label: 'التسبيح',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
