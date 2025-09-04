import 'package:flutter/material.dart';
import '../database_service.dart';
import '../Models/CycleMagazineModel.dart';
import './Magazines/CycleMagazinePage.dart';
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
        title: const Text(
          'Favoris',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
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
            return const Center(
              child: Text(
                'Aucune magazine en favoris',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final cycleMagazine = favorites[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showActionSheet(context, cycleMagazine),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover rectangulaire
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          cycleMagazine.cover,
                          height: 120,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Infos texte
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cycleMagazine.titre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cycleMagazine.periode,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Badge pages
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 16),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cycleMagazine.nbrPages} pages',
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
