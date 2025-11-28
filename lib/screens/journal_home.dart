// lib/screens/journal_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../widgets/background.dart';

class JournalHomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  /// NEW: RootScreen callback
  final void Function({
    String? docId,
    String? title,
    String? content,
  }) onOpenEditor;

  const JournalHomePage({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenEditor,
  }) : super(key: key);

  @override
  State<JournalHomePage> createState() => _JournalHomePageState();
}

class _JournalHomePageState extends State<JournalHomePage> {
  final user = FirebaseAuth.instance.currentUser;

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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: BackgroundHeader(),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("journals")
                      .where("uid", isEqualTo: user?.uid)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading entries"));
                    }

                    if (!snapshot.hasData ||
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No journal entries yet",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final title = data["title"] ?? "";
                        final content = data["content"] ?? "";
                        final timestamp = data["timestamp"] as Timestamp?;
                        final dateStr = timestamp != null
                            ? DateFormat.yMMMd()
                                .add_jm()
                                .format(timestamp.toDate())
                            : "";

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: Colors.white.withOpacity(0.85),
                          elevation: 3,
                          child: ListTile(
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.length > 50
                                      ? "${content.substring(0, 50)}..."
                                      : content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            // NEW: no Navigator.push
                            onTap: () {
                              widget.onOpenEditor(
                                docId: doc.id,
                                title: title,
                                content: content,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text("Logout"),
                ),
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          // NEW: no Navigator.push
          onPressed: () {
            widget.onOpenEditor(
              docId: null,
              title: "",
              content: "",
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
