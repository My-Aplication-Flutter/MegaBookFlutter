import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Book.dart';
import "BookReader.dart";

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<Book>> futureBooks;

  @override
  void initState() {
    super.initState();
    futureBooks = loadBooks();
  }

  Future<List<Book>> loadBooks() async {
    final response = await rootBundle.loadString('assets/data-livre.json');
    final List<dynamic> data = json.decode(response);
    return data.map((e) => Book.fromJson(e)).toList();
  }

  Future<int> getLastPage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("lastPage_$token") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: futureBooks,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final books = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Ma Bibliothèque"),
            centerTitle: true,
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];

              return FutureBuilder<int>(
                future: getLastPage(book.token),
                builder: (context, snap) {
                  final lastPage = snap.data ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookReader(book: book),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                book.cover,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text(
                                  book.titre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.auteur,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                if (lastPage > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Reprendre page ${lastPage + 1}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.blue),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
