import 'package:flutter/material.dart';
import 'librarypage.dart';
import 'PostedEntryPage.dart';

class AnonymousLibraryWrapper extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AnonymousLibraryWrapper({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  State<AnonymousLibraryWrapper> createState() =>
      _AnonymousLibraryWrapperState();
}

class _AnonymousLibraryWrapperState extends State<AnonymousLibraryWrapper> {
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
              builder: (_) => AnonymousLibrary(
                /// When a tile is tapped, call this instead of Navigator.push()
                onOpenEntry: (entry) {
                  _navKey.currentState!.pushNamed("/posted", arguments: entry);
                },
              ),
            );

          case "/posted":
            final args = settings.arguments as Map<String, dynamic>? ?? {};

            return MaterialPageRoute(
              builder: (_) => PostedEntryPage(
                docId: args["docId"],
                title: args["title"] ?? "",
                content: args["content"] ?? "",
                isDarkMode: widget.isDarkMode,
                onToggleTheme: widget.onToggleTheme,
              ),
            );

          default:
            return null;
        }
      },
    );
  }
}
