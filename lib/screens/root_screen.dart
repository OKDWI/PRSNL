// lib/screens/root_screen.dart

import 'package:flutter/material.dart';
import 'package:prsnl_final/screens/chat_screen.dart';
import '../widgets/background.dart';
import 'package:prsnl_final/navbar.dart';
import 'zengardenpage.dart';
import 'LibraryPage.dart';
import 'echoes.dart';
import 'home_screen.dart';
import 'journal_home.dart';
import 'profile_screen.dart';   // ← NEW
import 'anonymous_library.dart';
class RootScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const RootScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  // Allows any child page to call: RootScreen.of(context).jumpToTab(index)
  static _RootScreenState of(BuildContext context) {
    return context.findAncestorStateOfType<_RootScreenState>()!;
  }

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  // --------------------- TAB SWITCHING ----------------------
  void jumpToTab(int index) {
    setState(() => _index = index);
  }

  void _onNavTap(int i) {
    setState(() => _index = i);
  }

  // ------------------ OPEN PROFILE PAGE ---------------------
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  // ------------------------- PAGES --------------------------
  List<Widget> get _pages => [
        // 0 → Home
        HomePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
          onOpenTab: jumpToTab,
          onLumiTap: _openProfile,
        ),

        // 1 → Echoes
        EchoesWrapper(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
          onLumiTap: _openProfile,
        ),

        // 2 → Library / Anonymous Library
        AnonymousLibraryWrapper(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),

        // 3 → Companion Chat
        CompanionPage(),

        // 4 → Zen Garden
        ZenGardenPage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
          onNavTap: jumpToTab,
          onLumiTap: _openProfile,
        ),
      ];

  // ------------------------ BACK BUTTON ---------------------
  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  // ------------------------- UI BUILD ------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar:
            MyNavBar(selectedIndex: _index, onTap: _onNavTap),
      ),
    );
  }
}
