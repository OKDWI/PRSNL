import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_llama/flutter_llama.dart';

import '../widgets/background.dart';
import '../navbar.dart';

class CompanionPage extends StatefulWidget {
  const CompanionPage({super.key});

  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // LLM Instance
  final FlutterLlama _llama = FlutterLlama.instance;

  bool _isModelLoaded = false;
  bool _isGenerating = false;

  final List<Map<String, String>> messages = [
    {"text": "Hello, what can I do for you today?", "sender": "bot"},
  ];

  final String userAvatar = "assets/user.png";
  final String ghostAvatar = "assets/ghost.png";

  @override
  void initState() {
    super.initState();
    _loadLlamaModel();
  }

  @override
  void dispose() {
    _llama.unloadModel();
    _scrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  //                         MODEL LOADING
  // ------------------------------------------------------------
  Future<void> _loadLlamaModel() async {
    const String modelAssetPath =
        'assets/models/phi-1_5-empathetic-q4_k_m.gguf';

    try {
      _addBotMessage("Loading 1.4 GB GGUF model with GPU acceleration...");

      final config = LlamaConfig(
        modelPath: modelAssetPath,
        nThreads: 6,
        nGpuLayers: -1,
        contextSize: 2048,
        useGpu: true,
      );

      final success = await _llama.loadModel(config);

      if (success) {
        setState(() => _isModelLoaded = true);
        _addBotMessage("✅ Model loaded! GPU is active. Ask Lumi anything!");
      } else {
        _addBotMessage("❌ Error: Load failed. Check console for native logs.");
      }
    } catch (e) {
      _addBotMessage("❌ Critical Error: Failed to load model. $e");
    }
  }

  // ------------------------------------------------------------
  //                        MESSAGE SENDING
  // ------------------------------------------------------------
  void _sendMessage() {
    final String text = _controller.text.trim();

    if (text.isEmpty || !_isModelLoaded || _isGenerating) return;

    setState(() {
      messages.add({"text": text, "sender": "user"});
      messages.add({"text": "", "sender": "bot"}); // placeholder for streaming
      _controller.clear();
      _isGenerating = true;
    });

    _scrollToBottom();

    final int botMessageIndex = messages.length - 1;

    final String fullPrompt =
        "Instruction: You are an empathetic companion named Lumi. Respond concisely and helpfully.\n"
        "User: $text\n"
        "Lumi:";

    final params = GenerationParams(
      prompt: fullPrompt,
      temperature: 0.7,
      maxTokens: 500,
      repeatPenalty: 1.1,
    );

    _llama
        .generateStream(params)
        .listen(
          (token) {
            setState(() {
              messages[botMessageIndex]["text"] =
                  (messages[botMessageIndex]["text"] ?? "") + token;
            });
            _scrollToBottom();
          },
          onDone: () {
            setState(() => _isGenerating = false);
          },
          onError: (error) {
            setState(() {
              _addBotMessage("An error occurred during generation: $error");
              _isGenerating = false;
            });
          },
        );
  }

  // ------------------------------------------------------------
  //                          HELPERS
  // ------------------------------------------------------------
  void _addBotMessage(String text) {
    setState(() {
      messages.add({"text": text, "sender": "bot"});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ------------------------------------------------------------
  //                           UI BUILD
  // ------------------------------------------------------------
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: BackgroundHeader(overrideBackground: true),
              ),
              const SizedBox(height: 12),

              // ----------------- Title & Status -----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Lumi",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: _isGenerating
                        ? Colors.amber
                        : (_isModelLoaded ? Colors.green : Colors.red),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ----------------- Chat Messages -----------------
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
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
                              // Bubble
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

                              // Avatar
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

              // ----------------- Input Box -----------------
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
                        onSubmitted: (value) => _sendMessage(),
                        enabled: _isModelLoaded && !_isGenerating,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: _isModelLoaded
                              ? (_isGenerating
                                    ? "Lumi is thinking..."
                                    : "Type a message...")
                              : "Loading Model...",
                          hintStyle: const TextStyle(
                            color: Color.fromARGB(172, 20, 20, 20),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isModelLoaded && !_isGenerating
                          ? _sendMessage
                          : null,
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
