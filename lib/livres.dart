import 'package:flutter/material.dart';
import 'CategoriesListLivres.dart';

class Livres extends StatelessWidget {
  const Livres({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories des livres')),
      body:
          const CategoriesListLivres(), // Widget qui gère la récupération de l’API
    );
  }
}
