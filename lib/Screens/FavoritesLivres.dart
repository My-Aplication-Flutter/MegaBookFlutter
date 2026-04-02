import 'package:flutter/material.dart';
import '../database_service.dart';
import '../Models/livre.dart';
import './Livres/pageLivre.dart';
import '../menu.dart'; // Adapté à ton projet

class FavoritesLivresPage extends StatefulWidget {
  const FavoritesLivresPage({super.key});

  @override
  State<FavoritesLivresPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesLivresPage> {
  final dbService = DatabaseService();
  late Future<List<Book>> futureFavorites;

  @override
  void initState() {
    super.initState();
    futureFavorites = _loadFavorites();
  }

  Future<List<Book>> _loadFavorites() async {
    final favMaps = await dbService.getFavoritesLivre();
    return favMaps
        .map((m) => Book(
            id: m['id'],
            titre: m['titre'],
            auteur: m['auteur'],
            cover: m['cover'],
            year: m['year'],
            subtitle: m['subtitle'],
            nbrPages: m['nbrPages'],
            langue: m['langue'],
            listSommaires: m['listSommaires'],
            keyTheme: ''))
        .toList();
  }

  void _openBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookImagesPage(
            livreId: book.id,
            titreLivre: book.titre,
            listSommaires: book.listSommaires),
      ),
    );
  }

  void _showActionSheet(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Lire'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBookDetail(book);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer des favoris'),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Supprimer des favoris
                  await dbService.removeFavoriteLivre(book.id);
                  setState(() {
                    // Recharger la liste des favoris
                    futureFavorites = _loadFavorites();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Livre supprimé des favoris : ${book.titre}')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Annuler'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favoris',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 6,
        backgroundColor: Colors.deepPurple,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: const SideMenu(),
      body: FutureBuilder<List<Book>>(
        future: futureFavorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'Aucun livre en favoris',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final book = favorites[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showActionSheet(context, book),
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Cover du livre (Hero pour transition fluide)
                      Hero(
                        tag: 'book_${book.id}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Image.network(
                            book.cover,
                            height: 120,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Infos du livre
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.titre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${book.auteur} • ${book.year}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${book.langue}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (book.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  book.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Badge pages
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${book.nbrPages} pages',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
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
      ),
    );
  }
}
