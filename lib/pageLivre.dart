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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titreLivre)),
      body: FutureBuilder<List<BookPageImage>>(
        future: futureImages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return const Center(
                child: Text("Aucune image trouvée pour ce livre."));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final page = images[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageZoomPage(
                              imageUrl: page.urlImage,
                              title: 'Page ${page.numPage}',
                            ),
                          ),
                        );
                      },
                      child: Image.network(
                        page.urlImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.broken_image, size: 40));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page ${page.numPage}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
