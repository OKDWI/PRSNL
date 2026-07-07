// lib/screens/gardenscreen.dart

import 'package:flutter/material.dart';
import 'package:prsnl_final/widgets/background.dart';
import 'package:prsnl_final/screens/garden.dart'; // GardenPanel

class GardenScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const GardenScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      isDarkMode: isDarkMode,
      onToggleTheme: onToggleTheme,
      overrideBackground: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  "Your Garden",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // FINAL FIX: No clipping. No shifting. Full visibility.
              Positioned(
                left: 0,
                right: 0,
                bottom: -50,
                child: Center(
                  child: GardenPanel(
                    isDarkMode: isDarkMode,
                    width: 1200,
                    height: 350,
                    usableHeight: 300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
