// lib/utils/poisson.dart
//
// Poisson-disk sampler (Bridson) tuned for placing non-overlapping
// objects (flowers) inside a rectangle. Includes a tiny noise function
// for weighting placement probability without extra dependencies.
//
// Usage example:
//
// final sampler = PoissonDiskSampler(
//   width: 195,
//   height: 150,
//   minDist: 40,     // desired spacing in pixels (flower diameter or spacing)
//   jitter: 6.0,
//   k: 30,
//   noise: (nx, ny) => fallbackNoise(nx * 2.0, ny * 2.0, seed: 42),
// );
//
// final points = sampler.sample(); // List<Point<double>> in pixel coords
// final normalized = points.map((p) => Point(p.x/width, p.y/height)).toList();

import 'dart:math';

/// Simple value-noise-like fallback to bias placement probability.
///
/// nx, ny expected in range [0..1]. Returns a value 0..1.
/// Deterministic if seed provided.
double fallbackNoise(double nx, double ny, {int seed = 0}) {
  // small deterministic hash-ish mix of coordinates
  // not Perlin, but gives organic variation without external packages.
  final a = (nx * 127.1 + ny * 311.7 + seed * 0.00001);
  final b = (nx * 269.5 + ny * 183.3 + seed * 0.00002);
  final s = sin(a) * 43758.5453 + cos(b) * 789221.123;
  final frac = s - s.floor();
  return frac.abs().clamp(0.0, 1.0);
}

/// A small container for sampler results (optional).
class SamplerResult {
  final List<Point<double>> points;
  SamplerResult(this.points);
}

/// Poisson-disk sampler implementation (Bridson).
///
/// - width, height: region size in pixels
/// - minDist: base minimum distance between points (px)
/// - jitter: +/- jitter applied to minDist to make spacing organic
/// - k: number of tries per active sample
/// - noise: optional weighting function (nx, ny) -> 0..1 (normalized coords)
class PoissonDiskSampler {
  final double width;
  final double height;
  final double minDist;
  final double jitter;
  final int k;
  final double placementThreshold; // 0..1 - base cutoff if using noise
  final double _eps = 1e-9;
  final double _minAllowedDist = 6.0; // safety clamp
  final Random _rand;

  /// noise: function receiving normalized coords (0..1) and returning weight 0..1.
  final double Function(double nx, double ny)? noise;

  PoissonDiskSampler({
    required this.width,
    required this.height,
    required this.minDist,
    this.jitter = 6.0,
    this.k = 30,
    this.noise,
    this.placementThreshold = 0.08,
    int? seed, // optional for deterministic runs
  }) : _rand = (seed == null) ? Random() : Random(seed);

  /// Primary sampling function. Returns a list of Points in pixel coordinates.
  List<Point<double>> sample() {
    if (width <= 0 || height <= 0) return <Point<double>>[];

    // cell size for acceleration grid: use (minDist - jitter) / sqrt(2) to ensure neighborhood checks cover enough
    final effectiveMin = (minDist - jitter).abs().clamp(_minAllowedDist, minDist + jitter);
    final cellSize = max(effectiveMin / sqrt(2), 1.0);

    final gridW = (width / cellSize).ceil();
    final gridH = (height / cellSize).ceil();
    final grid = List<Point<double>?>.filled(gridW * gridH, null);

    Point<int> gridIndexFromPoint(Point<double> p) {
      final gx = (p.x / cellSize).floor().clamp(0, gridW - 1);
      final gy = (p.y / cellSize).floor().clamp(0, gridH - 1);
      return Point<int>(gx, gy);
    }

    bool farFromNeighbors(Point<double> point, double localMinDist) {
      final idx = gridIndexFromPoint(point);
      final gx = idx.x, gy = idx.y;
      final minCellX = max(0, gx - 2);
      final maxCellX = min(gridW - 1, gx + 2);
      final minCellY = max(0, gy - 2);
      final maxCellY = min(gridH - 1, gy + 2);

      final minR2 = localMinDist * localMinDist;
      for (var x = minCellX; x <= maxCellX; x++) {
        for (var y = minCellY; y <= maxCellY; y++) {
          final other = grid[x + y * gridW];
          if (other == null) continue;
          final dx = other.x - point.x;
          final dy = other.y - point.y;
          if (dx * dx + dy * dy < minR2 - _eps) {
            return false;
          }
        }
      }
      return true;
    }

    // local minDist with jitter
    double localMinDist() {
      final j = (_rand.nextDouble() * 2 - 1) * jitter; // -j..+j
      final val = (minDist + j).clamp(_minAllowedDist, minDist + jitter);
      return val;
    }

    final samples = <Point<double>>[];
    final active = <Point<double>>[];

    // Seed with several random attempts until one passes noise check (to avoid empty)
    for (int attempt = 0; attempt < 40 && samples.isEmpty; attempt++) {
      final p = Point(_rand.nextDouble() * width, _rand.nextDouble() * height);
      if (_passesNoise(p)) {
        samples.add(p);
        active.add(p);
        final gi = gridIndexFromPoint(p);
        grid[gi.x + gi.y * gridW] = p;
      }
    }

    // If still empty, force a non-noise seed so sampling can proceed
    if (samples.isEmpty) {
      final p = Point(width / 2.0, height / 2.0);
      samples.add(p);
      active.add(p);
      final gi = gridIndexFromPoint(p);
      grid[gi.x + gi.y * gridW] = p;
    }

    while (active.isNotEmpty) {
      final aIndex = _rand.nextInt(active.length);
      final a = active[aIndex];

      var placed = false;
      final lm = localMinDist();

      for (int i = 0; i < k; i++) {
        // sample in annulus [lm .. 2*lm]
        final angle = _rand.nextDouble() * 2 * pi;
        final rr = lm * (1.0 + _rand.nextDouble()); // radius between lm and 2*lm
        final nx = a.x + rr * cos(angle);
        final ny = a.y + rr * sin(angle);

        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;

        final np = Point<double>(nx, ny);

        if (!_passesNoise(np)) continue;

        if (!farFromNeighbors(np, lm)) continue;

        // accept
        samples.add(np);
        active.add(np);
        final gi = gridIndexFromPoint(np);
        grid[gi.x + gi.y * gridW] = np;
        placed = true;
        break;
      }

      if (!placed) {
        active.removeAt(aIndex);
      }
    }

    return samples;
  }

  /// Convenience: returns a single normalized point (x:0..1, y:0..1)
  /// picked from the sampler's results; returns null if none produced.
  Point<double>? pickNormalizedPoint({int tries = 3}) {
    final pts = sample();
    if (pts.isEmpty) return null;

    // pick a random point from generated ones (optionally try to return central)
    final idx = _rand.nextInt(pts.length);
    final p = pts[idx];
    return Point<double>(p.x / width, p.y / height);
  }

  // weight check based on provided noise function (if any)
  bool _passesNoise(Point<double> p) {
    if (noise == null) return true;
    final nx = (p.x / width).clamp(0.0, 1.0);
    final ny = (p.y / height).clamp(0.0, 1.0);
    final w = noise!(nx, ny).clamp(0.0, 1.0);

    // small base threshold to avoid too aggressive rejection on low noise fields.
    final threshold = placementThreshold;
    return _rand.nextDouble() <= (threshold + (1.0 - threshold) * w);
  }
}
