import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import '../../Models/pageCycleMagazineModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Page pour afficher une image zoomable
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

class CycleMagazineImagesPage extends StatefulWidget {
  final String cycleMagazineId;
  final String titreCycleMagazine;

  const CycleMagazineImagesPage(
      {super.key,
      required this.cycleMagazineId,
      required this.titreCycleMagazine});

  @override
  State<CycleMagazineImagesPage> createState() =>
      _CycleMagazineImagesPageState();
}

class _CycleMagazineImagesPageState extends State<CycleMagazineImagesPage> {
  late Future<List<CycleMagazinePageImage>> futureImages;
  int currentIndex = 0;
  int currentIndexMax = 0;
  final _storage = FlutterSecureStorage();
  String? token = '';
  String? keyTheme = '';
  String? coverMagazine = '';

  @override
  void initState() {
    super.initState();
    futureImages = fetchCycleMagazineImages(widget.cycleMagazineId);
    verifyUserData();
  }

  Future<void> verifyUserData() async {
    // final token = await _storage.read(key: 'auth_token');
    token = await _storage.read(key: 'auth_token');
    // token = "nouvelle_valeur"; // valide si besoin
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
        "ObjectNavigationPage": {
          "token": token,
          "document_id": widget.cycleMagazineId
        }
      }),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded["reponse"] == true && decoded["data"] != null) {
        if (decoded["data"]["compteurPageMaxi"] != null) {
          // currentIndexMax = decoded["data"]["compteurPageMaxi"];
        }

        // attention: 'compteurPage' est l’index 1-based de la dernière page consultée
        // pour l’exploiter comme index de liste (0-based), fais -1
        return ((decoded["data"]["compteurPage"] + 1) ?? 1) - 1;
      }
    }
    return 0; // défaut : page 1
  }

// Appelle cette fonction dès qu'un changement de page est effectué
  Future<void> updateCurrentPage() async {
    final images = await futureImages; // attend la liste réelle
    final urlPage =
        images[currentIndex].urlImage; // tu peux ensuite accéder à l’url
    // print("urlPage = ${urlPage}");

    final body = {
      "ObjectNavigationPage": {
        "token": token,
        "dateConsultation": DateTime.now().toIso8601String(), // date courante
        "document_id": widget.cycleMagazineId,
        "nom_document": widget.titreCycleMagazine,
        "compteurPage": currentIndex,
        "compteurPageMaxi": currentIndexMax,
        "urlPage": urlPage,
        "cover_document": coverMagazine,
        "keyTheme": keyTheme,
        "nomTheme": keyTheme,
        "typeDocument": 'magazine',
        "keySection": 'magazines'
      }
    };

    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/postUpdatePageNavigationLecture'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Tu peux utiliser la réponse ici si besoin
      if (decoded["reponse"] == true) {
        // Mise à jour OK
      } else {
        // Gestion d’erreur API
      }
    } else {
      // Gestion d’erreur réseau ou serveur
    }
  }

  Future<List<CycleMagazinePageImage>> fetchCycleMagazineImages(
      String cycle_magazine_id) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listPagesByMagazine'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"cycle_magazine_id": cycle_magazine_id}),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      keyTheme = decoded["dataMagazine"]["keyTheme"];
      print("keyTheme = ${keyTheme}");

      coverMagazine = decoded["dataMagazine"]["cover"];
      print("cover = ${coverMagazine}");

      final list = decoded["listPageByNumeroMagazine"] as List<dynamic>;
      return list.map((e) => CycleMagazinePageImage.fromJson(e)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titreCycleMagazine,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<CycleMagazinePageImage>>(
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
            return const Center(
                child: Text("Aucune image trouvée pour ce livre."));
          }
          final currentImage = images[currentIndex];

          return Column(
            children: [
              Expanded(
                child: PhotoView(
                  imageProvider: NetworkImage(currentImage.urlImage),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.white),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: currentIndex > 0 ? prevImage : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                    ),
                    Text('Page ${currentIndex + 1} / ${images.length}'),
                    ElevatedButton.icon(
                      onPressed: currentIndex < images.length - 1
                          ? () => nextImage(images.length - 1)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Suivant'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Slider(
                  value: (currentIndex + 1).toDouble(),
                  min: 1,
                  max: images.length.toDouble(),
                  divisions: images.length - 1,
                  label: 'Page ${currentIndex + 1}',
                  onChanged: (value) => jumpToImage(value.toInt() - 1),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
