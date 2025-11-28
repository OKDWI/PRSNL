import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prsnl_final/navbar.dart';
import 'package:prsnl_final/screens/journal_home.dart';
import '../ui/journal_editor.dart'; // ← NEW
import '../widgets/background.dart'; // ← Modular background

class JournalEntryPage extends StatefulWidget {
  final String? docId;
  final String? initialTitle;
  final String? initialContent;

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Function(int) onTabChange;

  const JournalEntryPage({
    Key? key,
    this.docId,
    this.initialTitle,
    this.initialContent,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onTabChange,
  }) : super(key: key);

  @override
  _JournalEntryPageState createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? "");
    _contentController = TextEditingController(
      text: widget.initialContent ?? "",
    );
  }

  @override
  void didUpdateWidget(covariant JournalEntryPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {}); // rebuild when theme changes
    }
  }

  Future<void> saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = {
      "uid": user.uid,
      "title": _titleController.text,
      "content": _contentController.text,
      "timestamp": DateTime.now(),
    };

    if (widget.docId == null) {
      await FirebaseFirestore.instance.collection("journals").add(data);
    } else {
      await FirebaseFirestore.instance
          .collection("journals")
          .doc(widget.docId)
          .update(data);
    }

    Navigator.pop(context);
  }

  void _onNavTap(int index) {
    widget.onTabChange(index);
  }

  void _openTray() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildTrayMenu(),
    );
  }

  Widget _buildTrayMenu() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _trayButton("B", () => _applyFormat("bold")),
          _trayButton("U", () => _applyFormat("underline")),
          _trayButton("I", () => _applyFormat("italic")),
        ],
      ),
    );
  }

  Widget _trayButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close tray
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade300,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _applyFormat(String type) {
    final sel = _contentController.selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final full = _contentController.text;
    final selected = full.substring(sel.start, sel.end);

    String wrapped = selected;

    switch (type) {
      case "bold":
        wrapped = "**$selected**";
        break;
      case "underline":
        wrapped = "__$selected\_\_";
        break;
      case "italic":
        wrapped = "*$selected*";
        break;
    }

    final newText = full.replaceRange(sel.start, sel.end, wrapped);
    _contentController.text = newText;

    // Move cursor after inserted formatting
    _contentController.selection = TextSelection.collapsed(
      offset: sel.start + wrapped.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: BackgroundHeader(),
              ),

              const SizedBox(height: 10),

              // ← THE EDITOR UI NOW LIVES IN ITS OWN FILE
              Expanded(
                child: JournalEditor(
                  titleCtrl: _titleController,
                  contentCtrl: _contentController,
                ),
              ),
            ],
          ),
        ),

        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "saveBtn",
              onPressed: saveEntry,
              child: const Icon(Icons.save),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: "trayBtn",
              onPressed: _openTray,
              child: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}
