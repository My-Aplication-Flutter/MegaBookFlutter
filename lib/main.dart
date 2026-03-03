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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BookReader(),
    );
  }
}

/* =======================
   MODELS
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

class SommaireItem {
  final String titre;
  final int page;

  SommaireItem({required this.titre, required this.page});

  factory SommaireItem.fromJson(Map<String, dynamic> json) {
    return SommaireItem(
      titre: json['titre'] ?? '',
      page: json['page'] ?? 0,
    );
  }
}

class BookInfo {
  final String titre;
  final String auteur;
  final List<SommaireItem> sommaire;

  BookInfo({
    required this.titre,
    required this.auteur,
    required this.sommaire,
  });

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    final list = json['listSommaires'] as List<dynamic>? ?? [];

    return BookInfo(
      titre: json['titre'] ?? '',
      auteur: json['auteur'] ?? '',
      sommaire: list.map((e) => SommaireItem.fromJson(e)).toList(),
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
  List<SommaireItem> sommaire = [];

  @override
  void initState() {
    super.initState();
    futurePages = loadBook();
  }

  /* =======================
     LOAD BOOK + SOMMAIRE
  ======================= */

  Future<List<BookPage>> loadBook() async {
    final prefs = await SharedPreferences.getInstance();
    currentIndex = prefs.getInt("lastPage") ?? 0;

    // Charger data-livre.json
    final infoString = await rootBundle.loadString('assets/data-livre.json');
    final List<dynamic> dataLivre = json.decode(infoString);

    if (dataLivre.isNotEmpty) {
      final info = BookInfo.fromJson(dataLivre.first);
      bookTitle = info.titre;
      bookAuthor = info.auteur;
      sommaire = info.sommaire;
    }

    // Charger pages
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
     MENU SOMMAIRE
  ======================= */

  void showSommaireMenu(List<BookPage> pages) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListView.builder(
            itemCount: sommaire.length,
            itemBuilder: (context, index) {
              final item = sommaire[index];

              return ListTile(
                title: Text(item.titre),
                trailing: Text("صفحة ${item.page}"),
                onTap: () {
                  Navigator.pop(context);

                  final targetIndex =
                      pages.indexWhere((p) => p.numPage == item.page);

                  if (targetIndex != -1) {
                    goToPage(targetIndex);
                  }
                },
              );
            },
          ),
        );
      },
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
                  bookTitle,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                Text(
                  bookAuthor,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book),
                onPressed: () => showSommaireMenu(pages),
              ),
            ],
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
