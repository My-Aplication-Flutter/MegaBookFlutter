import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'megabook.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favoritesLivres (
        id TEXT PRIMARY KEY,
        titre TEXT,
        auteur TEXT,
        cover TEXT,
        year TEXT,
        subtitle TEXT,
        nbrPages INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE favoritesCyclesMagazines (
        id TEXT PRIMARY KEY,
        titre TEXT,
        cover TEXT,
        type TEXT,
        keyMagazine TEXT,
        periode TEXT,
        subtitle TEXT,
        nbrPages INTEGER
      )
    ''');
  }

  Future<void> addFavoriteLivre({
    required String id,
    required String titre,
    required String auteur,
    required String cover,
    required String year,
    required String subtitle,
    required int nbrPages,
  }) async {
    final db = await database;
    await db.insert(
      'favoritesLivres',
      {
        'id': id,
        'titre': titre,
        'auteur': auteur,
        'cover': cover,
        'year': year,
        'subtitle': subtitle,
        'nbrPages': nbrPages,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavoriteLivre(String id) async {
    final db = await database;
    await db.delete('favoritesLivres', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFavoritesLivre() async {
    final db = await database;
    return await db.query('favoritesLivres');
  }

  Future<bool> isFavoriteLivre(String id) async {
    final db = await database;
    final result = await db.query('favoritesLivres',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty;
  }

  /*********************************************************** */

  Future<void> addCycleMagazine({
    required String id,
    required String titre,
    required String periode,
    required String cover,
    required String type,
    required String subtitle,
    required int nbrPages,
    required String keyMagazine,
  }) async {
    final db = await database;

    if (id == null || id.isEmpty) {
      print("Erreur : id vide ou null");
      return;
    }

    await db.insert(
      'favoritesCyclesMagazines',
      {
        'id': id,
        'titre': titre,
        'periode': periode,
        'cover': cover,
        'type': type,
        'subtitle': subtitle,
        'nbrPages': nbrPages,
        'keyMagazine': keyMagazine,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeCycleMagazine(String id) async {
    final db = await database;
    await db
        .delete('favoritesCyclesMagazines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFavoritesCycleMagazines() async {
    final db = await database;

    return await db.query('favoritesCyclesMagazines');
  }

  Future<bool> isCycleMagazineFavorite(String id) async {
    final db = await database;
    final result = await db.query(
      'favoritesCyclesMagazines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /************************************************************* */
}
