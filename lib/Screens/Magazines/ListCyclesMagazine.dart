import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../../Models/CycleMagazineModel.dart';
import '../../Models/pageCycleMagazineModel.dart';
import 'CycleMagazinePage.dart';
import '../../database_service.dart';
import '../../Services/cache_service.dart';
import '../../menu.dart'; // Adapté à ton projet
import 'package:shared_preferences/shared_preferences.dart';

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

  final MagazineCacheService _cacheService = MagazineCacheService();

  ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  ValueNotifier<bool> isDownloading = ValueNotifier(false);

  // Ajouter un set pour garder en mémoire les favoris chargés depuis la BD
  Set<String> favoriteIds = {};

  List<CycleMagazine> cycles = [];
  List<CycleMagazine> cyclesTemp = [];

  List<String> selectedTypes = [];
  List<String> selectedYears = [];

  String get filterKey => "filters_cycles_${widget.magazineId}";

  @override
  void initState() {
    super.initState();
    futureCyclesMagazine = fetchCyclesMagazine(widget.magazineId).then((data) {
      cycles = data;
      cyclesTemp = data;
      loadFilters(); // 🔥 charger filtres
      return data;
    });
    // futureCyclesMagazine = fetchCyclesMagazine(widget.magazineId);
    // loadFavorites();
  }

  String extractYear(String periode) {
    final regex = RegExp(r'\d{4}');
    final match = regex.firstMatch(periode);
    return match?.group(0) ?? "Unknown";
  }

  void applyFilter({
    required List<String> types,
    required List<String> years,
  }) {
    List<CycleMagazine> filtered = cyclesTemp;

    ////////////////////////////////////////////////////////////
    /// TYPE
    ////////////////////////////////////////////////////////////
    // print('types = ${types}');
    if (types.isNotEmpty) {
      filtered = filtered.where((c) => types.contains(c.type)).toList();
    }

    ////////////////////////////////////////////////////////////
    /// YEAR
    ////////////////////////////////////////////////////////////
    // print('years = ${years}');
    if (years.isNotEmpty) {
      filtered = filtered.where((c) {
        final year = extractYear(c.periode);
        // print("year extracted = [$year]");
        // print("years filter = $years");
        return years.any((y) => year.contains(y));
      }).toList();
    }

    // print("filtered = ${filtered}");

    setState(() {
      cycles = filtered;
      futureCyclesMagazine = Future.value(filtered); // ✅ FIX
    });
  }

  Future<void> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(filterKey);

    if (data == null) return;

    final decoded = jsonDecode(data);

    selectedTypes = List<String>.from(decoded['types'] ?? []);
    selectedYears = List<String>.from(decoded['years'] ?? []);

    applyFilter(types: selectedTypes, years: selectedYears);
  }

  Future<void> resetFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(filterKey);

    setState(() {
      cycles = cyclesTemp;
      selectedTypes = [];
      selectedYears = [];
    });
  }

  Future<void> saveFilters({
    required List<String> types,
    required List<String> years,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      "types": types,
      "years": years,
    };

    await prefs.setString(filterKey, jsonEncode(data));
  }

  void openFilterModal() {
    List<String> tempTypes = List.from(selectedTypes);
    List<String> tempYears = List.from(selectedYears);

    final allTypes = cyclesTemp.map((e) => e.type).toSet().toList();
    final allYears =
        cyclesTemp.map((e) => extractYear(e.periode)).toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text("🎯 Filtrer les cycles",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 20),

                    ////////////////////////////////////////////////////////////
                    /// TYPES
                    ////////////////////////////////////////////////////////////
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Type",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    Wrap(
                      spacing: 8,
                      children: allTypes.map((type) {
                        final isSelected = tempTypes.contains(type);

                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            setStateModal(() {
                              if (val) {
                                tempTypes.add(type);
                              } else {
                                tempTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    ////////////////////////////////////////////////////////////
                    /// YEARS
                    ////////////////////////////////////////////////////////////
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Année",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    Wrap(
                      spacing: 8,
                      children: allYears.map((year) {
                        final isSelected = tempYears.contains(year);

                        return FilterChip(
                          label: Text(year),
                          selected: isSelected,
                          onSelected: (val) {
                            setStateModal(() {
                              if (val) {
                                tempYears.add(year);
                              } else {
                                tempYears.remove(year);
                              }
                              print("tempYears = ${tempYears}");
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    ////////////////////////////////////////////////////////////
                    /// BUTTONS
                    ////////////////////////////////////////////////////////////
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await resetFilters();
                              Navigator.pop(context);
                            },
                            child: const Text("Reset"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              applyFilter(
                                types: tempTypes,
                                years: tempYears,
                              );

                              await saveFilters(
                                types: tempTypes,
                                years: tempYears,
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
              ),
            );
          },
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////

  Future<List<CycleMagazinePageImage>> fetchCycleMagazineImages(
      String id) async {
    final cacheService = MagazineCacheService();

    try {
      final response = await http.post(
        Uri.parse(
            'https://backend-mega-book-theta.vercel.app/api/listPagesByMagazine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"cycle_magazine_id": id}),
      );

      final decoded = json.decode(response.body);
      final list = decoded["listPageByNumeroMagazine"] as List;

      return list.map((e) => CycleMagazinePageImage.fromJson(e)).toList();
    } catch (e) {
      /// 🔥 OFFLINE MODE
      final cachedPages = await cacheService.getPages(id);

      if (cachedPages != null) {
        return cachedPages
            .map((e) => CycleMagazinePageImage.fromJson(e))
            .toList();
      }

      throw Exception("Pas de données offline disponibles");
    }
  }

  Future<void> _downloadCycle(CycleMagazine cycle) async {
    final cacheService = MagazineCacheService();

    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;

      /// 🔹 1. Cache COVER
      final localCover = await cacheService.cacheImage(cycle.cover);

      /// 🔹 2. Save cycle
      await cacheService.saveCycle({
        "id": cycle.id,
        "titre": cycle.titre,
        "periode": cycle.periode,
        "cover": localCover,
        "cover_network": cycle.cover,
        "type": cycle.type,
        "subtitle": cycle.subtitle,
        "nbrPages": cycle.nbrPages,
        "keyMagazine": cycle.keyMagazine,
      });

      /// 🔹 3. Fetch pages
      final pages = await fetchCycleMagazineImages(cycle.id);

      List<Map<String, dynamic>> savedPages = [];

      /// 🔥 4. CACHE PAGE PAR PAGE
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];

        try {
          final localImage = await cacheService.cacheImage(page.urlImage);
          print("localImage = ${localImage}");

          savedPages.add({
            ...page.toJson(),
            "image_local": localImage,
          });
        } catch (e) {
          print("❌ erreur cache page: $e");
        }

        downloadProgress.value = (i + 1) / pages.length;
      }

      /// 🔹 5. SAVE PAGES
      await cacheService.savePages(cycle.id, savedPages);

      isDownloading.value = false;

      print("✅ Téléchargement terminé");
      Navigator.pop(context);
    } catch (e) {
      isDownloading.value = false;
      print("❌ Erreur téléchargement: $e");
    }
  }

  void _showDownloadProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Téléchargement"),
          content: ValueListenableBuilder<double>(
            valueListenable: downloadProgress,
            builder: (context, progress, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text("${(progress * 100).toStringAsFixed(0)} %"),
                ],
              );
            },
          ),
        );
      },
    );

    /// fermer automatiquement quand fini
    /* isDownloading.addListener(() {
      if (!isDownloading.value) {
        Navigator.pop(context);
      }
    });*/
  }

  void _showActionSheet(BuildContext context, CycleMagazine CycleMagazine) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return FutureBuilder<bool>(
          future: _cacheService.isCycleCached(CycleMagazine.id),
          builder: (context, snapshot) {
            final isCached = snapshot.data ?? false;

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
                        ),
                      );
                    },
                  ),

                  /// ❤️ FAVORIS
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

                  /// 💾 OFFLINE CACHE
                  ListTile(
                    leading: Icon(
                      isCached ? Icons.check_circle : Icons.download,
                    ),
                    title: Text(
                      isCached
                          ? 'Déjà téléchargé'
                          : 'Télécharger pour lecture hors ligne',
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      _showDownloadProgressDialog(context);
                      await _downloadCycle(CycleMagazine);
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
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titreMagazine,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilterModal,
          ),
        ],
      ),
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
              child: Text('Aucun livre trouvé pour ce thème.'),
            );
          }

          final cyclesMagazine = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cyclesMagazine.length,
            itemBuilder: (context, index) {
              final cycle = cyclesMagazine[index];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showActionSheet(context, cycle),
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Cover avec Hero
                      Hero(
                        tag: 'cycle_${cycle.id}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Image.network(
                            cycle.cover,
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Texte à droite
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cycle.titre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cycle.periode,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
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
                          '${cycle.nbrPages} pages',
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
