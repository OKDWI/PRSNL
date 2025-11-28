import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Add new entry
  Future<void> addEntry(String title, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("journal_entries").add({
      "uid": user.uid,
      "email": user.email,
      "title": title,
      "content": content,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  /// Get all entries for current user (ordered by date)
  Stream<QuerySnapshot<Map<String, dynamic>>> entriesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection("journal_entries")
        .where("uid", isEqualTo: user.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// Delete entry
  Future<void> deleteEntry(String docId) async {
    await _firestore.collection("journal_entries").doc(docId).delete();
  }
}
