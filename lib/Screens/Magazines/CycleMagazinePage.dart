import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import '../../Models/pageCycleMagazineModel.dart';

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

  @override
  void initState() {
    super.initState();
    futureImages = fetchCycleMagazineImages(widget.cycleMagazineId);
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
      final list = decoded["listPageByNumeroMagazine"] as List<dynamic>;
      return list.map((e) => CycleMagazinePageImage.fromJson(e)).toList();
    } else {
      throw Exception('Erreur récupération images');
    }
  }

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
