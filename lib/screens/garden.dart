// lib/screens/garden.dart - FINAL CLEAN VERSION

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GardenPanel extends StatefulWidget {
  final bool isDarkMode;
  final double width;
  final double height;
  final double usableHeight;
  final Color lightInner;
  final Color lightOuter;
  final Color darkInner;
  final Color darkOuter;

  const GardenPanel({
    Key? key,
    required this.isDarkMode,
    this.width = 1200,
    this.height = 350,
    this.usableHeight = 300,
    this.lightInner = const Color(0xFF49F05D),
    this.lightOuter = const Color(0xFF2A8A35),
    this.darkInner = const Color(0xFF1C6D31),
    this.darkOuter = const Color(0xFF17421C),
  }) : super(key: key);

  @override
  State<GardenPanel> createState() => _GardenPanelState();
}

// Wrapper to manage the stream connection (renamed back to original class)
class _GardenPanelState extends State<GardenPanel> {
  Stream<QuerySnapshot>? _plantsStream;
  User? _user;

  // Keeping original state fields, though they're not used in this simplified version
  final Map<String, bool> _visible = {};
  static const double _flowerSize = 102;
  static const double _flowerHalfSize = _flowerSize / 2;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      _plantsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('garden')
          .orderBy('createdAt', descending: false)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    // We keep LayoutBuilder to ensure flower positioning is always correct
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualRenderWidth = constraints.maxWidth;

