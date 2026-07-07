import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/journal_editor.dart';
import '../widgets/background.dart';

class JournalEntryPage extends StatefulWidget {
  final String? docId;
  final String initialTitle;
  final String initialContent;

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  final VoidCallback onClose;

  const JournalEntryPage({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onClose,
    this.docId,
    this.initialTitle = "",
    this.initialContent = "",
  }) : super(key: key);

  @override
  _JournalEntryPageState createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  String? savedDocId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);

    savedDocId = widget.docId;
  }

  // ------------------- SAVE ENTRY -------------------
  Future<String> saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "";

    final data = {
      "uid": user.uid,
      "title": _titleController.text.trim(),
      "content": _contentController.text.trim(),
      "timestamp": DateTime.now(),
      "isPosted": false, // default
      "likedBy": [],
    };

    if (savedDocId == null) {
      final docRef = await FirebaseFirestore.instance
          .collection("journals")
          .add(data);
      savedDocId = docRef.id;
    } else {
      await FirebaseFirestore.instance
          .collection("journals")
          .doc(savedDocId)
          .update(data);
    }

    return savedDocId!;
  }

  // ------------------- POST LOGIC -------------------
  Future<void> postEntry() async {
    final id = await saveEntry(); // ensure entry exists
    if (id.isEmpty) return;

    // mark as posted
    await FirebaseFirestore.instance.collection("journals").doc(id).update({
      "isPosted": true,
      "postedTimestamp": DateTime.now(),
    });

    // confirmation message
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Posted Successfully!")));
    }

    // exit
    Navigator.pop(context);
  }

  // ------------------- FORMATTING -------------------
  void _applyFormat(String type) {
    final sel = _contentController.selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final full = _contentController.text;
    final selected = full.substring(sel.start, sel.end);

    String wrapped = selected;

    switch (type) {
      case "bold":
        wrapped = "$selected**";
        break;
      case "italic":
        wrapped = "$selected";
        break;
      case "underline":
        wrapped = "$selected";
        break;
    }

    final newText = full.replaceRange(sel.start, sel.end, wrapped);
    _contentController.text = newText;

    _contentController.selection = TextSelection.collapsed(
      offset: sel.start + wrapped.length,
    );
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
        Navigator.pop(context);
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
              heroTag: "saveBtn_editor",
              onPressed: () async {
                await saveEntry();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Saved Successfully!")),
                  );
                }
                Navigator.pop(context);
              },
              child: const Icon(Icons.save),
            ),
            const SizedBox(height: 16),

            FloatingActionButton(
              heroTag: "postBtn_editor",
              backgroundColor: Colors.orangeAccent,
              onPressed: postEntry,
              child: const Icon(Icons.send),
            ),
            const SizedBox(height: 16),

            FloatingActionButton(
              heroTag: "trayBtn_editor",
              onPressed: _openTray,
              child: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}
