import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Models/livre.dart';
import 'pageLivre.dart';

class BooksByThemePage extends StatefulWidget {
  final String theme;

  const BooksByThemePage({super.key, required this.theme});

  @override
  State<BooksByThemePage> createState() => _BooksByThemePageState();
}

class _BooksByThemePageState extends State<BooksByThemePage> {
  late Future<List<Book>> futureBooks;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks(widget.theme);
  }

  Future<List<Book>> fetchBooks(String theme) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listLivresBytheme'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"keyTheme": theme}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = decoded["listLivres"] as List<dynamic>;
      return list.map((e) => Book.fromJson(e)).toList();
    } else {
      throw Exception('Erreur de récupération des livres');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.theme,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Book>>(
        future: futureBooks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Aucun livre trouvé pour ce thème.'));
          }
          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(book.cover),
                    radius: 25,
                  ),
                  title: Text(book.titre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${book.auteur} • ${book.year}\n${book.subtitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('${book.nbrPages} pages',
                      style: const TextStyle(color: Colors.grey)),
                  onTap: () {
                    // Naviguer vers une page détaillée si besoin
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Sélectionné : ${book.titre}/id = ${book.id}')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookImagesPage(
                          livreId: book.id,
                          titreLivre: book.titre,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
