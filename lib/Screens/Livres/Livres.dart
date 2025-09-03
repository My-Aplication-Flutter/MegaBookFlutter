import 'package:flutter/material.dart';
import 'CategoriesListLivres.dart';
import '../../menu.dart'; // Adapté à ton projet

class Livres extends StatelessWidget {
  const Livres({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thèmes',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const SideMenu(),
      body:
          const CategoriesListLivres(), // Widget qui gère la récupération de l’API
    );
  }
}
