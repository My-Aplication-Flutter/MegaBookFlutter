import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../Models/livre.dart';
import 'pageLivre.dart';
import '../../database_service.dart';
import '../../menu.dart'; // Adapté à ton projet

class BooksByThemePage extends StatefulWidget {
  final String theme;

  const BooksByThemePage({super.key, required this.theme});

  @override
  State<BooksByThemePage> createState() => _BooksByThemePageState();
}

class _BooksByThemePageState extends State<BooksByThemePage> {
  late Future<List<Book>> futureBooks;
  final DatabaseService dbService = DatabaseService();

  // Ajouter un set pour garder en mémoire les favoris chargés depuis la BD
  Set<String> favoriteIds = {};

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks(widget.theme);
    loadFavorites();
  }

  void loadFavorites() async {
    final favs = await dbService.getFavoritesLivre();
    setState(() {
      favoriteIds = favs.map((e) => e['id'] as String).toSet();
    });
  }

  void _toggleFavorite(Book book) async {
    final isFav = favoriteIds.contains(book.id);
    if (isFav) {
      await dbService.removeFavoriteLivre(book.id);
      setState(() {
        favoriteIds.remove(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Livre retiré des favoris : ${book.titre}')));
    } else {
      await dbService.addFavoriteLivre(
        id: book.id,
        titre: book.titre,
        auteur: book.auteur,
        cover: book.cover,
        year: book.year,
        subtitle: book.subtitle,
        nbrPages: book.nbrPages,
      );
      setState(() {
        favoriteIds.add(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Livre ajouté aux favoris : ${book.titre}')));
    }
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
              ListTile(
                leading: favoriteIds.contains(book.id)
                    ? const Icon(Icons.favorite)
                    : const Icon(Icons.favorite_border),
                title: favoriteIds.contains(book.id)
                    ? const Text('Retirer des favoris')
                    : const Text('Ajouter au favoris'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleFavorite(book);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Télécharger pour lire hors-ligne'),
                onTap: () {
                  Navigator.pop(ctx);
                  // _downloadBook(book);
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

  /* 

  Future<void> checkStoragePermission() async {
  if (await Permission.storage.request().isGranted) {
    print("Permission stockage accordée");
  } else {
    print("Permission stockage refusée");
  }
}

  Future<void> _downloadBookImagesBis(Book book, Future<List<BookPageImage>> futureImages) async {
  try {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final appDocDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory(p.join(appDocDir.path, 'megabook', book.titre));
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }

    final images = await futureImages;
    int success = 0;
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      final imageUrl = img.url;
      final imageName = '${img.numPage}_${img.id_image}.jpg';

      final file = File(p.join(bookDir.path, imageName));
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        success++;
      }
      // Met à jour la progression
      setState(() {
        _downloadProgress = (i + 1) / images.length;
      });
      // Ajoute une pause d'1 seconde
      await Future.delayed(const Duration(seconds: 1));
    }

    await dbService.saveOfflineBookPages(book.id, bookDir.path, images.length);

    if (mounted) {
      Navigator.of(context).pop(); // ferme le dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pages téléchargées : $success/${images.length}'))
      );
    }

  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur téléchargement images : $e'))
      );
    }
  } finally {
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0;
    });
  }
}

  
  // Télécharge toutes les images du livre (pages) pour un accès offline
Future<void> _downloadBookImages(Book book, Future<List<BookPageImage>> futureImages) async {
  try {
    // Répertoire cible : megabook/nom_livre
    final appDocDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory(p.join(appDocDir.path, 'megabook', book.titre));
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }

    // Récupérer la liste d'images
    final images = await futureImages;

    int success = 0;

    for (final img in images) {
      final imageUrl = img.url;
      final imageName = '${img.numPage}_${img.id_image}.jpg'; // nommage perso

      final file = File(p.join(bookDir.path, imageName));
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        success++;
      }
      // Optionnel : gérer else ou progress
    }

    // Enregistre les infos dans ta base si nécessaire
    await dbService.saveOfflineBookPages(book.id, bookDir.path, images.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pages téléchargées : $success/${images.length}')),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur téléchargement images : $e')),
    );
  }
}
  
  
  
  Future<void> _downloadBook(Book book) async {
    try {
      // Remplace book.downloadUrl par la vraie propriété contenant l’URL du fichier à télécharger
      final url = book.downloadUrl;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Nom du fichier
        final filename =
            '${book.titre}_${book.id}.pdf'; // ajuste selon le format

        // Dossier Documents local
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        // Sauvegarde l'info du livre offline dans ta base (ajouter showSnackBar)
        // await dbService.saveOfflineBook(book, file.path);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Livre téléchargé avec succès : ${book.titre}')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Échec du téléchargement')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
  
  Future<void> saveOfflineBook(Book book, String localPath) async {
  // Ajoute ou met à jour les infos du livre offline dans SQLite
  await insertOfflineBook({
    'id': book.id,
    'titre': book.titre,
    'path': localPath,
    // ...autres champs utiles
  });
}
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.theme,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      // drawer: const SideMenu(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8F5FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Book>>(
          future: futureBooks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur : ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (snapshot.data == null || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun livre trouvé pour ce thème.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              );
            }

            final books = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 6,
                  shadowColor: Colors.deepPurple.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _showActionSheet(context, book),
                    child: Container(
                      height: 150, // 🔹 Grande card
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Image grande
                          Hero(
                            tag: "book_${book.titre}_${book.year}",
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                book.cover,
                                height: 130,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Texte & infos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  book.titre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${book.auteur} • ${book.year}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (book.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    book.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),

                          // Pages & icône
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.menu_book_rounded,
                                  color: Colors.deepPurple, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                "${book.nbrPages} p.",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
