import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;
  final VoidCallback onToggleTheme;

  // NEW: simple background override toggle
  final bool overrideBackground;

  const BackgroundContainer({
    Key? key,
    required this.isDarkMode,
    required this.child,
    required this.onToggleTheme,
    this.overrideBackground = false,     // 👈 default = normal behavior
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('BackgroundContainer.build — isDarkMode=$isDarkMode');

    return Stack(
      children: [
        // ---------- BACKGROUND IMAGE ----------
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: _buildBackgroundImage(),
          ),
        ),

        Positioned.fill(child: child),

        // ---------- SUN / MOON (HIDDEN IF OVERRIDDEN) ----------
        if (!overrideBackground)
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: onToggleTheme,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.grey.shade200.withOpacity(0.4)
                      : Colors.yellowAccent.withOpacity(0.6),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.blueGrey.withOpacity(0.4)
                          : Colors.orange.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------- DECIDE BACKGROUND ----------
  Widget _buildBackgroundImage() {
    // If override is ON, ALWAYS use bg_wood.png
    final backgroundAsset = overrideBackground
        ? "assets/bg_wood.png"
        : (isDarkMode ? "assets/bg_night.png" : "assets/bg_day.png");

    print('Background image chosen: $backgroundAsset');

    return Image.asset(
      backgroundAsset,
      key: ValueKey(backgroundAsset),
      fit: BoxFit.cover,
      gaplessPlayback: false,
    );
  }
}

class BackgroundHeader extends StatelessWidget {
  final bool overrideBackground;
  const BackgroundHeader({Key? key,  this.overrideBackground = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(overrideBackground);
    if (!overrideBackground) {
    return Row(
      children: [
        Image.asset("assets/ghost.png", height: 40),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "Prsnl",
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 52),
      ],
    );}
    else {
    return SizedBox.shrink();
    }
  }
}
