import 'package:flutter/material.dart';
import 'Models/BookCategory.dart';
import 'listLivres.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryList extends StatelessWidget {
  final List<BookCategory> categories;
  const CategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: const Icon(Icons.book),
          title: Text(category.valueTheme),
          subtitle: Text('Section: ${category.keySection}'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sélectionné : ${category.valueTheme}')),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BooksByThemePage(theme: category.valueTheme),
              ),
            );
          },
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

  Future<List<BookCategory>> fetchCategories() async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/getListeItemsBySectionMenuApp'),
      headers: {
        'Content-Type': 'application/json',
        // ... autres headers si besoin
      },
      // Ajoute le body si nécessaire pour filtrer sur "livres", sinon laisse vide
      body: json.encode(
          {}), // body: json.encode({'section': 'livres'}), // Ex du body envoyé
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // On attend un objet {"reponse": true, "data": [...]}
      final List<dynamic> data = decoded['data'] ?? [];

      // Cherche l'élément dont keySection == "livres"
      final livresSection = data.firstWhere(
        (section) => section['keySection'] == 'livres',
        orElse: () => null,
      );

      if (livresSection != null && livresSection['listThemes'] != null) {
        // Liste de thèmes à extraire
        final List<dynamic> themes = livresSection['listThemes'];
        print('themes : $themes');
        for (var themeItem in themes) {
          print('theme item: $themeItem');
        }
        return themes.map((json) => BookCategory.fromJson(json)).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Erreur serveur');
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
