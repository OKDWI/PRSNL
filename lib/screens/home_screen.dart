import 'package:flutter/material.dart';
import '../widgets/background.dart'; // 🌟 Your modular background

import 'journal_home.dart'; // Echoes becomes JournalHomePage
import 'LibraryPage.dart';
import 'Companion.dart';
import 'ZenGardenPage.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  double tilesTopOffset = 0.20;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _rise;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rise = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BackgroundContainer(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                child: BackgroundHeader(),
              ),

              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  return Stack(
                    children: [
                      Positioned(
                        top: size.height * tilesTopOffset - _rise.value,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _fade.value,
                          child: Center(
                            child: SizedBox(
                              width: size.width * 0.88,
                              height: size.height * 0.70,
                              child: GridView(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                    ),
                                children: [
                                  _buildTile(
                                    title: "Echoes",
                                    image: "assets/echo.png",
                                    tint: Colors.yellow.shade200.withOpacity(
                                      0.7,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JournalHomePage(
                                          isDarkMode: widget.isDarkMode,
                                          onToggleTheme: widget.onToggleTheme,
                                          onOpenEditor:
                                              ({docId, title, content}) {
                                                debugPrint(
                                                  "onOpenEditor called",
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ),

                                  _buildTile(
                                    title: "Anonymous Library",
                                    image: "assets/anon.png",
                                    tint: Colors.grey.shade300.withOpacity(0.7),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PlaceholderPage(
                                          "Library Page",
                                        ),
                                      ),
                                    ),
                                  ),

                                  _buildTile(
                                    title: "Companion",
                                    image: "assets/ghost.png",
                                    tint: Colors.green.shade200.withOpacity(
                                      0.7,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PlaceholderPage(
                                          "Companion Page",
                                        ),
                                      ),
                                    ),
                                  ),

                                  _buildTile(
                                    title: "Zen Garden",
                                    image: "assets/zen.png",
                                    tint: Colors.lightBlue.shade200.withOpacity(
                                      0.7,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PlaceholderPage(
                                          "Zen Garden Page",
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // 🌟 Glassy Tile Builder
  // -----------------------------------------------------------------------
  Widget _buildTile({
    required String title,
    required String image,
    required Color? tint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: tint?.withOpacity(0.55),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(4, 6),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ---- ICON AS IMAGE ----
            Image.asset(image, height: 120, fit: BoxFit.contain),

            const SizedBox(height: 14),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// 🟪 Placeholder Pages — so navigation won't break
// -----------------------------------------------------------------------
class PlaceholderPage extends StatelessWidget {
  final String label;
  const PlaceholderPage(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          "$label — Coming soon",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
