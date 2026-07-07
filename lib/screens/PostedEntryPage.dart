import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/journal_editor.dart';
import '../widgets/background.dart';

class PostedEntryPage extends StatefulWidget {
  final String docId;
  final String title;
  final String content;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const PostedEntryPage({
    super.key,
    required this.docId,
    required this.title,
    required this.content,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<PostedEntryPage> createState() => _PostedEntryPageState();
}

class _PostedEntryPageState extends State<PostedEntryPage> {
  bool hasRelated = false;

  @override
  void initState() {
    super.initState();
    checkIfUserRelated();
  }

  Future<void> checkIfUserRelated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("journals")
        .doc(widget.docId)
        .get();

    final list = List<String>.from(snap["likedBy"] ?? []);

    setState(() {
      hasRelated = list.contains(user.uid);
    });
  }

  Future<void> relateEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || hasRelated) return;

    await FirebaseFirestore.instance
        .collection("journals")
        .doc(widget.docId)
        .update({
          "likedBy": FieldValue.arrayUnion([user.uid]),
        });

    setState(() => hasRelated = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You related to this entry ❤")),
      );

      // Wait 600ms for user to see animation, then go back
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController(text: widget.title);
    final contentCtrl = TextEditingController(text: widget.content);

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
                  titleCtrl: titleCtrl,
                  contentCtrl: contentCtrl,
                  // readOnly: true, // ⛔ not editable
                ),
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: hasRelated ? null : relateEntry,
          backgroundColor: hasRelated ? Colors.grey : Colors.pinkAccent,
          icon: const Icon(Icons.favorite),
          label: Text(hasRelated ? "Related ❤" : "Relate"),
        ),
      ),
    );
  }
}
