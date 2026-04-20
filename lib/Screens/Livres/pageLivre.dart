import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import '../../Models/pageLivre.dart';
import '../../Models/livre.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageZoomPage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageZoomPage({
    super.key,
    required this.imageUrl,
    required this.title,
  });

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

class BookImagesPage extends StatefulWidget {
  final String livreId;
  final String titreLivre;
  final List<Sommaire> listSommaires;

  const BookImagesPage({
    super.key,
    required this.livreId,
    required this.titreLivre,
    required this.listSommaires,
  });

  @override
  State<BookImagesPage> createState() => _BookImagesPageState();
}

class _BookImagesPageState extends State<BookImagesPage> {
  late Future<List<BookPageImage>> futureImages;

  int currentIndex = 0;
  int currentIndexMax = 0;

  final _storage = FlutterSecureStorage();

  String? token = '';
  String? keyTheme = '';
  String? coverLivre = '';

  // CHAT
  bool isLoadingChat = false;
  List<Map<String, String>> chatMessages = [];
  TextEditingController chatController = TextEditingController();

  List<String> models = [];
  String? selectedModel;
  bool isLoadingModels = true;

  late String storageKey;

  String ocrText = "";
  String translatedText = "";
  bool isProcessingOCR = false;

  final ScrollController _miniSliderController = ScrollController();
  final PageController _pageController = PageController();

  bool showMiniSlider = true;

  @override
  void initState() {
    storageKey = "chat_${widget.livreId}";
    super.initState();
    futureImages = fetchBookImages(widget.livreId);
    fetchModels();
    loadChatHistory();
    verifyUserData();
  }

  // ================= OCR et traduction  =================

