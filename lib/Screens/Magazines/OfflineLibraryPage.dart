import 'dart:io';
import 'package:flutter/material.dart';
import '../../Services/cache_service.dart';
import 'OfflineCycleMagazinePage.dart';

class OfflineLibraryPage extends StatefulWidget {
  const OfflineLibraryPage({super.key});

  @override
  State<OfflineLibraryPage> createState() => _OfflineLibraryPageState();
}

class _OfflineLibraryPageState extends State<OfflineLibraryPage> {
  final MagazineCacheService _cacheService = MagazineCacheService();

  List<Map<String, dynamic>> cycles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  ////////////////////////////////////////////////////////////
  /// 📥 LOAD OFFLINE DATA
  ////////////////////////////////////////////////////////////
  Future<void> _loadOfflineData() async {
    final data = await _cacheService.getCycles();

    setState(() {
      cycles = data;
      isLoading = false;
    });
  }

  ////////////////////////////////////////////////////////////
  /// 🗑 DELETE CYCLE (FIX IMPORTANT)
  ////////////////////////////////////////////////////////////
  Future<void> _deleteCycle(String id) async {
    final all = await _cacheService.getCycles();

    all.removeWhere((c) => c['id'] == id);

    /// 🔥 IMPORTANT : on réécrit via SharedPreferences directement
    await _cacheService.replaceCycleList(all);

    setState(() {
      cycles = all;
    });
  }

  ////////////////////////////////////////////////////////////
  /// 🖼 COVER OFFLINE SAFE RENDER
  ////////////////////////////////////////////////////////////
  Widget _buildCover(String? coverPath, String? networkUrl) {
    if (coverPath != null && coverPath.isNotEmpty) {
      return Image.file(
        File(coverPath),
        width: 60,
        fit: BoxFit.cover,
      );
    }

    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        width: 60,
        fit: BoxFit.cover,
      );
    }

    return const Icon(Icons.image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bibliothèque Offline"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cycles.isEmpty
              ? const Center(child: Text("Aucun magazine téléchargé"))
              : ListView.builder(
                  itemCount: cycles.length,
                  itemBuilder: (context, index) {
                    final cycle = cycles[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: _buildCover(
                            cycle['cover'], // local path
                            cycle['cover_network'] // fallback
                            ),
                        title: Text(
                          cycle['titre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cycle['subtitle'] ?? ''),
                            Text("Période: ${cycle['periode'] ?? ''}"),
                            Text("Pages: ${cycle['nbrPages'] ?? ''}"),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "read",
                              child: Text("Lire"),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Text("Supprimer"),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == "read") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OfflineCycleMagazinePage(
                                    cycleMagazineId: cycle['id'],
                                    titreCycleMagazine: cycle['titre'],
                                  ),
                                ),
                              );
                            } else if (value == "delete") {
                              _deleteCycle(cycle['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
