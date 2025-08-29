import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'Models/pageLivre.dart';

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

class BookImagesPage extends StatefulWidget {
  final String livreId;
  final String titreLivre;

  const BookImagesPage(
      {super.key, required this.livreId, required this.titreLivre});

  @override
  State<BookImagesPage> createState() => _BookImagesPageState();
}

class _BookImagesPageState extends State<BookImagesPage> {
  late Future<List<BookPageImage>> futureImages;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    futureImages = fetchBookImages(widget.livreId);
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
      final list = decoded["listPageByLivre"] as List<dynamic>;
      return list.map((e) => BookPageImage.fromJson(e)).toList();
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
      appBar: AppBar(title: Text(widget.titreLivre)),
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
