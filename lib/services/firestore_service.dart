// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;

//   // Add new journal entry
//   Future<void> addJournalEntry(String title, String content) async {
//     if (userId == null) return;

//     await _db.collection('users').doc(userId).collection('journals').add({
//       'title': title,
//       'content': content,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//   }

//   // Get all journal entries
//   Stream<QuerySnapshot> getJournalEntries() {
//     if (userId == null) {
//       return const Stream.empty();
//     }

//     return _db
//         .collection('users')
//         .doc(userId)
//         .collection('journals')
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }

//   // Delete an entry
//   Future<void> deleteJournalEntry(String docId) async {
//     if (userId == null) return;

//     await _db
//         .collection('users')
//         .doc(userId)
//         .collection('journals')
//         .doc(docId)
//         .delete();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  /// Save a journal entry
  Future<void> addJournalEntry(String content) async {
    if (user == null) return; // no logged in user

    await _db.collection("journals").add({
      "uid": user!.uid,
      "content": content,
      "timestamp": FieldValue.serverTimestamp(),
      "date": DateTime.now().toIso8601String(),
    });
  }

  /// Stream journal entries for current user
  Stream<QuerySnapshot> getUserJournals() {
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection("journals")
        .where("uid", isEqualTo: user!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
