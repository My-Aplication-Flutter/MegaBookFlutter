import 'package:flutter/material.dart';
import 'Models/BookCategory.dart';
import 'listLivres.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CategoryList extends StatelessWidget {
  final List<BookCategory> categories;
  const CategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(
              category.valueTheme,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Section: ${category.keySection}'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sélectionné : ${category.valueTheme}'),
                ),
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BooksByThemePage(theme: category.valueTheme),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class CategoriesListLivres extends StatefulWidget {
  const CategoriesListLivres({super.key});

  @override
  State<CategoriesListLivres> createState() => _CategoriesListLivresState();
}

class _CategoriesListLivresState extends State<CategoriesListLivres> {
  late Future<List<BookCategory>> futureCategories;

  @override
  void initState() {
    super.initState();
    futureCategories = fetchCategories();
  }

  // 🔥 VERSION OFFLINE
  Future<List<BookCategory>> fetchCategories() async {
    try {
      // Charger le fichier JSON local
      final String response =
          await rootBundle.loadString('assets/data/items_sections_livres.json');

      final decoded = json.decode(response);

      final List<dynamic> data = decoded['data'] ?? [];

      // Cherche la section "livres"
      final livresSection = data.firstWhere(
        (section) => section['keySection'] == 'livres',
        orElse: () => null,
      );

      if (livresSection != null && livresSection['listThemes'] != null) {
        final List<dynamic> themes = livresSection['listThemes'];

        return themes.map((json) => BookCategory.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("Erreur chargement JSON local: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookCategory>>(
      future: futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune catégorie trouvée'));
        }

        return CategoryList(categories: snapshot.data!);
      },
    );
  }
}