        return SizedBox(
          width: actualRenderWidth,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Background painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GardenBackgroundPainter(
                        dark: widget.isDarkMode,
                        lightInner: widget.lightInner,
                        lightOuter: widget.lightOuter,
                        darkInner: widget.darkInner,
                        darkOuter: widget.darkOuter,
                      ),
                    ),
                  ),

                  // Fixed-size overlay that contains flowers
                  Positioned.fill(
                    child: Center(
                      child: _user == null
                          ? const Center(child: Text("Please sign in"))
                          : StreamBuilder<QuerySnapshot>(
                              stream: _plantsStream,
                              builder: (context, snap) {
                                if (snap.hasError) {
                                  return const Center(
                                    child: Text('Error loading garden'),
                                  );
                                }

                                if (!snap.hasData || snap.data!.docs.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final docs = snap.data!.docs;

                                // Re-introducing animation logic placeholder without Ticker
                                final presentIds = docs
                                    .map((d) => d.id)
                                    .toSet();
                                _visible.keys
                                    .where((k) => !presentIds.contains(k))
                                    .toList()
                                  ..forEach((k) => _visible.remove(k));

                                for (int i = 0; i < docs.length; i++) {
                                  final id = docs[i].id;
                                  if (_visible[id] != true) {
                                    // Use a minimal delay before showing it as 'appeared'
                                    Timer(
                                      const Duration(milliseconds: 150),
                                      () {
                                        if (mounted)
                                          setState(() => _visible[id] = true);
                                      },
                                    );
                                  }
                                }

                                // Build flowers positioned absolutely
                                return Stack(
                                  children: docs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final nx = (data['x'] is num)
                                        ? (data['x'] as num).toDouble()
                                        : 0.5;
                                    final ny = (data['y'] is num)
                                        ? (data['y'] as num).toDouble()
                                        : 0.0;

                                    final cx = nx.clamp(0.0, 1.0);
                                    final cy = ny.clamp(0.0, 1.0);

                                    // Corrected positioning logic
                                    final px = (cx * actualRenderWidth);
                                    final py = (cy * widget.usableHeight);

                                    final leftPos = px - _flowerHalfSize;
                                    final topPos = py - _flowerSize + 4;
                                    final appeared = _visible[doc.id] == true;

                                    return Positioned(
                                      key: ValueKey(doc.id),
                                      left: leftPos,
                                      top: topPos,
                                      child: _FlowerWidget(
                                        // Renamed to a generic final widget
                                        asset: 'assets/${data["type"]}.png',
                                        appeared: appeared,
                                        flowerSize: _flowerSize,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// -------------------------------
/// 1. FINAL FLOWER WIDGET (Restores Animation/Image Capability)
/// -------------------------------
class _FlowerWidget extends StatelessWidget {
  final String asset;
  final bool appeared;
  final double flowerSize;

  const _FlowerWidget({
    Key? key,
    required this.asset,
    required this.appeared,
    required this.flowerSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is where you would re-introduce your fade/scale animation
    // using a proper animation library or StatefulWidget if needed.
    // For now, it simply displays the image asset and respects the 'appeared' flag for instant display.
    return Opacity(
      opacity: appeared ? 1.0 : 0.0, // Instantly show/hide based on flag
      child: SizedBox(
        width: flowerSize,
        height: flowerSize,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}

/// -------------------------------
/// 2. GARDEN BACKGROUND PAINTER (UNCHANGED)
/// -------------------------------
class _GardenBackgroundPainter extends CustomPainter {
  final bool dark;
  final Color lightInner;
  final Color lightOuter;
  final Color darkInner;
  final Color darkOuter;

  _GardenBackgroundPainter({
    required this.dark,
    required this.lightInner,
    required this.lightOuter,
    required this.darkInner,
    required this.darkOuter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(57.5),
    );

    final paint = Paint()
      ..shader =
          RadialGradient(
            center: const Alignment(-0.2, -0.6),
            radius: 1.0,
            colors: dark ? [darkInner, darkOuter] : [lightInner, lightOuter],
            stops: const [0.0, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.45, size.height * 0.25),
              radius: max(size.width, size.height),
            ),
          );

    canvas.drawRRect(rrect, paint);

    // subtle inner highlight
    final overlay = Paint()
      ..color = Colors.white.withOpacity(dark ? 0.02 : 0.06)
      ..blendMode = BlendMode.softLight;
    canvas.drawRRect(rrect, overlay);
  }

  @override
  bool shouldRepaint(covariant _GardenBackgroundPainter old) {
    return old.dark != dark ||
        old.lightInner != lightInner ||
        old.darkInner != darkInner;
  }
}

/// -------------------------------
/// 3. POISSON-DISK SAMPLER (UNCHANGED)
/// -------------------------------
List<Offset> poissonDiskSampling({
  required double width,
  required double height,
  required double minDistance,
  int k = 30,
  Random? rng,
}) {
  rng ??= Random();
  final cellSize = minDistance / sqrt2;
  final nx = (width / cellSize).ceil();
  final ny = (height / cellSize).ceil();
  final grid = List.generate(nx * ny, (_) => <Offset>[]);
  final List<Offset> samples = [];
  final List<Offset> active = [];

  Offset randomPoint() =>
      Offset(rng!.nextDouble() * width, rng!.nextDouble() * height);

  final first = randomPoint();
  samples.add(first);
  active.add(first);
  grid[(first.dx ~/ cellSize) + (first.dy ~/ cellSize) * nx].add(first);

  while (active.isNotEmpty) {
    final idx = rng.nextInt(active.length);
    final point = active[idx];
    var found = false;
    for (var i = 0; i < k; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final r = minDistance * (1 + rng.nextDouble());
      final cand = Offset(point.dx + r * cos(a), point.dy + r * sin(a));
      if (cand.dx < 0 || cand.dx >= width || cand.dy < 0 || cand.dy >= height)
        continue;

      final gx = (cand.dx ~/ cellSize).toInt();
      final gy = (cand.dy ~/ cellSize).toInt();
      var ok = true;
      for (var ox = max(0, gx - 2); ox <= min(nx - 1, gx + 2); ox++) {
        for (var oy = max(0, gy - 2); oy <= min(ny - 1, gy + 2); oy++) {
          final cell = grid[ox + oy * nx];
          for (final s in cell) {
            if ((s - cand).distance < minDistance) {
              ok = false;
              break;
            }
          }
          if (!ok) break;
        }
        if (!ok) break;
      }
      if (ok) {
        samples.add(cand);
        active.add(cand);
        grid[gx + gy * nx].add(cand);
        found = true;
        break;
      }
    }
    if (!found) {
      active.removeAt(idx);
    }
  }

  // normalize to 0..1
  return samples.map((p) => Offset(p.dx / width, p.dy / height)).toList();
}
