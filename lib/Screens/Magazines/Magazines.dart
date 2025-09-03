import 'package:flutter/material.dart';
import 'CategoriesListMagazines.dart';
import '../../menu.dart'; // Adapté à ton projet

class Magazines extends StatelessWidget {
  const Magazines({super.key});

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
          const CategoriesListMagazines(), // Widget qui gère la récupération de l’API
    );
  }
}