  Future<String> translateText(String text) async {
    final response = await http.post(
      Uri.parse('https://backend-mega-book-theta.vercel.app/api/translate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"text": text, "source": "en", "target": "fr"}),
    );

    final decoded = json.decode(response.body);
    return decoded["translatedText"] ?? "";
  }

  void openOCRModal(String imagePath) {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 500,
                child: Column(
                  children: [
                    const Text(
                      "🔍 OCR & Traduction",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        setModalState(() {});
                      },
                      child: const Text("Scanner & Traduire"),
                    ),
                    if (isProcessingOCR)
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const Text("📄 Texte détecté"),
                            Text(ocrText),
                            const Divider(),
                            const Text("🇫🇷 Traduction"),
                            Text(translatedText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= FETCH =================

  Future<List<BookPageImage>> fetchBookImages(String livreId) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listPagesByLivre'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"livre_id": livreId}),
    );

    final decoded = json.decode(response.body);

    keyTheme = decoded["dataLivre"]["keyTheme"];
    coverLivre = decoded["dataLivre"]["cover"];

    final list = decoded["listPageByLivre"] as List<dynamic>;
    return list.map((e) => BookPageImage.fromJson(e)).toList();
  }

  Future<void> verifyUserData() async {
    token = await _storage.read(key: 'auth_token');
  }

  // ================= CHAT =================
  Future<void> fetchModels() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://backend-mega-book-theta.vercel.app/api/list_models_ollama_cloud'),
      );

      final decoded = json.decode(response.body);

      if (decoded["state"]) {
        setState(() {
          models = List<String>.from(decoded["listModels"]);
          selectedModel = models.first;
          isLoadingModels = false;
        });
      }
    } catch (_) {
      setState(() {
        models = [];
        selectedModel = models.first;
        isLoadingModels = false;
      });
    }
  }

  Future<void> sendMessageToChat() async {
    final text = chatController.text.trim();
    if (text.isEmpty || isLoadingChat) return;

    setState(() {
      chatMessages.add({"role": "user", "content": text});
      isLoadingChat = true;
    });

    chatController.clear();

    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/chat_ollama_cloud'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"text": text, "model": selectedModel}),
    );

    final decoded = json.decode(response.body);

    setState(() {
      chatMessages
          .add({"role": "assistant", "content": decoded["message"]["content"]});
      isLoadingChat = false;
    });
  }

  // ================= MODAL =================

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

  /// ================= SOMMAIRE =================
  ///
  /// // ================= NAVIGATION AVANCE =================

  Future<void> jumpToImage(int index) async {
    final images = await futureImages;

    if (index < 0 || index >= images.length) return;

    setState(() {
      currentIndex = index;

      if (currentIndexMax < index) {
        currentIndexMax = index;
      }
    });

    await updateCurrentPage();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Aller à la page ${index + 1}"),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

// ================= TRACKING =================

  DateTime? lastUpdateTime;

  Future<void> updateCurrentPage() async {
    try {
      // 🔥 anti spam API
      if (lastUpdateTime != null &&
          DateTime.now().difference(lastUpdateTime!) <
              const Duration(seconds: 2)) {
        return;
      }

      lastUpdateTime = DateTime.now();

      final prefs = await SharedPreferences.getInstance();

      // 🔥 sauvegarde locale
      await prefs.setInt("book_${widget.livreId}_page", currentIndex);
      await prefs.setInt("book_${widget.livreId}_max", currentIndexMax);

      final response = await http.post(
        Uri.parse(
            "https://backend-mega-book-theta.vercel.app/api/update-reading"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "book_id": widget.livreId,
          "current_page": currentIndex,
          "max_page": currentIndexMax,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Erreur API");
      }
    } catch (e) {}
  }

  void openSommaireModal() async {
    final images = await futureImages;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              children: [
                // 🔥 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Le sommaire",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),

                const Divider(),

                // 🔥 LISTE
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.listSommaires.length,
                    itemBuilder: (_, i) {
                      final item = widget.listSommaires[i];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔥 TITRE
                            Expanded(
                              child: Text(
                                item.titre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // 🔥 ACTIONS
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    // ⚠️ page commence à 1 → index = page -1
                                    jumpToImage(item.page - 1);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text("Page (${item.page.toString()})"),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // 🔥 CLOSE BTN
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text("Fermer"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= MENU =================
  void openActionMenu() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.translate, color: Colors.deepPurple),
                title: const Text("Afficher la traduction"),
                onTap: () {
                  Navigator.pop(context);
                  openTranslationModal();
                },
              ),

              const SizedBox(height: 20),
              // 🔥 SOMMAIRE (conditionnel)
              if (widget.listSommaires.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.list, color: Colors.deepPurple),
                  title: const Text("Afficher le sommaire"),
                  onTap: () {
                    Navigator.pop(context);
                    openSommaireModal();
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ================= TRADUCTION =================
  void openTranslationModal() async {
    final images = await futureImages;

    int modalIndex = currentIndex;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentImage = images[modalIndex];

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  children: [
                    // 🔥 HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "📖 Traduction",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),

                    const Divider(),

                    // 🔥 CONTENU
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            currentImage.traductionText.isNotEmpty
                                ? currentImage.traductionText
                                : "Aucune traduction disponible",
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔥 PAGINATION
                    Text(
                      "Page ${modalIndex + 1} / ${images.length}",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 10),

                    // 🔥 BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PRECEDENT
                        ElevatedButton.icon(
                          onPressed: modalIndex > 0
                              ? () {
                                  setModalState(() {
                                    modalIndex--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Précédent"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // SUIVANT
                        ElevatedButton.icon(
                          onPressed: modalIndex < images.length - 1
                              ? () {
                                  setModalState(() {
                                    modalIndex++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Suivant"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= NAVIGATION =================
  void nextImage(int maxIndex) {
    setState(() {
      if (currentIndex < maxIndex) currentIndex++;
    });
  }

  void prevImage() {
    setState(() {
      if (currentIndex > 0) currentIndex--;
    });
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

  Widget buildLinearSlider(List<BookPageImage> pages) {
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

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titreLivre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 🔥 MENU
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: openActionMenu,
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: openChatModal, // ton chatbot
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

      ////////////////////////////////////////////////////////////
      /// BODY
      ////////////////////////////////////////////////////////////
      body: FutureBuilder<List<BookPageImage>>(
        future: futureImages,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final images = snapshot.data!;
          final currentImage = images[currentIndex];

          return Stack(
            children: [
              /// CONTENU PRINCIPAL
              Column(
                children: [
                  Expanded(
                    child: PhotoView(
                      imageProvider: NetworkImage(currentImage.urlImage),
                    ),
                  ),

                  /// NAVIGATION
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: currentIndex > 0 ? prevImage : null,
                          child: const Text("Précédent"),
                        ),
                        Text('${currentIndex + 1}/${images.length}'),
                        ElevatedButton(
                          onPressed: currentIndex < images.length - 1
                              ? () => nextImage(images.length - 1)
                              : null,
                          child: const Text("Suivant"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              /// 🔥 MINI SLIDER
              if (showMiniSlider) buildLinearSlider(images),
            ],
          );
        },
      ),
    );
  }
}

/*
Ton code est déjà **très solide (lecture + tracking + chatbot multi-LLM)** 👏
Mais vu ton niveau (API + IA + architecture), tu peux clairement passer à une **version “next-gen” type Kindle + ChatGPT + Notion**.

Je te propose des évolutions **classées par impact (🔥 = game changer)** :

---

# 🔥 1. Chat IA contextuel (RAG sur le livre)

👉 Aujourd’hui ton chat est “généraliste”
👉 Tu peux le rendre **intelligent sur le livre en cours**

### 💡 Idée

* Envoyer :

  * page actuelle
  * pages voisines
  * historique lecture
* Backend → embedding + vector DB

### 🚀 Résultat

* “Explique cette page”
* “Résume ce chapitre”
* “Donne les points clés”

### Exemple payload :

```json
{
  "text": "Explique cette page",
  "model": "gpt4",
  "context": {
    "page": currentPageText,
    "previous_pages": [...],
    "book_id": livreId
  }
}
```

👉 Tu transformes ton app en **assistant pédagogique intelligent**

---

# 🔥 2. Mode “Lecture intelligente”

Ajoute une **couche UX avancée type Kindle**

### Features :

* 📌 Highlight texte (si OCR)
* 🧠 Résumé auto par page
* 🔖 Bookmark pages
* 📊 Progression de lecture

### UI :

* double tap → ajouter note
* swipe up → résumé IA

---

# 🔥 3. OCR + compréhension des images

👉 Très puissant pour livres scannés

### Stack :

* API OCR (Google Vision / Tesseract)
* Stocker texte dans DB

### Résultat :

* recherche dans le livre 🔍
* chat basé sur contenu réel
* traduction automatique

---

# 🔥 4. Recherche globale dans le livre

Ajoute :

```dart
TextField → search
```

Backend :

* index texte (Elastic / Mongo text index)

### UX :

* “chercher un mot”
* jump vers page

---

# 🔥 5. Mode audio (Text-to-Speech)

👉 Ultra utile (accessibilité + multitâche)

### Features :

* lecture vocale de page
* vitesse configurable
* voice AI (OpenAI / ElevenLabs)

---

# 🔥 6. Système de recommandation IA

👉 Tu es déjà expert ML → exploite ça

### Inputs :

* historique lecture
* pages vues
* temps passé

### Output :

* livres similaires
* pages importantes

---

# 🔥 7. Analytics avancé utilisateur

Tu track déjà → pousse plus loin :

### Metrics :

* temps par page
* heatmap lecture
* abandon rate

### Bonus :

* dashboard admin (Angular que tu veux déjà)

---

# 🔥 8. Offline mode (très important)

👉 Ton app dépend trop du réseau

### Solution :

* cache images (Hive / SQLite)
* sync différé

---

# 🔥 9. Multi-agent IA (niveau expert 🔥🔥🔥)

Vu que tu fais du LangChain 👇

### Agents :

1. 📚 Agent résumé
2. 🧑‍🏫 Agent pédagogue
3. ❓ Agent Q&A
4. 📊 Agent quiz

### Exemple :

```json
{
  "agent": "teacher",
  "task": "explique comme un prof",
  "level": "college"
}
```

---

# 🔥 10. Génération automatique de quiz

👉 énorme valeur éducative

### Exemple :

* QCM depuis page
* correction auto
* score utilisateur

---

# 🔥 11. Synchronisation multi-device

* mobile ↔ web ↔ tablette
* reprendre lecture instantanément

---

# 🔥 12. Mode social

👉 transforme ton app en plateforme

* partager notes
* voir annotations publiques
* leaderboard lecture

---

# 🔥 13. UX premium (simple mais impact énorme)

* dark mode 🌙
* swipe horizontal (comme Kindle)
* animation page flip
* preload images

---

# 🔥 14. Streaming réponse IA (comme ChatGPT)

👉 au lieu d’attendre la réponse complète

### Backend :

* SSE / WebSocket

### UX :

* texte qui s’affiche en live

---

# 🔥 15. Sécurité & performance

Vu ton architecture :

### Ajoute :

* refresh token
* retry automatique API
* cache LLM responses (Redis 🔥)

---

# 💎 Bonus ultra avancé (niveau startup)

👉 “Copilot de lecture”

* détecte si user bloque
* propose explication automatiquement
* adapte niveau (collège / lycée / expert)

---

# 🧠 Architecture idéale (ton cas)

Vu ton profil, je recommande :

```
Flutter App
   ↓
Node.js API Gateway
   ↓
Python (IA microservices)
   ↓
Vector DB (Pinecone / Weaviate)
   ↓
LLM (GPT / Gemini / Ollama)
```

---

# ⚡ Ce que je te recommande PRIORITAIREMENT

Si tu veux un impact rapide :

1. 🔥 RAG sur livre (chat intelligent)
2. 🔥 OCR + search
3. 🔥 quiz auto
4. 🔥 streaming IA

---

Si tu veux, je peux te faire :

* 🧠 architecture complète LangChain pour ton app
* ⚙️ code backend RAG (Node + Python)
* 📱 refactor Flutter propre (clean architecture)
* 🚀 version “startup ready”

Dis-moi 👍

*/
