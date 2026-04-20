import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MagazineCacheService {
  static const String cyclesKey = "offline_cycles";
  static const String pagesKeyPrefix = "offline_pages_";

  ////////////////////////////////////////////////////////////
  /// 📦 CACHE IMAGE
  ////////////////////////////////////////////////////////////
  Future<String> cacheImage(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    print("📦 Image cachée: ${file.path}");
    return file.path;
  }

  ////////////////////////////////////////////////////////////
  /// 💾 SAVE CYCLE
  ////////////////////////////////////////////////////////////
  Future<void> saveCycle(Map<String, dynamic> cycle) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> stored = prefs.getStringList(cyclesKey) ?? [];

    stored.add(jsonEncode(cycle));

    await prefs.setStringList(cyclesKey, stored);
  }

  ////////////////////////////////////////////////////////////
  /// 📖 SAVE PAGES
  ////////////////////////////////////////////////////////////
  Future<void> savePages(
      String cycleId, List<Map<String, dynamic>> pages) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> cachedPages = [];

    for (var page in pages) {
      try {
        /// 🔥 cache image page
        final localPath = await cacheImage(page["imageUrl"]);

        cachedPages.add({
          ...page,
          "image_local": localPath,
        });
      } catch (e) {
        print("❌ erreur cache image page: $e");
      }
    }

    await prefs.setString(
      "$pagesKeyPrefix$cycleId",
      jsonEncode(cachedPages),
    );
  }

  ////////////////////////////////////////////////////////////
  /// 📥 GET PAGES OFFLINE
  ////////////////////////////////////////////////////////////
  Future<List<dynamic>?> getPages(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString("$pagesKeyPrefix$cycleId");

    if (data == null) return null;

    return jsonDecode(data);
  }

  ////////////////////////////////////////////////////////////
  /// ✅ CHECK SI DÉJÀ CACHÉ
  ////////////////////////////////////////////////////////////
  Future<bool> isCycleCached(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("$pagesKeyPrefix$cycleId");
  }

  Future<void> replaceCycleList(List<Map<String, dynamic>> cycles) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = cycles.map((e) => jsonEncode(e)).toList();

    await prefs.setStringList(cyclesKey, encoded);
  }

  ////////////////////////////////////////////////////////////
  /// 📥 GET CYCLES OFFLINE
////////////////////////////////////////////////////////////
  Future<List<Map<String, dynamic>>> getCycles() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getStringList(cyclesKey);

    if (stored == null || stored.isEmpty) {
      return [];
    }

    try {
      return stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      print("❌ erreur parsing cycles: $e");
      return [];
    }
  }
}
