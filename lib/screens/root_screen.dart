// lib/screens/root_screen.dart

import 'package:flutter/material.dart';
import 'package:prsnl_final/screens/chat_screen.dart';
import '../widgets/background.dart';
import 'package:prsnl_final/navbar.dart';
import 'zengardenpage.dart';


import 'home_screen.dart';
import 'journal_home.dart';

class RootScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const RootScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  // editor arguments
  String? _editorDocId;
  String? _editorTitle;
  String? _editorContent;

  void _openEditor({String? docId, String? title, String? content}) {
    setState(() {
      _editorDocId = docId;
      _editorTitle = title;
      _editorContent = content;
      _index = 2; // NEW: Editor moved to index 2
    });
  }

  void _clearEditorArgs() {
    _editorDocId = null;
    _editorTitle = null;
    _editorContent = null;
  }

  void _onNavTap(int i) {
    setState(() => _index = i);
  }

  // ---------------------------- PAGE ORDER ----------------------------
  // 0 → HomePage
  // 1 → JournalHome (Echoes)
  // 2 → Editor
  // --------------------------------------------------------------------
  // pages array — using builders so we can pass latest editor args
  List<Widget> get _pages => [
    // 0 → Home Screen
    HomePage(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
    ),

    // 1 → Journal (Echoes)
    JournalHomePage(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      onOpenEditor: ({String? docId, String? title, String? content}) {
        _openEditor(docId: docId, title: title, content: content);
      },
    ),

    const Placeholder(),

    // 2 → Companion Chat Screen (NEW)
    CompanionPage(),

    ZenGardenPage(
    isDarkMode: widget.isDarkMode,
    onToggleTheme: widget.onToggleTheme,
    onNavTap: _onNavTap,
  ),
  ];

  // -------------------------- ANDROID BACK BEHAVIOR --------------------
  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0); // go to HomePage
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent, // pages provide background
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: MyNavBar(selectedIndex: _index, onTap: _onNavTap),
      ),
    );
  }
}
