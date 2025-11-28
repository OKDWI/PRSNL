// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/firestore_service.dart';

// class JournalListPage extends StatelessWidget {
//   final FirestoreService _firestoreService = FirestoreService();

//   JournalListPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestoreService.getJournalEntries(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final entries = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: entries.length,
//             itemBuilder: (context, index) {
//               final entry = entries[index];
//               return ListTile(
//                 title: Text(entry['title'] ?? ''),
//                 subtitle: Text(entry['content'] ?? ''),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () {
//                     _firestoreService.deleteJournalEntry(entry.id);
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.pushNamed(context, "/journalWriting");
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'journal_writing_page.dart';

class JournalListPage extends StatelessWidget {
  JournalListPage({Key? key}) : super(key: key);

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Journals")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUserJournals(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No journal entries yet"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No journal entries yet"));
          }

          //final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data["content"] ?? ""),
                subtitle: Text(data["date"] ?? ""),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalWritingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
