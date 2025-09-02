import 'package:flutter/material.dart';
import '../database_service.dart';
import '../Models/CycleMagazineModel.dart';
import 'CycleMagazinePage.dart';
import '../menu.dart'; // Adapté à ton projet

class FavoritesMagazinesPage extends StatefulWidget {
  const FavoritesMagazinesPage({super.key});

  @override
  State<FavoritesMagazinesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesMagazinesPage> {
  final dbService = DatabaseService();
  late Future<List<CycleMagazine>> futureFavorites;

  @override
  void initState() {
    super.initState();
    futureFavorites = _loadFavorites();
  }

  void showFavMapsDialog(BuildContext context, List<CycleMagazine> favMaps) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Liste des magazines favoris'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: favMaps.map((magazine) {
                // Adaptez ici selon les champs à afficher dans CycleMagazine
                return Text(
                    'Titre : ${magazine.titre}\nId : ${magazine.id}\n---');
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<CycleMagazine>> _loadFavorites() async {
    final favMaps = await dbService.getFavoritesCycleMagazines();
    // showFavMapsDialog(context, favMaps);

    return favMaps
        .map((m) => CycleMagazine(
            id: m["id"],
            titre: m["titre"],
            periode: m["periode"],
            cover: m["cover"],
            subtitle: m["subtitle"],
            nbrPages: m["nbrPages"],
            type: m["type"],
            keyMagazine: m["keyMagazine"]))
        .toList();
  }

  void _openCycleMagazineDetail(CycleMagazine cycleMagazine) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CycleMagazineImagesPage(
            cycleMagazineId: cycleMagazine.id,
            titreCycleMagazine: cycleMagazine.titre,
          ),
        ));
  }

  void _showActionSheet(BuildContext context, CycleMagazine cycleMagazine) {
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
                  _openCycleMagazineDetail(cycleMagazine);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer des favoris'),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Supprimer des favoris
                  await dbService.removeCycleMagazine(cycleMagazine.id);
                  setState(() {
                    // Recharger la liste des favoris
                    futureFavorites = _loadFavorites();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Magazine supprimé des favoris : ${cycleMagazine.titre}')),
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
      body: FutureBuilder<List<CycleMagazine>>(
        future: futureFavorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(child: Text('Aucune magazine en favoris'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final cycleMagazine = favorites[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(cycleMagazine.cover),
                    radius: 25,
                  ),
                  title: Text(cycleMagazine.titre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${cycleMagazine.periode}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('${cycleMagazine.nbrPages} pages',
                      style: const TextStyle(color: Colors.grey)),
                  onTap: () => _showActionSheet(context, cycleMagazine),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
