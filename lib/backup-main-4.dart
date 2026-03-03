/*
🎯 Résultat

Maintenant ton lecteur :

📖 Affiche automatiquement :
فقه السنة – سيد سابق - مجلد 1
✍️ سيد سابق

📂 Chargé depuis data-livre.json
💾 Continue à sauvegarder la dernière page
🎞 Garde le mini slider Kindle
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const BookReader(),
    );
  }
}

/* =======================
   MODEL PAGE
======================= */

class BookPage {
  final String id;
  final String title;
  final int numPage;

  BookPage({required this.id, required this.title, required this.numPage});

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      numPage: json['numPage'] ?? 0,
    );
  }
}

/* =======================
   MODEL LIVRE
======================= */

class BookInfo {
  final String titre;
  final String auteur;
  final int nbrPages;

  BookInfo({
    required this.titre,
    required this.auteur,
    required this.nbrPages,
  });

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    return BookInfo(
      titre: json['titre'] ?? '',
      auteur: json['auteur'] ?? '',
      nbrPages: json['nbr_pages'] ?? 0,
    );
  }
}

/* =======================
   BOOK READER
======================= */

class BookReader extends StatefulWidget {
  const BookReader({super.key});

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  late Future<List<BookPage>> futurePages;

  PageController? _pageController;
  final ScrollController _miniSliderController = ScrollController();

  int currentIndex = 0;
  bool showMiniSlider = true;

  String bookTitle = "";
  String bookAuthor = "";

  @override
  void initState() {
    super.initState();
    futurePages = loadBook();
  }

  /* =======================
     CHARGEMENT LIVRE + INFOS
  ======================= */

  Future<List<BookPage>> loadBook() async {
    final prefs = await SharedPreferences.getInstance();
    currentIndex = prefs.getInt("lastPage") ?? 0;

    // 🔥 Charger infos livre
    final bookInfoString =
        await rootBundle.loadString('assets/data-livre.json');
    final List<dynamic> bookData = json.decode(bookInfoString);

    if (bookData.isNotEmpty) {
      final info = BookInfo.fromJson(bookData.first);
      bookTitle = info.titre;
      bookAuthor = info.auteur;
    }

    // 🔥 Charger pages
    final response = await rootBundle.loadString('assets/book.json');
    final List<dynamic> data = json.decode(response);

    final pages = data.map((e) => BookPage.fromJson(e)).toList();
    pages.sort((a, b) => a.numPage.compareTo(b.numPage));

    _pageController = PageController(initialPage: currentIndex);

    return pages;
  }

  Future<void> saveLastPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastPage", index);
  }

  void goToPage(int index) {
    if (_pageController == null) return;

    _pageController!.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    _miniSliderController.animateTo(
      (index * 64.0) - (MediaQuery.of(context).size.width / 2) + 32,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /* =======================
     MINI SLIDER
  ======================= */

  Widget buildMiniSlider(List<BookPage> pages) {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Container(
        height: 95,
        color: Colors.black.withOpacity(0.35),
        child: ListView.builder(
          controller: _miniSliderController,
          scrollDirection: Axis.horizontal,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            final bool isCurrent = index == currentIndex;

            return GestureDetector(
              onTap: () => goToPage(index),
              child: AnimatedScale(
                scale: isCurrent ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: AnimatedOpacity(
                  opacity: isCurrent ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    width: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: isCurrent ? Colors.amber : Colors.transparent,
                          width: 2),
                    ),
                    child: Image.asset(
                      "assets/images/${page.id}.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /* =======================
     UI
  ======================= */

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookPage>>(
      future: futurePages,
      builder: (context, snapshot) {
        if (!snapshot.hasData || _pageController == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  bookTitle.isNotEmpty ? bookTitle : "Chargement...",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (bookAuthor.isNotEmpty)
                  Text(
                    bookAuthor,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / pages.length,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => currentIndex = index);
                        saveLastPage(index);
                      },
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.asset(
                            "assets/images/${page.id}.jpg",
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Page ${currentIndex + 1} / ${pages.length}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              if (showMiniSlider) buildMiniSlider(pages),
            ],
          ),
        );
      },
    );
  }
}
