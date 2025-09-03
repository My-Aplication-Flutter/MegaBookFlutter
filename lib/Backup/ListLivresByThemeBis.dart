
import 'package:flutter/material.dart';

class Book {
  final String titre;
  final String auteur;
  final String cover;
  final int year;

  Book({
    required this.titre,
    required this.auteur,
    required this.cover,
    required this.year,
  });
}

class BooksGridPage extends StatelessWidget {
  final List<Book> books = [
    Book(
      titre: "L’Étranger",
      auteur: "Albert Camus",
      cover: "https://i.postimg.cc/DZ0yxfQK/user.png", // Remplace par une vraie cover
      year: 1942,
    ),
    Book(
      titre: "1984",
      auteur: "George Orwell",
      cover: "https://m.media-amazon.com/images/I/71kxa1-0mfL.jpg",
      year: 1949,
    ),
    Book(
      titre: "Harry Potter",
      auteur: "J.K. Rowling",
      cover: "https://m.media-amazon.com/images/I/81YOuOGFCJL.jpg",
      year: 1997,
    ),
    Book(
      titre: "Le Petit Prince",
      auteur: "Antoine de Saint-Exupéry",
      cover: "https://m.media-amazon.com/images/I/71UwSHSZRnS.jpg",
      year: 1943,
    ),
  ];

  BooksGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Ma bibliothèque"),
        backgroundColor: Colors.greenAccent,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 colonnes
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65, // Ratio adapté aux couvertures
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              _showBookDetails(context, book);
            },
            child: Stack(
              children: [
                // Cover en fond
                Hero(
                  tag: "book_${book.titre}_${book.year}",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      book.cover,
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay dégradé sombre
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Infos en bas
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.titre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${book.auteur} • ${book.year}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Petit modal pour montrer les détails du livre
  void _showBookDetails(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: "book_${book.titre}_${book.year}",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(book.cover, height: 200),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              book.titre,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "${book.auteur} (${book.year})",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text("Fermer"),
            ),
          ],
        ),
      ),
    );
  }
}
