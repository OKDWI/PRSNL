import 'package:flutter/material.dart';
import '../widgets/background.dart'; // PRSNL background + header
import '../navbar.dart'; // Your custom navbar

class CompanionPage extends StatefulWidget {
  const CompanionPage({super.key});

  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> {
  final TextEditingController _controller = TextEditingController();

  // Initial greeting
  final List<Map<String, String>> messages = [
    {"text": "Hello, what can I do for you today?", "sender": "bot"},
  ];

  final String userAvatar = "assets/user.png"; // replace if needed
  final String ghostAvatar = "assets/ghost.png"; // your ghost

  int _selectedIndex = 2; // third tile

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    // Navigation logic — modify once real pages are connected
    switch (index) {
      case 0:
        Navigator.pop(context); // back to home
        break;
      default:
        // placeholder
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Page $index coming soon")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      isDarkMode: false,
      onToggleTheme: () {},
      overrideBackground: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,

        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ---------- PRSNL Ghost Header ----------
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: BackgroundHeader(overrideBackground: true),
              ),

              const SizedBox(height: 12),

              // ---------- Title ----------
              const Text(
                "Lumi",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // ---------- Chat Messages ----------
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg["sender"] == "user";
                    final text = msg["text"] ?? "";

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ---------- Bubble ----------
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  42,
                                  20,
                                  42,
                                  20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(30),
                                    topRight: const Radius.circular(30),
                                    bottomLeft: isUser
                                        ? const Radius.circular(30)
                                        : const Radius.circular(20),
                                    bottomRight: isUser
                                        ? const Radius.circular(20)
                                        : const Radius.circular(30),
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(4, 6),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.28,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // ---------- Avatar ----------
                              Positioned(
                                top: -16,
                                right: isUser ? -12 : null,
                                left: isUser ? null : -12,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: Image.asset(
                                      isUser ? userAvatar : ghostAvatar,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ---------- Input box ----------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(
                            color: Color.fromARGB(172, 20, 20, 20),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;

                        setState(() {
                          messages.add({"text": text, "sender": "user"});
                          _controller.clear();
                        });
                      },
                      icon: const Icon(Icons.send, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
