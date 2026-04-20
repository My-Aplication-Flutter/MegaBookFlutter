import 'package:flutter/material.dart';
import '../database_service.dart';
import '../Models/CycleMagazineModel.dart';
import './Magazines/CycleMagazinePage.dart';
import '../Models/livre.dart';
import './Livres/pageLivre.dart';
import "./../Models/FavorisModel.dart";
import '../menu.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final dbService = DatabaseService();
  late Future<List<FavoriteItem>> futureFavorites;

  @override
  void initState() {
    super.initState();
    futureFavorites = dbService.getAllFavorites();
  }

  void _openItem(FavoriteItem item) {
    if (item.type == "book") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookImagesPage(
            livreId: item.id,
            titreLivre: item.title,
            listSommaires: [],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CycleMagazineImagesPage(
            cycleMagazineId: item.id,
            titreCycleMagazine: item.title,
          ),
        ),
      );
    }
  }

  void _deleteItem(FavoriteItem item) async {
    if (item.type == "book") {
      await dbService.removeFavoriteLivre(item.id);
    } else {
      await dbService.removeCycleMagazine(item.id);
    }

    setState(() {
      futureFavorites = dbService.getAllFavorites();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item.title} supprimé")),
    );
  }

  void _showAction(FavoriteItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Lire"),
              onTap: () {
                Navigator.pop(context);
                _openItem(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Supprimer"),
              onTap: () {
                Navigator.pop(context);
                _deleteItem(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type == "book"
            ? Colors.blue.withOpacity(0.1)
            : Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type == "book" ? "Livre" : "Magazine",
        style: TextStyle(
          fontSize: 11,
          color: type == "book" ? Colors.blue : Colors.deepPurple,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoris"),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const SideMenu(),
      body: FutureBuilder<List<FavoriteItem>>(
        future: futureFavorites,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(child: Text("Aucun favori"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];

              return InkWell(
                onTap: () => _showAction(item),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          item.image,
                          height: 120,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(item.subtitle),
                              const SizedBox(height: 6),
                              _buildBadge(item.type),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text("${item.pages} p."),
                      )
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
