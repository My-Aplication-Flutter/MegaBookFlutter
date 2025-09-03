
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Models/CycleMagazineModel.dart';
import 'CycleMagazinePage.dart';
import '../../database_service.dart';
import '../../menu.dart'; // Adapté à ton projet

class CyclesByMagazinePage extends StatefulWidget {
  final String magazineId;
  final String titreMagazine;

  const CyclesByMagazinePage(
      {super.key, required this.magazineId, required this.titreMagazine});

  @override
  State<CyclesByMagazinePage> createState() => _CyclesByMagazinePageState();
}

class _CyclesByMagazinePageState extends State<CyclesByMagazinePage> {
  late Future<List<CycleMagazine>> futureCyclesMagazine;
  final DatabaseService dbService = DatabaseService();

  // Ajouter un set pour garder en mémoire les favoris chargés depuis la BD
  Set<String> favoriteIds = {};

  @override
  void initState() {
    super.initState();
    futureCyclesMagazine = fetchCyclesMagazine(widget.magazineId);
    // loadFavorites();
  }

  void loadFavorites() async {
    final favs = await dbService.getFavoritesCycleMagazines();
    setState(() {
      favoriteIds = favs.map((e) => e['id'] as String).toSet();
    });
  }

  void _toggleFavorite(CycleMagazine CycleMagazine) async {
    final isFav = favoriteIds.contains(CycleMagazine.id);
    if (isFav) {
      await dbService.removeCycleMagazine(CycleMagazine.id);
      setState(() {
        favoriteIds.remove(CycleMagazine.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Livre retiré des favoris : ${CycleMagazine.titre}')));
    } else {
      /************************************************** */
      // Appel modifié avec affichage du dialog
      await dbService.addCycleMagazine(
        id: CycleMagazine.id,
        titre: CycleMagazine.titre,
        periode: CycleMagazine.periode,
        cover: CycleMagazine.cover,
        type: CycleMagazine.type,
        subtitle: CycleMagazine.subtitle,
        nbrPages: CycleMagazine.nbrPages,
        keyMagazine: CycleMagazine.keyMagazine,
      );

// Affiche une boîte de dialogue avec la valeur de insertedId
      /* showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Insertion réussie'),
          content: Text('ID inséré : $insertedId'),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );*/

      /*********************************************** */

      setState(() {
        favoriteIds.add(CycleMagazine.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Magazine ajouté aux favoris : ${CycleMagazine.titre}')));
    }
  }

  Future<List<CycleMagazine>> fetchCyclesMagazine(String keyMagazine) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listNumeroMagazine'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"keyMagazine": keyMagazine}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = decoded["listNumerosMagazine"] as List<dynamic>;
      return list.map((e) => CycleMagazine.fromJson(e)).toList();
    } else {
      throw Exception('Erreur de récupération des numeros des magazines');
    }
  }

  void _showActionSheet(BuildContext context, CycleMagazine CycleMagazine) {
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CycleMagazineImagesPage(
                          cycleMagazineId: CycleMagazine.id,
                          titreCycleMagazine: CycleMagazine.titre,
                        ),
                      ));
                },
              ),
              ListTile(
                leading: favoriteIds.contains(CycleMagazine.id)
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                title: favoriteIds.contains(CycleMagazine.id)
                    ? const Text('Retirer des favoris')
                    : const Text('Ajouter au favoris'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleFavorite(CycleMagazine);
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
        title: Text(widget.titreMagazine,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      //drawer: const SideMenu(),
      body: FutureBuilder<List<CycleMagazine>>(
        future: futureCyclesMagazine,
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
          final CyclesMagazine = snapshot.data!;
          return ListView.builder(
            itemCount: CyclesMagazine.length,
            itemBuilder: (context, index) {
              final CycleMagazine = CyclesMagazine[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(CycleMagazine.cover),
                    radius: 25,
                  ),
                  title: Text(CycleMagazine.titre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${CycleMagazine.periode}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('${CycleMagazine.nbrPages} pages',
                      style: const TextStyle(color: Colors.grey)),
                  onTap: () => _showActionSheet(context, CycleMagazine),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
