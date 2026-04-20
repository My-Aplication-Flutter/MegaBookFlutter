import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import '../../Models/pageCycleMagazineModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../Services/cache_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  final MagazineCacheService cacheService = MagazineCacheService();

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

  final ScrollController _miniSliderController = ScrollController();
  final PageController _pageController = PageController();

  bool showMiniSlider = true;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    storageKey = "chat_${widget.cycleMagazineId}";

    futureImages = fetchCycleMagazineImages(widget.cycleMagazineId);

    /// 🔥 PRELOAD IMAGES
    futureImages.then((pages) async {
      for (var p in pages) {
        try {
          await DefaultCacheManager().getSingleFile(p.urlImage);
        } catch (_) {}
      }
    });

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

  // ================= FETCH IMAGES (ONLINE + OFFLINE) =================
  Future<List<CycleMagazinePageImage>> fetchCycleMagazineImages(
      String id) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://backend-mega-book-theta.vercel.app/api/listPagesByMagazine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"cycle_magazine_id": id}),
      );

      final decoded = json.decode(response.body);
      final list = decoded["listPageByNumeroMagazine"] as List;

      final pages =
          list.map((e) => CycleMagazinePageImage.fromJson(e)).toList();

      /// 💾 cache JSON
      await cacheService.savePages(
        id,
        pages.map((e) => e.toJson()).toList(),
      );

      return pages;
    } catch (e) {
      /// 🔥 OFFLINE FALLBACK
      final cachedPages = await cacheService.getPages(id);

      if (cachedPages != null) {
        return cachedPages
            .map((e) => CycleMagazinePageImage.fromJson(e))
            .toList();
      }

      throw Exception("Aucune donnée disponible offline");
    }
  }

  // ================= IMAGE PROVIDER (CACHE) =================
  Future<ImageProvider> _getImageProvider(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);

      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return NetworkImage(url);
      }
    } catch (_) {
      return NetworkImage(url);
    }
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

  // ================= CHAT MODAL =================
  void openChatModal() {
    final FocusNode inputFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 🔥 important
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: viewInsets, // 🔥 remonte avec clavier
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    ////////////////////////////////////////////////////////////
                    /// HEADER
                    ////////////////////////////////////////////////////////////
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

                    ////////////////////////////////////////////////////////////
                    /// MODELS
                    ////////////////////////////////////////////////////////////
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

                    ////////////////////////////////////////////////////////////
                    /// CHAT
                    ////////////////////////////////////////////////////////////
                    Expanded(
                      child: ListView.builder(
                        reverse: true, // 🔥 style chat moderne
                        itemCount:
                            chatMessages.length + (isLoadingChat ? 1 : 0),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.deepPurple
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg["content"] ?? "",
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    ////////////////////////////////////////////////////////////
                    /// INPUT STYLE CHATGPT 🔥
                    ////////////////////////////////////////////////////////////
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            ////////////////////////////////////////////////////
                            /// TEXTFIELD STYLÉ
                            ////////////////////////////////////////////////////
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: inputFocusNode.hasFocus
                                        ? Colors.deepPurple
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: chatController,
                                  focusNode: inputFocusNode,
                                  maxLines: null, // 🔥 auto expand
                                  onTap: () {
                                    setModalState(() {}); // refresh border
                                  },
                                  decoration: const InputDecoration(
                                    hintText: "Pose ta question...",
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            ////////////////////////////////////////////////////
                            /// SEND BUTTON
                            ////////////////////////////////////////////////////
                            IconButton(
                              icon: isLoadingChat
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send,
                                      color: Colors.deepPurple),
                              onPressed: isLoadingChat
                                  ? null
                                  : () async {
                                      await sendMessageToChat();
                                      setModalState(() {});
                                    },
                            )
                          ],
                        ),
                      ),
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

  void goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    _miniSliderController.animateTo(
      (index * 64.0) - (MediaQuery.of(context).size.width / 2) + 32,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget buildLinearSlider(List<CycleMagazinePageImage> pages) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ////////////////////////////////////////////////////////////
            /// 🔢 TEXTE PAGE
            ////////////////////////////////////////////////////////////
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Page ${currentIndex + 1}",
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  "${pages.length}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 6),

            ////////////////////////////////////////////////////////////
            /// 🎯 SLIDER PRINCIPAL
            ////////////////////////////////////////////////////////////
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.deepPurple,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (pages.length - 1).toDouble(),
                divisions: pages.length - 1,
                onChanged: (value) {
                  setState(() {
                    currentIndex = value.toInt();
                  });
                },
                onChangeEnd: (value) {
                  goToPage(value.toInt()); // 🔥 garde ta logique
                },
              ),
            ),
          ],
        ),
      ),
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
        actions: [
          GestureDetector(
            onTap: openChatModal,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
          ),
          IconButton(
              icon:
                  Icon(showMiniSlider ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  showMiniSlider = !showMiniSlider;
                });
              }),
        ],
      ),
      body: FutureBuilder<List<CycleMagazinePageImage>>(
        future: futureImages,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final images = snapshot.data!;
          final currentImage = images[currentIndex];

          return Stack(
            children: [
              ////////////////////////////////////////////////////////////
              /// CONTENU PRINCIPAL
              ////////////////////////////////////////////////////////////
              Column(
                children: [
                  Expanded(
                    child: FutureBuilder<ImageProvider>(
                      future: _getImageProvider(currentImage.urlImage),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        return PhotoView(
                          imageProvider: snap.data!,
                        );
                      },
                    ),
                  ),

                  ////////////////////////////////////////////////////////////
                  /// NAVIGATION
                  ////////////////////////////////////////////////////////////
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: currentIndex > 0
                              ? () => goToPage(currentIndex - 1)
                              : null,
                          child: const Text("Précédent"),
                        ),
                        Text(
                          "${currentIndex + 1}/${images.length}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: currentIndex < images.length - 1
                              ? () => goToPage(currentIndex + 1)
                              : null,
                          child: const Text("Suivant"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              ////////////////////////////////////////////////////////////
              /// 🔥 MINI SLIDER
              ////////////////////////////////////////////////////////////
              if (showMiniSlider) buildLinearSlider(images),
            ],
          );
        },
      ),
    );
  }
}
