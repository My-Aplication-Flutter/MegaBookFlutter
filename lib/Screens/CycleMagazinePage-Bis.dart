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
          backgroundDecoration: const BoxDecoration(color: Colors.white),
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
  int currentIndexMax = 0;

  final _storage = FlutterSecureStorage();
  String? token = '';
  String? keyTheme = '';
  String? coverMagazine = '';

  // ===== CHATBOT =====
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
    verifyUserData();
    fetchModels();
    loadChatHistory(); // 🔥
  }

  // ================= LOCAL STORAGE =================
  Future<void> saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> encoded = chatMessages.map((msg) => json.encode(msg)).toList();

    await prefs.setStringList(storageKey, encoded);
  }

  Future<void> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? stored = prefs.getStringList(storageKey);

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

    setState(() {
      chatMessages.clear();
    });
  }

  // ================= USER =================
  Future<void> verifyUserData() async {
    token = await _storage.read(key: 'auth_token');
    _initCurrentIndex();
  }

  Future<void> _initCurrentIndex() async {
    int lastIndex = await fetchCurrentIndex();
    setState(() {
      currentIndex = lastIndex;
      currentIndexMax = lastIndex;
    });
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

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded["state"] == true && decoded["listModels"] != null) {
          List<dynamic> list = decoded["listModels"];

          setState(() {
            models = list.map((e) => e.toString()).toList();
            selectedModel = models.isNotEmpty ? models.first : null;
            isLoadingModels = false;
          });
        } else {
          fallbackModels();
        }
      } else {
        fallbackModels();
      }
    } catch (e) {
      fallbackModels();
    }
  }

  void fallbackModels() {
    setState(() {
      models = ["gemini-3-flash-preview", "gpt4", "llama3"];
      selectedModel = models.first;
      isLoadingModels = false;
    });
  }

  // ================= NAVIGATION =================
  Future<int> fetchCurrentIndex() async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/getDataPageNavigationLecture'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "ObjectNavigationPage": {
          "token": token,
          "document_id": widget.cycleMagazineId
        }
      }),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded["reponse"] == true && decoded["data"] != null) {
        return ((decoded["data"]["compteurPage"] + 1) ?? 1) - 1;
      }
    }
    return 0;
  }

  Future<void> updateCurrentPage() async {
    final images = await futureImages;
    final urlPage = images[currentIndex].urlImage;

    await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/postUpdatePageNavigationLecture'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "ObjectNavigationPage": {
          "token": token,
          "document_id": widget.cycleMagazineId,
          "compteurPage": currentIndex,
          "compteurPageMaxi": currentIndexMax,
          "urlPage": urlPage
        }
      }),
    );
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
    final list = decoded["listPageByNumeroMagazine"] as List<dynamic>;

    return list.map((e) => CycleMagazinePageImage.fromJson(e)).toList();
  }

  // ================= NAV =================
  void nextImage(int maxIndex) {
    setState(() {
      if (currentIndex < maxIndex) currentIndex++;
    });
    updateCurrentPage();
  }

  void prevImage() {
    setState(() {
      if (currentIndex > 0) currentIndex--;
    });
    updateCurrentPage();
  }

  // ================= CHAT =================
  Future<void> sendMessageToChat() async {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

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
        body: json.encode(
            {"text": text, "model": selectedModel ?? "gemini-3-flash-preview"}),
      );

      final decoded = json.decode(response.body);
      final reply = decoded["message"]["content"];

      setState(() {
        chatMessages.add(
            {"role": "assistant", "content": "[${selectedModel}]\n$reply"});
      });

      await saveChatHistory();
    } catch (e) {
      setState(() {
        chatMessages.add({"role": "assistant", "content": "Erreur réseau"});
      });
      await saveChatHistory();
    }

    setState(() {
      isLoadingChat = false;
    });
  }

  // ================= MODAL =================
  void openChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 🔥 HEADER + RESET
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 10),
                        const Text("Assistant IA",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await clearChatHistory();
                            setModalState(() {});
                          },
                        )
                      ],
                    ),

                    // ===== MODELS =====
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: isLoadingModels
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: selectedModel,
                              items: models.map((m) {
                                return DropdownMenuItem(
                                    value: m, child: Text(m));
                              }).toList(),
                              onChanged: (v) {
                                setModalState(() {
                                  selectedModel = v!;
                                });
                              },
                            ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (_, i) {
                          final msg = chatMessages[i];
                          final isUser = msg["role"] == "user";

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.deepPurple
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(msg["content"] ?? ""),
                            ),
                          );
                        },
                      ),
                    ),

                    if (isLoadingChat) const CircularProgressIndicator(),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(controller: chatController),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            await sendMessageToChat();
                            setModalState(() {});
                          },
                        )
                      ],
                    )
                  ],
                ),
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
      appBar: AppBar(title: Text(widget.titreCycleMagazine)),
      floatingActionButton: FloatingActionButton(
        onPressed: openChatModal,
        child: const Icon(Icons.smart_toy),
      ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: currentIndex > 0 ? prevImage : null,
                      child: const Text("Prev")),
                  Text("${currentIndex + 1}/${images.length}"),
                  ElevatedButton(
                      onPressed: currentIndex < images.length - 1
                          ? () => nextImage(images.length - 1)
                          : null,
                      child: const Text("Next")),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}
