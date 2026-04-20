import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../Models/livre.dart';
import 'pageLivre.dart';
import '../../database_service.dart';
import '../../menu.dart'; // Adapté à ton projet
import '../../Models/pageLivre.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BooksByThemePage extends StatefulWidget {
  final String theme;

  const BooksByThemePage({super.key, required this.theme});

  @override
  State<BooksByThemePage> createState() => _BooksByThemePageState();
}

class _BooksByThemePageState extends State<BooksByThemePage> {
  late Future<List<Book>> futureBooks;
  final DatabaseService dbService = DatabaseService();
  late Future<List<BookPageImage>> futureImages;
  double _downloadProgress = 0.0;

  List<Book> books = [];
  List<Book> booksTemp = [];

  List<String> selectedYears = [];
  List<String> selectedLangues = [];
  List<String> selectedAuthors = [];

  String get filterKey => "filters_livres_${widget.theme}";

  // Ajouter un set pour garder en mémoire les favoris chargés depuis la BD
  Set<String> favoriteIds = {};

  ScrollController _miniSliderController = ScrollController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks(widget.theme).then((data) {
      books = data;
      booksTemp = data;
      loadFilters(); // 🔥 charger filtres
      return data;
    });
    // futureBooks = fetchBooks(widget.theme);
    loadFavorites();
  }

  Future<void> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(filterKey);

    if (data == null) return;

    final decoded = jsonDecode(data);

    selectedAuthors = List<String>.from(decoded['authors'] ?? []);
    selectedYears = List<String>.from(decoded['years'] ?? []);
    selectedLangues = List<String>.from(decoded['langues'] ?? []);

    applyFilter(
      authors: selectedAuthors,
      years: selectedYears,
      langues: selectedLangues,
    );
  }

  Future<void> resetFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(filterKey);

    setState(() {
      books = booksTemp;
      selectedAuthors = [];
      selectedYears = [];
      selectedLangues = [];
    });
  }

  Future<void> saveFilters({
    required List<String> authors,
    required List<String> years,
    required List<String> langues,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      "authors": authors,
      "years": years,
      "langues": langues,
    };

    await prefs.setString(filterKey, jsonEncode(data));
  }

  void openFilterModal() {
    List<String> tempYears = List.from(selectedYears);
    List<String> tempAuthors = List.from(selectedAuthors);
    List<String> tempLangues = List.from(selectedLangues);

    final allYears = booksTemp.map((e) => e.year.toString()).toSet().toList();

    final allAuthors = booksTemp.map((e) => e.auteur).toSet().toList();

    final allLangues = booksTemp.map((e) => e.langue).toSet().toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🎯 Filtrer les livres",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),

                  /// Langues
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Langue",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  Wrap(
                    spacing: 8,
                    children: allLangues.map((langue) {
                      return FilterChip(
                        label: Text(langue),
                        selected: tempLangues.contains(langue),
                        onSelected: (val) {
                          setStateModal(() {
                            if (val) {
                              tempLangues.add(langue);
                            } else {
                              tempLangues.remove(langue);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// YEARS
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Année",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  Wrap(
                    spacing: 8,
                    children: allYears.map((year) {
                      return FilterChip(
                        label: Text(year),
                        selected: tempYears.contains(year),
                        onSelected: (val) {
                          setStateModal(() {
                            if (val) {
                              tempYears.add(year);
                            } else {
                              tempYears.remove(year);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// AUTHORS
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Auteur",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  Wrap(
                    spacing: 8,
                    children: allAuthors.map((author) {
                      return FilterChip(
                        label: Text(author),
                        selected: tempAuthors.contains(author),
                        onSelected: (val) {
                          setStateModal(() {
                            if (val) {
                              tempAuthors.add(author);
                            } else {
                              tempAuthors.remove(author);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              books = booksTemp;
                              selectedYears = [];
                              selectedAuthors = [];
                              selectedLangues = [];
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Reset"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            selectedYears = tempYears;
                            selectedAuthors = tempAuthors;
                            selectedLangues = tempLangues;

                            applyFilter(
                              years: selectedYears,
                              authors: selectedAuthors,
                              langues: selectedLangues,
                            );

                            Navigator.pop(context);
                          },
                          child: const Text("Appliquer"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void applyFilter({
    required List<String> years,
    required List<String> authors,
    required List<String> langues,
  }) {
    List<Book> filtered = booksTemp;

    ////////////////////////////////////////////////////////////
    /// YEAR
    ////////////////////////////////////////////////////////////
    if (years.isNotEmpty) {
      filtered = filtered.where((b) {
        return years.contains(b.year.toString());
      }).toList();
    }

    ////////////////////////////////////////////////////////////
    /// AUTHOR
    ////////////////////////////////////////////////////////////
    if (authors.isNotEmpty) {
      filtered = filtered.where((b) {
        return authors.contains(b.auteur);
      }).toList();
    }

    ////////////////////////////////////////////////////////////
    /// Langue
    ////////////////////////////////////////////////////////////
    if (langues.isNotEmpty) {
      filtered = filtered.where((b) {
        return langues.contains(b.langue);
      }).toList();
    }

    setState(() {
      books = filtered;
      futureBooks = Future.value(filtered); // ✅ IMPORTANT
    });
  }

  ////////////////////////////////////////////////////////////

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
                          listSommaires: book.listSommaires),
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
                  futureImages = fetchBookImages(book.id);
                  _downloadBook(book);
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

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (status.isGranted) {
        // Autorisation accordée
        print("Accès au stockage autorisé");
      } else {
        // Autorisation refusée
        print("Accès au stockage refusé");
      }
    } else {
      // Déjà accordée
      print("Accès au stockage déjà accordé");
    }
  }

  void _showDownloadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text("Téléchargement..."),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: _downloadProgress),
            SizedBox(height: 16),
            Text(
                "Progression: ${(_downloadProgress * 100).toStringAsFixed(0)}%"),
          ],
        ),
      ),
    );
  }

  void _showDownloadProgressNotification() {
    final snackBar = SnackBar(
      duration: const Duration(
          minutes: 10), // durée longue pour ne pas disparaître trop vite
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          ),
          const SizedBox(width: 12),
          Text("${(_downloadProgress * 100).toStringAsFixed(0)}%"),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);

    if (_downloadProgress >= 1.0) {
      // Quand téléchargement terminé, ferme le SnackBar
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      return;
    }
  }

  Future<void> _downloadBook(Book book) async {
    bool _isDownloading = false;

    final images = await futureImages;
    int success = 0;

    // Vérifie la permission de stockage avant de télécharger
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de stockage refusée')));
        return; // stoppe le téléchargement
      }
    }

    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      //final appDocDir = await getApplicationDocumentsDirectory();
      // final bookDir = Directory(p.join(appDocDir.path, 'megabook', book.titre));
      final appDocDir = await getExternalStorageDirectory();
      if (appDocDir == null) {
        // Gérer le cas où le dossier externe n'est pas accessible, par exemple :
        throw Exception("Storage directory not accessible");
      }
      print('Chemin stockage externe : ${appDocDir.path}');
      final bookDir = Directory(p.join(appDocDir.path, 'megabook', book.titre));
      if (!await bookDir.exists()) {
        await bookDir.create(recursive: true);
      }

      /*************************************************** */
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        final imageUrl = img.urlImage;
        final imageName = '${img.numPage}_${img.id}.jpg';

        /* if (i == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${imageUrl}')),
          );
        }*/

        final file = File(p.join(bookDir.path, imageName));
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          success++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Echec telechargement image')));
        }

        // Met à jour la progression
        setState(() {
          _downloadProgress = (i + 1) / images.length;
          _showDownloadProgressNotification();
        });
        // Ajoute une pause d'1 seconde
        await Future.delayed(const Duration(seconds: 1));
      }

      //  await dbService.saveOfflineBookPages(book.id, bookDir.path, images.length);

      if (mounted) {
        Navigator.of(context).pop(); // ferme le dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pages téléchargées : $success/${images.length}')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur téléchargement images : $e')));
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
    }
  }

  Future<List<BookPageImage>> fetchBookImages(String livreId) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listPagesByLivre'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"livre_id": livreId}),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = decoded["listPageByLivre"] as List<dynamic>;
      return list.map((e) => BookPageImage.fromJson(e)).toList();
    } else {
      throw Exception('Erreur récupération images');
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilterModal,
          ),
        ],
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
                                const SizedBox(height: 8),
                                Text(
                                  "${book.langue}",
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
