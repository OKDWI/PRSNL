// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// Future<void> saveJournalEntry(
//   String title,
//   String content,
//   String category,
// ) async {
//   final user = FirebaseAuth.instance.currentUser;

//   if (user != null) {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('journals')
//         .add({
//           'title': title,
//           'content': content,
//           'date': DateTime.now().toString().split(" ")[0], // yyyy-mm-dd
//           'timestamp': FieldValue.serverTimestamp(),
//           'category': category,
//         });
//   }
// }

// import 'package:flutter/material.dart';
// import '../services/firestore_service.dart';

// class JournalWritingPage extends StatefulWidget {
//   const JournalWritingPage({super.key});

//   @override
//   _JournalWritingPageState createState() => _JournalWritingPageState();
// }

// class _JournalWritingPageState extends State<JournalWritingPage> {
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _contentController = TextEditingController();
//   final FirestoreService _firestoreService = FirestoreService();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Image.asset(
//             "assets/images/day_bg.png", // switch dynamically as you did before
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           ),
//           Column(
//             children: [
//               TextField(
//                 controller: _titleController,
//                 decoration: const InputDecoration(hintText: "Title"),
//               ),
//               Expanded(
//                 child: TextField(
//                   controller: _contentController,
//                   decoration: const InputDecoration(
//                     hintText: "Write your journal...",
//                   ),
//                   maxLines: null,
//                   expands: true,
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _firestoreService.addJournalEntry(
//                     _titleController.text.trim(),
//                     _contentController.text.trim(),
//                   );

//                   Navigator.pop(context); // go back to entries list
//                 },
//                 child: const Text("Save"),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class JournalWritingPage extends StatefulWidget {
  const JournalWritingPage({Key? key}) : super(key: key);

  @override
  State<JournalWritingPage> createState() => _JournalWritingPageState();
}

class _JournalWritingPageState extends State<JournalWritingPage> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Write Journal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Write your journal entry...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.addJournalEntry(_controller.text);
                Navigator.pop(context); // go back to list
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
