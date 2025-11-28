import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF23304F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, value, child) {
              // value goes from 0 → 1 smoothly

              final sway = (1 - value) * 20; // left-right drift
              final twist = (1 - value) * 0.20; // rotation (in radians)
              final scale = 0.6 + (value * 0.4); // grow from 0.6 → 1.0

              return Opacity(
                opacity: value, // fade-in
                child: Transform.translate(
                  offset: Offset(
                    sway,
                    (1 - value) * 15,
                  ), // slight drift down too
                  child: Transform.rotate(
                    angle: twist, // twist in
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              );
            },
            child: Image.asset(
              "assets/ghost.png",
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
