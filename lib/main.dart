import 'package:flutter/material.dart';
import 'Screens/MyHomePage.dart';
import 'Screens/Livres.dart';
import 'Screens/Magazines.dart';
import 'Screens/FavoritesLivres.dart'; // importe ta page favoris
import 'Screens/FavoritesMagazines.dart'; // importe ta page favoris

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MegaBook',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // La propriété initialRoute est inutile ici car home est défini.
      // Il vaut mieux choisir soit home, soit initialRoute + routes.
      // Voici un exemple correct avec initialRoute et routes :
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'Accueil'),
        // Si tu ajoutes ProfilePage et SettingsPage, décommente et crée-les.
        '/Livres': (context) => const Livres(),
        '/Magazines': (context) => const Magazines(),
        '/FavorisLivres': (context) => const FavoritesLivresPage(),
        '/FavorisMagazines': (context) => const FavoritesMagazinesPage(),
        // '/settings': (context) => const SettingsPage(),
      },
      // Si tu utilises 'home', inutile de mettre initialRoute et routes,
      // mais ici on garde seulement routes + initialRoute pour l'exemple.
      // home: MyHomePage(title: 'Flutter Demo Home Page'), // Retiré
    );
  }
}
