// lib/screens/zengardenpage.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prsnl_final/screens/gardenscreen.dart';
import '../widgets/background.dart';
import '../utils/poisson.dart';

class ZenGardenPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final void Function(int)? onNavTap;

  /// NEW
  final VoidCallback? onLumiTap;

  const ZenGardenPage({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.onNavTap,
    this.onLumiTap, // NEW
  }) : super(key: key);

  @override
  State<ZenGardenPage> createState() => _ZenGardenPageState();
}

class _ZenGardenPageState extends State<ZenGardenPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Local UI state
  bool _loading = true;
  bool _plantedToday = false;
  late String _todayKey; // e.g. '2025-11-28'
  List<Map<String, dynamic>> _dailyTasks = []; // [{title, done}]
  List<Map<String, dynamic>> _userTasks = []; // [{id, title, done}]
  bool _hasInitialized = false;

  // NEW: plant growth stage + variant
  // stage: "plant", "plantling", "bud", "flower"
  String _todayStage = "plant";
  // variant examples: "", "bud1", "bud2", "bud3", "flower1", "flower2", "flower3"
  String _todayVariant = "";
  int? _todayIndex;

  // controllers
  final TextEditingController _taskController = TextEditingController();

  // Animation
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // default daily tasks (app-provided) - tweak as needed
  final List<String> _defaultTaskBank = [
    "Write 1 paragraph in journal",
    "Stretch for 5 minutes",
    "Drink a glass of water",
    "List 3 things you're grateful for",
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    final now = DateTime.now().toUtc();
    _todayKey =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    // load data
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _taskController.dispose();
    super.dispose();
  }

  // -----------------------
  // Firestore helpers
  // -----------------------
  Future<void> _initLoad() async {
    final user = _auth.currentUser;
    if (user == null) {
      // no user: show empty defaults (optional: navigate to auth)
      setState(() {
        _dailyTasks = _defaultTaskBank
            .map((t) => {"title": t, "done": false})
            .toList();
        _userTasks = [];
        _plantedToday = false;
        _todayStage = "plant";
        _todayVariant = "";
        _loading = false;
      });
      return;
    }

    final uid = user.uid;
    final dailyRef = _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('daily_state');
    final userTasksColl = _db
        .collection('users')
        .doc(uid)
        .collection('user_tasks');
    final gardenColl = _db.collection('users').doc(uid).collection('garden');

    try {
      // 1) Load daily_state; create for today if not present or outdated
      final dailySnap = await dailyRef.get();
      if (dailySnap.exists) {
        final data = dailySnap.data()!;
        final savedDate = data['date'] as String? ?? '';
        if (savedDate == _todayKey && data['tasks'] is List) {
          // reuse
          final tasksRaw = (data['tasks'] as List)
              .cast<Map<dynamic, dynamic>>();
          _dailyTasks = tasksRaw
              .map(
                (m) => {
                  "title": (m['title'] ?? '').toString(),
                  "done": (m['done'] ?? false) == true,
                },
              )
              .toList();
          _plantedToday = (data['planted'] ?? false) == true;
          _todayStage = (data['stage'] ?? "plant").toString();
          _todayVariant = (data['variant'] ?? "").toString();
          _todayIndex = data['variantIndex'];
        } else {
          // new day -> generate new tasks (optionally rotate from bank)
          // simple: take first 4 defaults (or random)
          _dailyTasks = _defaultTaskBank
              .map((t) => {"title": t, "done": false})
              .toList();
          _plantedToday = false;
          _todayStage = "plant";
          _todayVariant = "";

          // write back
          await dailyRef.set({
            "date": _todayKey,
            "tasks": _dailyTasks,
            "planted": false,
            "stage": _todayStage,
            "variantIndex": _todayIndex,
            "variant": _todayVariant,
            "updatedAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        // doc missing -> create
        _dailyTasks = _defaultTaskBank
            .map((t) => {"title": t, "done": false})
            .toList();
        _plantedToday = false;
        _todayStage = "plant";
        _todayVariant = "";
        await dailyRef.set({
          "date": _todayKey,
          "tasks": _dailyTasks,
          "planted": false,
          "stage": _todayStage,
          "variant": _todayVariant,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      // 2) load user tasks
      final utSnap = await userTasksColl
          .orderBy('createdAt', descending: true)
          .get();
      _userTasks = utSnap.docs.map((d) {
        final dd = d.data();
        return {
          "id": d.id,
          "title": dd['title'] ?? '',
          "done": dd['done'] ?? false,
        };
      }).toList();

      // 3) (optionally) check if garden has a doc for today (redundant because daily_state.planted covers it)
      // final plantedSnap = await gardenColl.where('date', isEqualTo: _todayKey).get();
      // _plantedToday = plantedSnap.docs.isNotEmpty || _plantedToday;

      setState(() {
        _loading = false;
        _hasInitialized = true;
      });
    } catch (e, st) {
      // log error and fallback to defaults
      // ignore print in production
      // ignore: avoid_print
      print("ZenGarden load error: $e\n$st");
      setState(() {
        _dailyTasks = _defaultTaskBank
            .map((t) => {"title": t, "done": false})
            .toList();
        _userTasks = [];
        _plantedToday = false;
        _todayStage = "plant";
        _todayVariant = "";
        _loading = false;
        _hasInitialized = true;
      });
    }
  }

  Future<void> _plantToday() async {
    // Called when user completes daily tasks and planting should occur
    // It will add a garden doc with the variant set (flower1/flower2/flower3)
    // and update daily_state.planted = true
    // DEBUG: keep prints for troubleshooting
    // ignore: avoid_print
    print("DEBUG: _plantToday() CALLED");
    final user = _auth.currentUser;
    if (user == null) return;

    final gardenColl = _db
        .collection('users')
        .doc(user.uid)
        .collection('garden');

    final dailyRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('daily_state');

    const double panelW = 1200;
    const double panelH = 300; // usable height

    try {
      // -----------------------------------------
      // Ensure variant is set to a flower variant
      // -----------------------------------------
      if (!_todayVariant.startsWith("flower")) {
        // If by chance variant wasn't set, pick a random flower
        final r = Random().nextInt(3) + 1;
        _todayVariant = "flower$r";
      }

      // -----------------------------------------
      // 1. Load existing flower positions (in px)
      // -----------------------------------------
      final existing = await gardenColl.get();
      final existingPx = existing.docs.map((d) {
        final data = d.data();
        final nx = (data['x'] ?? 0.5).toDouble();
        final ny = (data['y'] ?? 0.2).toDouble();
        return Offset(nx * panelW, ny * panelH);
      }).toList();

      // -----------------------------------------
      // 2. Create Poisson sampler (pixel space)
      // -----------------------------------------
      final sampler = PoissonDiskSampler(
        width: panelW,
        height: panelH,
        minDist: 34, // flower collision radius
        jitter: 6.0, // organic spacing
        k: 30,
        // optional noise:
        // noise: (nx, ny) => fallbackNoise(nx, ny, seed: 42),
      );

      final pts = sampler.sample(); // List<Point<double>> in px
      if (pts.isEmpty) {
        // ignore: avoid_print
        print("Poisson sampler returned no points.");
        return;
      }

      // -----------------------------------------
      // 3. Pick first non-colliding point
      // -----------------------------------------
      Point<double>? chosen;
      for (final p in pts) {
        bool ok = true;
        for (final e in existingPx) {
          if (Offset(p.x, p.y).distance < 34 + 1) {
            // +1 safety
            ok = false;
            break;
          }
        }
        if (ok) {
          chosen = p;
          break;
        }
      }

      // fallback if needed
      chosen ??= pts.first;

      // -----------------------------------------
      // 4. Normalize before saving
      // -----------------------------------------
      final nx = chosen.x / panelW;
      final ny = chosen.y / panelH;

      await gardenColl.add({
        "x": nx,
        "y": ny,
        // store the chosen variant as the type (flower1/flower2/flower3)
        "type": _todayVariant,
        "date": _todayKey,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _plantedToday = true;

      // write planted + stage + variant back to daily_state
      await dailyRef.set({
        "planted": true,
        "stage": _todayStage,
        "variant": _todayVariant,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print("Failed to plant today: $e");
    }
  }

  // -------------------------
  // user tasks (persistent)
  // -------------------------
  Future<void> _loadUserTasks() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final coll = _db.collection('users').doc(user.uid).collection('user_tasks');
    final snap = await coll.orderBy('createdAt', descending: true).get();
    _userTasks = snap.docs.map((d) {
      final dd = d.data();
      return {
        "id": d.id,
        "title": dd['title'] ?? '',
        "done": dd['done'] ?? false,
      };
    }).toList();
    setState(() {});
  }

  Future<void> _addUserTask(String title) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final coll = _db.collection('users').doc(user.uid).collection('user_tasks');
    final docRef = await coll.add({
      "title": title,
      "done": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
    _userTasks.insert(0, {"id": docRef.id, "title": title, "done": false});
    setState(() {});
  }

  Future<void> _editUserTask(String id, String title) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('user_tasks')
        .doc(id);
    await docRef.update({"title": title});
    final idx = _userTasks.indexWhere((t) => t['id'] == id);
    if (idx != -1) {
      _userTasks[idx]['title'] = title;
      setState(() {});
    }
  }

  Future<void> _toggleUserTask(String id, bool done) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('user_tasks')
        .doc(id);
    await docRef.update({"done": done});
    final idx = _userTasks.indexWhere((t) => t['id'] == id);
    if (idx != -1) {
      _userTasks[idx]['done'] = done;
      setState(() {});
    }
  }

  Future<void> _deleteUserTask(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('user_tasks')
        .doc(id);
    await docRef.delete();
    _userTasks.removeWhere((t) => t['id'] == id);
    setState(() {});
  }

  // -------------------------
  // Dialogs / helpers
  // -------------------------
  void _showAddUserTaskDialog() {
    _taskController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add thought"),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "What do you want to add?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final txt = _taskController.text.trim();
              if (txt.isNotEmpty) {
                _addUserTask(txt);
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditUserTaskDialog(Map<String, dynamic> task) {
    _taskController.text = task['title'] ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit thought"),
        content: TextField(controller: _taskController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final txt = _taskController.text.trim();
              if (txt.isNotEmpty) _editUserTask(task['id'], txt);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // UI helpers
  // -------------------------
  double get _dailyProgress {
    if (_dailyTasks.isEmpty) return 0.0;
    final done = _dailyTasks.where((t) => t['done'] == true).length;
    return done / _dailyTasks.length;
  }

  Widget _buildPlant(double progress) {
    // For now show a circular image with progress ring around it.
    final progressPct = (progress * 100).round();
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // ring
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: Colors.white.withOpacity(0.6),
                // color will adapt with theme
              ),
            ),

            // plant image (replace with stage images if you have them)
            ClipOval(
              child: Image.asset(
                _currentImageAsset(),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  print("DEBUG: Failed to load image: $error");
                  print("DEBUG STACK: $stack");
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.spa, size: 48),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "$progressPct% daily growth",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _currentImageAsset() {
    print("DEBUG: Stage = $_todayStage, Variant = $_todayVariant");

    // Determine file name
    String asset;

    switch (_todayStage) {
      case "plant":
        asset = "assets/plant.png";
        break;

      case "plantling":
        asset = "assets/plantling.png";
        break;

      case "bud":
        asset = "assets/${_todayVariant}.png";
        break;

      case "flower":
        asset = "assets/${_todayVariant}.png";
        break;

      default:
        asset = "assets/plant.png";
    }

    print("DEBUG: Attempting to load asset: $asset");

    return asset;
  }

  // persist daily_state to Firestore
  Future<void> _writeDailyState() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final dailyRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('daily_state');

    await dailyRef.set({
      "date": _todayKey,
      "tasks": _dailyTasks,
      "planted": _plantedToday,
      "stage": _todayStage,
      "variant": _todayVariant,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Determine stage + variant based on exact task counts (your requested mapping)
  void _updateStageFromTasks() {
    final done = _dailyTasks.where((t) => t['done'] == true).length;

    if (done == 0) {
      _todayStage = "plant";
      _todayVariant = "";
      _todayIndex = null;
      return;
    }

    if (done == 1) {
      _todayStage = "plantling";
      _todayVariant = "";
      _todayIndex = null;
      return;
    }

    // Choose index ONCE for the day
    if (_todayIndex == null) {
      _todayIndex = Random().nextInt(3) + 1;
    }

    if (done == 2) {
      _todayStage = "bud";
      _todayVariant = "bud$_todayIndex";
      return;
    }

    if (done >= 3) {
      _todayStage = "flower";
      _todayVariant = "flower$_todayIndex";
      return;
    }
  }

  // toggle a daily (app-provided) task and persist; if all complete, plant today
  Future<void> _toggleDailyTask(int index, bool value) async {
    if (index < 0 || index >= _dailyTasks.length) return;

    setState(() {
      _dailyTasks[index]['done'] = value;
    });

    // update stage based on exact task counts now
    _updateStageFromTasks();

    // persist new daily state (including stage/variant)
    await _writeDailyState();

    // if all done and haven't planted yet, plant
    final completedCount = _dailyTasks.where((t) => t['done'] == true).length;
    if (!_plantedToday &&
        _dailyTasks.isNotEmpty &&
        completedCount >= _dailyTasks.length) {
      await _plantToday();
    } else {
      // ensure UI updates to show new stage/variant
      setState(() {});
    }
  }

  // -------------------------
  // Build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackgroundContainer(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                // header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BackgroundHeader(onLumiTap: widget.onLumiTap),
                        const SizedBox(height: 12),
                        const Text(
                          "Zen Garden",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Plant + progress
                // Plant + progress (CLICKABLE → Opens the Garden)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.transparent,
                                body: Center(
                                  child: GardenScreen(
                                    isDarkMode: widget.isDarkMode,
                                    onToggleTheme: widget.onToggleTheme,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: _buildPlant(_dailyProgress),
                      ),
                    ),
                  ),
                ),

                // If planted today - info
                if (_plantedToday)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Center(
                        child: Text(
                          "Today's flower planted 🌸",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // DAILY TASKS title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text(
                      "Today's tasks",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // DAILY TASKS list
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (_loading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final t = _dailyTasks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Card(
                        color: Colors.white.withOpacity(0.92),
                        child: ListTile(
                          leading: Checkbox(
                            value: t['done'] == true,
                            onChanged: (v) =>
                                _toggleDailyTask(index, v ?? false),
                          ),
                          title: Text(t['title'] ?? ""),
                        ),
                      ),
                    );
                  }, childCount: _dailyTasks.length),
                ),

                // spacer
                SliverToBoxAdapter(child: const SizedBox(height: 12)),

                // USER TASKS title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: Text(
                      "Your thoughts",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // USER TASKS list
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final ut = _userTasks[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Card(
                        color: Colors.white.withOpacity(0.92),
                        child: ListTile(
                          leading: Checkbox(
                            value: ut['done'] == true,
                            onChanged: (v) =>
                                _toggleUserTask(ut['id'], v ?? false),
                          ),
                          title: Text(ut['title'] ?? ""),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditUserTaskDialog(ut),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteUserTask(ut['id']),
                              ),
                            ],
                          ),
                          onTap: () => _showEditUserTaskDialog(ut),
                        ),
                      ),
                    );
                  }, childCount: _userTasks.length),
                ),

                // bottom padding so FAB doesn't overlap
                SliverToBoxAdapter(child: const SizedBox(height: 88)),
              ],
            ),
          ),
        ),

        floatingActionButton: FloatingActionButton(
          heroTag: 'zenfab',
          onPressed: _showAddUserTaskDialog,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
