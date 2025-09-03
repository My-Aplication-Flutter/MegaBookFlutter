import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../menu.dart'; // Adapté à ton projet
import './Livres/pageLivre.dart';
import './Magazines/CycleMagazinePage.dart';

class Livre {
  final String id, titre, cover, auteur, year, subtitle, keyTheme, date;
  final int nbrPages;

  Livre({
    required this.id,
    required this.titre,
    required this.cover,
    required this.auteur,
    required this.year,
    required this.subtitle,
    required this.keyTheme,
    required this.nbrPages,
    required this.date,
  });

  factory Livre.fromJson(Map<String, dynamic> json) {
    return Livre(
      id: json['_id'],
      titre: json['titre'],
      cover: json['cover'],
      auteur: json['auteur'],
      year: json['year'],
      subtitle: json['subtitle'],
      keyTheme: json['keyTheme'],
      nbrPages: json['nbr_pages'],
      date: json['date'],
    );
  }
}

// CycleMagazine modèle
class CycleMagazineModel {
  final String id, titre, cover, periode, type, keyMagazine, date;
  final int nbrPages;
  CycleMagazineModel({
    required this.id,
    required this.titre,
    required this.cover,
    required this.periode,
    required this.type,
    required this.keyMagazine,
    required this.nbrPages,
    required this.date,
  });
  factory CycleMagazineModel.fromJson(Map<String, dynamic> json) {
    return CycleMagazineModel(
      id: json['_id'],
      titre: json['titre'],
      cover: json['cover'],
      periode: json['periode'],
      type: json['type'],
      keyMagazine: json['keyMagazine'],
      nbrPages: json['nbr_pages'],
      date: json['date'],
    );
  }
}

// -------- Widget --------

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Livre>> futureBooks;
  late Future<List<CycleMagazineModel>> futureCyclesFinance;
  late Future<List<CycleMagazineModel>> futureCyclesInformatique;
  late Future<List<CycleMagazineModel>> futureCyclesBusiness;
  late Future<List<CycleMagazineModel>> futureCyclesPsychologie;
  // late Future<List<CycleMagazineModel>> futureCyclesActualite;
  late Future<List<CycleMagazineModel>> futureCyclesScience;
  late Future<List<CycleMagazineModel>> futureCyclesSante;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchLastBooks();
    futureCyclesFinance = fetchLastCyclesMagazines("Finance");
    futureCyclesInformatique = fetchLastCyclesMagazines("Informatique");
    futureCyclesBusiness =
        fetchLastCyclesMagazines("Business"); // ajout Business
    futureCyclesPsychologie =
        fetchLastCyclesMagazines("Psychologie"); // ajout Psychologie
    // futureCyclesPsychologie =    fetchLastCyclesMagazines("Actualite"); // ajout Actualite
    futureCyclesScience =
        fetchLastCyclesMagazines("Science"); // ajout Actualite
    futureCyclesSante = fetchLastCyclesMagazines("Sante"); // ajout Sante
  }

  Future<List<Livre>> fetchLastBooks() async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/getLastLivres'), // Remplace par ton URL
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['lastLivres'];
      return list.map((e) => Livre.fromJson(e)).toList();
    } else {
      throw Exception('Erreur de chargement');
    }
  }

  Future<List<CycleMagazineModel>> fetchLastCyclesMagazines(
      String theme) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/getLastCyclesMagazines'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"keyTheme": theme}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['lastCyclesMagazines'];
      return list.map((e) => CycleMagazineModel.fromJson(e)).toList();
    } else {
      throw Exception('Erreur de chargement des cycles magazines');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: const SideMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Slider Livres
            sectionSlider(
              'Derniers livres ajoutés',
              FutureBuilder<List<Livre>>(
                future: futureBooks,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (book) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookImagesPage(
                            livreId: book.id,
                            titreLivre: book.titre,
                          ),
                        ),
                      );
                    },
                    child: cardLivre(book),
                  ),
                ),
              ),
            ),
            // Slider Magazines Finance
            sectionSlider(
              'Derniers magazines Finance',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesFinance,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ),
            // Slider Magazines Informatique
            sectionSlider(
              'Derniers magazines Informatique',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesInformatique,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ),
            // Slider Magazines Business
            sectionSlider(
              'Derniers magazines Business',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesBusiness,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ),
            // Slider Magazines Psychologie
            sectionSlider(
              'Derniers magazines Psychologie',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesPsychologie,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ),
            // Slider Magazines Actualite
            /*  sectionSlider(
              'Derniers magazines Actualité',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesActualite,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ), */
            // Slider Magazines Science
            sectionSlider(
              'Derniers magazines Science',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesScience,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ),
            // Slider Magazines Sante
            sectionSlider(
              'Derniers magazines Santé',
              FutureBuilder<List<CycleMagazineModel>>(
                future: futureCyclesSante,
                builder: (context, snapshot) => sliderBuilder(
                  snapshot: snapshot,
                  builderWidget: (cycle) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleMagazineImagesPage(
                            cycleMagazineId: cycle.id,
                            titreCycleMagazine: cycle.titre,
                          ),
                        ),
                      );
                    },
                    child: cardCycleMagazine(cycle),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  } //

  // widgets utilitaires
  Widget sectionSlider(String title, Widget slider) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[700])),
          const SizedBox(height: 8),
          slider,
        ],
      );

  Widget sliderBuilder<T>({
    required AsyncSnapshot<List<T>> snapshot,
    required Widget Function(T item) builderWidget,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Erreur : ${snapshot.error}'));
    }
    final items = snapshot.data ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('Aucun résultat disponible.'));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      child: cs.CarouselSlider(
        options: cs.CarouselOptions(
          height: 350,
          enlargeCenterPage: true,
          autoPlay: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.55,
        ),
        items: items.map(builderWidget).toList(),
      ),
    );
  }

  // widgets cards
  Widget cardLivre(Livre book) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Image.network(book.cover,
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(book.auteur,
                      style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${book.year} • ${book.nbrPages} pages',
                      style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(book.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(9)),
                    child: Text(book.keyTheme,
                        style: const TextStyle(
                            color: Colors.deepPurple, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget cardCycleMagazine(CycleMagazineModel cycle) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Image.network(cycle.cover,
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cycle.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(cycle.periode,
                      style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${cycle.type} • ${cycle.nbrPages} pages',
                      style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(cycle.date.substring(0, 10),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}
