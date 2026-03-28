import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import '../../Models/pageCycleMagazineModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================= IMAGE ZOOM =================
class ImageZoomPage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageZoomPage({super.key, required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}

// ================= MAIN PAGE =================
class CycleMagazineImagesPage extends StatefulWidget {
  final String cycleMagazineId;
  final String titreCycleMagazine;

  const CycleMagazineImagesPage({
    super.key,
    required this.cycleMagazineId,
    required this.titreCycleMagazine,
  });

  @override
  State<CycleMagazineImagesPage> createState() =>
      _CycleMagazineImagesPageState();
}

class _CycleMagazineImagesPageState extends State<CycleMagazineImagesPage> {
  // ================= VARIABLES =================
  late Future<List<CycleMagazinePageImage>> futureImages;
  int currentIndex = 0;

  final _storage = FlutterSecureStorage();
  String? token = '';

  // ===== CHAT =====
  List<Map<String, String>> chatMessages = [];
  bool isLoadingChat = false;
  TextEditingController chatController = TextEditingController();

  // ===== MODELS =====
  List<String> models = [];
  String? selectedModel;
  bool isLoadingModels = true;

  // ===== STORAGE =====
  late String storageKey;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    storageKey = "chat_${widget.cycleMagazineId}";

    futureImages = fetchCycleMagazineImages(widget.cycleMagazineId);
    fetchModels();
    loadChatHistory();
  }

  // ================= LOCAL STORAGE =================
  Future<void> saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        storageKey, chatMessages.map((e) => json.encode(e)).toList());
  }

  Future<void> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(storageKey);

    if (stored != null) {
      setState(() {
        chatMessages = stored
            .map((e) => Map<String, String>.from(json.decode(e)))
            .toList();
      });
    }
  }

  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    setState(() => chatMessages.clear());
  }

  // ================= FETCH MODELS =================
  Future<void> fetchModels() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://backend-mega-book-theta.vercel.app/api/list_models_ollama_cloud'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({}),
      );

      final decoded = json.decode(response.body);

      if (decoded["state"] == true) {
        setState(() {
          models = List<String>.from(decoded["listModels"]);
          selectedModel = models.first;
          isLoadingModels = false;
        });
      }
    } catch (_) {
      setState(() {
        models = ["gemini-3-flash-preview", "gpt4"];
        selectedModel = models.first;
        isLoadingModels = false;
      });
    }
  }

  // ================= FETCH IMAGES =================
  Future<List<CycleMagazinePageImage>> fetchCycleMagazineImages(
      String id) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listPagesByMagazine'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"cycle_magazine_id": id}),
    );

    final decoded = json.decode(response.body);
    final list = decoded["listPageByNumeroMagazine"] as List;

    return list.map((e) => CycleMagazinePageImage.fromJson(e)).toList();
  }

  // ================= CHAT =================
  Future<void> sendMessageToChat() async {
    final text = chatController.text.trim();
    if (text.isEmpty || isLoadingChat) return;

    setState(() {
      chatMessages.add({"role": "user", "content": text});
      isLoadingChat = true;
    });

    await saveChatHistory();
    chatController.clear();

    try {
      final response = await http.post(
        Uri.parse(
            'https://backend-mega-book-theta.vercel.app/api/chat_ollama_cloud'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "text": text,
          "model": selectedModel,
        }),
      );

      final decoded = json.decode(response.body);

      setState(() {
        chatMessages.add({
          "role": "assistant",
          "content": "[${selectedModel}]\n${decoded["message"]["content"]}"
        });
      });

      await saveChatHistory();
    } catch (e) {
      chatMessages.add({"role": "assistant", "content": "Erreur réseau"});
    }

    setState(() => isLoadingChat = false);
  }

  // ================= MODAL =================
  void openChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 10),
                      const Text("Assistant IA"),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await clearChatHistory();
                          setModalState(() {});
                        },
                      )
                    ],
                  ),

                  // MODELS
                  isLoadingModels
                      ? const CircularProgressIndicator()
                      : DropdownButton<String>(
                          value: selectedModel,
                          items: models
                              .map((m) =>
                                  DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => selectedModel = v),
                        ),

                  // CHAT
                  Expanded(
                    child: ListView.builder(
                      itemCount: chatMessages.length + (isLoadingChat ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == chatMessages.length && isLoadingChat) {
                          return const ListTile(
                            title: Text("Assistant réfléchit..."),
                            trailing: CircularProgressIndicator(),
                          );
                        }

                        final msg = chatMessages[i];
                        final isUser = msg["role"] == "user";

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(10),
                            color:
                                isUser ? Colors.deepPurple : Colors.grey[300],
                            child: Text(msg["content"] ?? ""),
                          ),
                        );
                      },
                    ),
                  ),

                  // INPUT
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: chatController),
                      ),
                      IconButton(
                        icon: isLoadingChat
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.send),
                        onPressed: isLoadingChat
                            ? null
                            : () async {
                                await sendMessageToChat();
                                setModalState(() {});
                              },
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titreCycleMagazine,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 2,
        actions: [
          GestureDetector(
            onTap: openChatModal,
            onLongPress: () async {
              await clearChatHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chat réinitialisé")),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.smart_toy, size: 26, color: Colors.white),
                ),

                // 🔥 Loader chatbot
                if (isLoadingChat)
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // ❌ SUPPRIMÉ
      // floatingActionButton: FloatingActionButton(...)

      body: FutureBuilder<List<CycleMagazinePageImage>>(
        future: futureImages,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final images = snapshot.data!;
          final currentImage = images[currentIndex];

          return Column(
            children: [
              Expanded(
                child: PhotoView(
                  imageProvider: NetworkImage(currentImage.urlImage),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: currentIndex > 0
                          ? () => setState(() => currentIndex--)
                          : null,
                      child: const Text("Précédent"),
                    ),
                    Text(
                      "${currentIndex + 1}/${images.length}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: currentIndex < images.length - 1
                          ? () => setState(() => currentIndex++)
                          : null,
                      child: const Text("Suivant"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
