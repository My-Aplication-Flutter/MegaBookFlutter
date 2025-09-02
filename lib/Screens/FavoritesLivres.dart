import 'package:flutter/material.dart';
import '../database_service.dart';
import '../Models/livre.dart';
import 'pageLivre.dart';
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
        ),
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
        title: const Text('Favoris'),
        backgroundColor: Colors.deepPurple,
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
            return const Center(child: Text('Aucun livre en favoris'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final book = favorites[index];
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
                  onTap: () => _showActionSheet(context, book),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
