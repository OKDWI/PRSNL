import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../navbar.dart';

class ZenGardenPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Function(int) onNavTap;

  const ZenGardenPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onNavTap,
  });

  @override
  State<ZenGardenPage> createState() => _ZenGardenPageState();
}

class _ZenGardenPageState extends State<ZenGardenPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController taskController = TextEditingController();
  final List<Map<String, dynamic>> tasks = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Add Thought
  void _addThought() {
    taskController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Plant a Thought 🌱"),
        content: TextField(
          controller: taskController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "What would you like to nurture today?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskController.text.trim().isNotEmpty) {
                setState(() {
                  tasks.add({
                    "title": taskController.text.trim(),
                    "done": false,
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Edit Thought
  void _editThought(int index) {
    taskController.text = tasks[index]["title"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Edit Thought"),
        content: TextField(
          controller: taskController,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                tasks[index]["title"] = taskController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return BackgroundContainer(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,

        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: BackgroundHeader(),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Zen Garden",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 20),

                // --- Circle Plant Image ---
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        spreadRadius: 4,
                        color: Colors.black.withOpacity(0.25),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/plant.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Tend to your thoughts 🌸",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 20),

                // --- Task List ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: tasks.isEmpty
                        ? Center(
                            child: Text(
                              "Your garden is quiet.\nPlant your first thought.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final t = tasks[index];

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.55),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 12,
                                      offset: const Offset(4, 6),
                                      color:
                                          Colors.black.withOpacity(0.12),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _editThought(index),
                                        child: Text(
                                          t["title"],
                                          style: TextStyle(
                                            fontSize: 16,
                                            decoration:
                                                t["done"] == true
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                            color: isDark
                                                ? Colors.black87
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: t["done"],
                                      onChanged: (v) {
                                        setState(() => t["done"] = v);
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: isDark
              ? const Color(0xFF2E4466)
              : const Color(0xFF8797F1),
          onPressed: _addThought,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}
