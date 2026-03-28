import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import '../../Models/pageLivre.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  const BookImagesPage({
    super.key,
    required this.livreId,
    required this.titreLivre,
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

  // 🔥 Etat chatbot
  bool isLoadingChat = false;
  List<Map<String, dynamic>> chatHistory = [];

  @override
  void initState() {
    super.initState();
    futureImages = fetchBookImages(widget.livreId);
    verifyUserData();
  }

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

  Future<int> fetchCurrentIndex() async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/getDataPageNavigationLecture'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "ObjectNavigationPage": {"token": token, "document_id": widget.livreId}
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

    final body = {
      "ObjectNavigationPage": {
        "token": token,
        "dateConsultation": DateTime.now().toIso8601String(),
        "document_id": widget.livreId,
        "nom_document": widget.titreLivre,
        "compteurPage": currentIndex,
        "compteurPageMaxi": currentIndexMax,
        "urlPage": urlPage,
        "cover_document": coverLivre,
        "keyTheme": keyTheme,
        "nomTheme": keyTheme,
        "typeDocument": 'livre',
        "keySection": 'livres'
      }
    };

    await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/postUpdatePageNavigationLecture'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<List<BookPageImage>> fetchBookImages(String livreId) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listPagesByLivre'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"livre_id": livreId}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      keyTheme = decoded["dataLivre"]["keyTheme"];
      coverLivre = decoded["dataLivre"]["cover"];

      final list = decoded["listPageByLivre"] as List<dynamic>;
      return list.map((e) => BookPageImage.fromJson(e)).toList();
    } else {
      throw Exception('Erreur récupération images');
    }
  }

  void nextImage(int maxIndex) {
    setState(() {
      if (currentIndex < maxIndex) currentIndex++;
      if (currentIndexMax < maxIndex) currentIndexMax = maxIndex;
    });
    updateCurrentPage();
  }

  void prevImage() {
    setState(() {
      if (currentIndex > 0) currentIndex--;
    });
    updateCurrentPage();
  }

  void jumpToImage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // 🔥 CHATBOT
  void openChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text("Assistant IA",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView(
                children: chatHistory
                    .map((msg) => ListTile(
                          title: Text(msg["text"]),
                          subtitle: Text(msg["role"]),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 LONG PRESS = RESET CHAT
  void resetChat() {
    setState(() {
      chatHistory.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Historique chat réinitialisé")),
    );
  }

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
        iconTheme: const IconThemeData(
            color: Colors.white), // 🔥 pour icônes back + autres
        actions: [
          GestureDetector(
            onTap: openChatModal,
            onLongPress: resetChat,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.smart_toy, size: 26, color: Colors.white),
                ),
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
      body: FutureBuilder<List<BookPageImage>>(
        future: futureImages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final images = snapshot.data ?? [];

          if (images.isEmpty) {
            return const Center(child: Text("Aucune page trouvée"));
          }

          final currentImage = images[currentIndex];

          return Column(
            children: [
              Expanded(
                child: PhotoView(
                  imageProvider: NetworkImage(currentImage.urlImage),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.white),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentIndex > 0 ? prevImage : null,
                    child: const Text("Précédent"),
                  ),
                  Text('Page ${currentIndex + 1} / ${images.length}'),
                  ElevatedButton(
                    onPressed: currentIndex < images.length - 1
                        ? () => nextImage(images.length - 1)
                        : null,
                    child: const Text("Suivant"),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
