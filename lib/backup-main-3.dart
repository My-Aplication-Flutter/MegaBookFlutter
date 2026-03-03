/*
Résultat final

À présent ton lecteur :

📖 Rouvre automatiquement à la dernière page

💾 Sauvegarde instantanément à chaque changement

🔎 Garde le slider interactif avec effet zoom

🔖 Conserve les signets et notes

⚡ Fluide comme un Kindle
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

  List<int> bookmarks = [];
  Map<String, String> bookmarkNotes = {};

  @override
  void initState() {
    super.initState();
    futurePages = loadBook();
  }

  Future<List<BookPage>> loadBook() async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 Charger dernière page sauvegardée
    currentIndex = prefs.getInt("lastPage") ?? 0;

    final savedBookmarks = prefs.getStringList("bookmarks") ?? [];
    bookmarks = savedBookmarks.map((e) => int.parse(e)).toList();

    final savedNotes = prefs.getString("bookmarkNotes") ?? "{}";
    bookmarkNotes = Map<String, String>.from(json.decode(savedNotes));

    final response = await rootBundle.loadString('assets/book.json');
    final List<dynamic> data = json.decode(response);

    final pages = data.map((e) => BookPage.fromJson(e)).toList();
    pages.sort((a, b) => a.numPage.compareTo(b.numPage));

    // 🔥 Initialiser PageController avec dernière page
    _pageController = PageController(initialPage: currentIndex);

    return pages;
  }

  // 🔥 Sauvegarde automatique de la dernière page
  Future<void> saveLastPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastPage", index);
  }

  Future<void> saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        "bookmarks", bookmarks.map((e) => e.toString()).toList());
    await prefs.setString("bookmarkNotes", json.encode(bookmarkNotes));
  }

  void toggleBookmark() {
    setState(() {
      if (bookmarks.contains(currentIndex)) {
        bookmarks.remove(currentIndex);
        bookmarkNotes.remove(currentIndex.toString());
      } else {
        bookmarks.add(currentIndex);
        bookmarks.sort();
        bookmarkNotes[currentIndex.toString()] = "";
      }
    });
    saveBookmarks();
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

  Widget buildSlider(List<BookPage> pages) {
    return Slider(
      min: 0,
      max: (pages.length - 1).toDouble(),
      value: currentIndex.toDouble(),
      onChanged: (value) {
        setState(() => currentIndex = value.toInt());
      },
      onChangeEnd: (value) => goToPage(value.toInt()),
    );
  }

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

            final double scale = isCurrent ? 1.3 : 1.0;
            final double opacity = isCurrent ? 1.0 : 0.6;

            return GestureDetector(
              onTap: () => goToPage(index),
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 250),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: opacity,
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
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
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

        if (currentIndex >= pages.length) currentIndex = 0;

        return Scaffold(
          appBar: AppBar(
            title: Text("Page ${currentIndex + 1}"),
            centerTitle: true,
            actions: [
              IconButton(
                  icon: Icon(bookmarks.contains(currentIndex)
                      ? Icons.bookmark
                      : Icons.bookmark_border),
                  onPressed: toggleBookmark),
              IconButton(
                  icon: Icon(
                      showMiniSlider ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() => showMiniSlider = !showMiniSlider);
                  }),
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

                        // 🔥 Sauvegarde automatique ici
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
                            cacheWidth: 1200,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Text("Image introuvable")),
                          ),
                        );
                      },
                    ),
                  ),
                  buildSlider(pages),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Page ${currentIndex + 1} / ${pages.length}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 15),
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
