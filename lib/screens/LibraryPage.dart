import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'PostedEntryPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnonymousLibrary extends StatefulWidget {
  final void Function(Map<String, dynamic> entry)? onOpenEntry;

  const AnonymousLibrary({super.key, this.onOpenEntry});

  @override
  State<AnonymousLibrary> createState() => _AnonymousLibraryState();
}

class _AnonymousLibraryState extends State<AnonymousLibrary> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// ALWAYS BEHIND
          Positioned.fill(
            child: Image.asset(
              isDarkMode ? "assets/bg_night.png" : "assets/bg_day.png",
              fit: BoxFit.cover,
            ),
          ),

          /// FOREGROUND CONTENT
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  /// Theme Toggle
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => setState(() => isDarkMode = !isDarkMode),
                      child: Container(
                        margin: const EdgeInsets.only(right: 20, top: 10),
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFFFFD645),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Anonymous Library",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF315177),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// LIST OF POSTED ENTRIES
                  Expanded(child: _buildPostedEntries()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 Stream of posted entries
  Widget _buildPostedEntries() {
    // ... (Your _buildHeartIcon method is fine, no change needed here)
    Widget _buildHeartIcon(DocumentSnapshot doc) {
      final List likedBy = doc["likedBy"] ?? [];
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null && likedBy.contains(userId)) {
        return const Icon(Icons.favorite, color: Colors.redAccent, size: 26);
      } else {
        return const SizedBox(); // no icon
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("journals")
          .where("isPosted", isEqualTo: true)
          .orderBy("postedTimestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No anonymous entries yet.",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 18,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        final List<Color> lightCardColors = [
          const Color(0xFFFFF8B0).withOpacity(0.5),
          const Color(0xFFD7E3F4).withOpacity(0.5),
          const Color(0xFFFFD2A5).withOpacity(0.5),
          const Color(0xFFCCE4FF).withOpacity(0.5),
        ];

        final List<Color> darkCardColors = [
          const Color(0xFF3B3B3B).withOpacity(0.5),
          const Color(0xFF4D4D4D).withOpacity(0.5),
          const Color(0xFF5C3D3D).withOpacity(0.5),
          const Color(0xFF314458).withOpacity(0.5),
        ];

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final title = doc["title"] ?? "Untitled";
            final content = doc["content"] ?? "";
            final docId = doc.id;

            final cardColor = isDarkMode
                ? darkCardColors[index % darkCardColors.length]
                : lightCardColors[index % lightCardColors.length];

            return GestureDetector(
              onTap: () {
                // 1. **CREATE THE ENTRY MAP**
                final Map<String, dynamic> entryData = {
                  "docId": docId,
                  "title": title,
                  "content": content,
                  // Pass current theme status if PostedEntryPage relies on it
                  "isDarkMode": isDarkMode,
                  // Any other data PostedEntryPage needs...
                };

                // 2. **CHECK AND USE THE CALLBACK**
                if (widget.onOpenEntry != null) {
                  // If a callback is provided (e.g., from the parent widget using Navigator.pushNamed)
                  widget.onOpenEntry!(entryData);
                } else {
                  // If no callback is provided, fall back to local Navigator.push
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostedEntryPage(
                        docId: docId,
                        title: title,
                        content: content,
                        isDarkMode: isDarkMode, // **REQUIRED ARGUMENT ADDED**
                        onToggleTheme: () => setState(
                          () => isDarkMode = !isDarkMode,
                        ), // **REQUIRED ARGUMENT ADDED**
                      ),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ... (Title and Heart Icon code is fine)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF2C446A),
                          ),
                        ),
                      ),
                    ),
                    Positioned(right: 10, top: 10, child: _buildHeartIcon(doc)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
