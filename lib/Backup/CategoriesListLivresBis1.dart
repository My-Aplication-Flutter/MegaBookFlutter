import 'package:flutter/material.dart';
import '../Models/BookCategory.dart';

// Liste des catégories définie ici en variable constante
final List<BookCategory> categories = [
  BookCategory(
      keyTheme: "Informatique",
      valueTheme: "Informatique",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Science", valueTheme: "Science", keySection: "livres"),
  BookCategory(
      keyTheme: "Crypto-monnaie/Blockchain",
      valueTheme: "Crypto-monnaie/Blockchain",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Societe", valueTheme: "Societe", keySection: "livres"),
  BookCategory(
      keyTheme: "Affaires et économie",
      valueTheme: "Affaires et économie",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Finances personnelles",
      valueTheme: "Finances personnelles",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Études et enseignement en éducation",
      valueTheme: "Études et enseignement en éducation",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Biographie et autobiographie - Affaires et finances",
      valueTheme: "Biographie et autobiographie - Affaires et finances",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Jeux et Loisirs",
      valueTheme: "Jeux et Loisirs",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Citations et Pensées",
      valueTheme: "Citations et Pensées",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Développement personnel",
      valueTheme: "Développement personnel",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Mathématiques - Puzzle",
      valueTheme: "Mathématiques - Puzzle",
      keySection: "livres"),
  BookCategory(
      keyTheme: "Bourse - Trading",
      valueTheme: "Bourse - Trading",
      keySection: "livres"),
];

// Widget pour afficher la liste des catégories
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
          },
        );
      },
    );
  }
}
