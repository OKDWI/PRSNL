// lib/screens/echoes.dart
import 'package:flutter/material.dart';
import 'journal_home.dart';
import 'journal_entry_page.dart';

class EchoesWrapper extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  /// NEW: for Lumi click → open ProfilePage
  final VoidCallback? onLumiTap;

  const EchoesWrapper({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.onLumiTap, // ← NEW
  }) : super(key: key);

  @override
  State<EchoesWrapper> createState() => _EchoesWrapperState();
}

class _EchoesWrapperState extends State<EchoesWrapper> {
  /// Internal navigator key for Echoes section
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/":
            return MaterialPageRoute(
              builder: (_) => JournalHomePage(
                isDarkMode: widget.isDarkMode,
                onToggleTheme: widget.onToggleTheme,

                /// NEW: pass Lumi handler in
                onLumiTap: widget.onLumiTap,

                /// This callback replaces Navigator.push
                onOpenEditor:
                    ({String? docId, String? title, String? content}) {
                      _navKey.currentState!.pushNamed(
                        "/editor",
                        arguments: {
                          "docId": docId,
                          "title": title,
                          "content": content,
                        },
                      );
                    },
              ),
            );

          case "/editor":
            final args = settings.arguments as Map<String, dynamic>? ?? {};

            return MaterialPageRoute(
              builder: (_) => JournalEntryPage(
                isDarkMode: widget.isDarkMode,
                onToggleTheme: widget.onToggleTheme,
                docId: args["docId"],
                initialTitle: args["title"] ?? "",
                initialContent: args["content"] ?? "",
                onClose: () => _navKey.currentState!.pop(),
              ),
            );

          default:
            return null;
        }
      },
    );
  }
}
