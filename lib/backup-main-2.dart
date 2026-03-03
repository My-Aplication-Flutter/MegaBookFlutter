
/*
✅ Nouveautés ajoutées :

Slider horizontal flottant avec miniatures interactives

Défilement horizontal pour visualiser rapidement toutes les pages

Bordure jaune sur la page courante

Bouton dans l’AppBar pour montrer / cacher le mini-slider
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
  final PageController _pageController = PageController();
  int currentIndex = 0;

  List<int> bookmarks = [];
  Map<String, String> bookmarkNotes = {};
  bool showMiniSlider = false;

  @override
  void initState() {
    super.initState();
    futurePages = loadBook();
  }

  Future<List<BookPage>> loadBook() async {
    final prefs = await SharedPreferences.getInstance();
    currentIndex = prefs.getInt("lastPage") ?? 0;

    final savedBookmarks = prefs.getStringList("bookmarks") ?? [];
    bookmarks = savedBookmarks.map((e) => int.parse(e)).toList();

    final savedNotes = prefs.getString("bookmarkNotes") ?? "{}";
    bookmarkNotes = Map<String, String>.from(json.decode(savedNotes));

    final response = await rootBundle.loadString('assets/book.json');
    final List<dynamic> data = json.decode(response);

    final pages = data.map((e) => BookPage.fromJson(e)).toList();
    pages.sort((a, b) => a.numPage.compareTo(b.numPage));

    return pages;
  }

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

  void editNoteDialog(int pageIndex) {
    final controller =
        TextEditingController(text: bookmarkNotes[pageIndex.toString()] ?? "");
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Note pour la page ${pageIndex + 1}"),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(hintText: "Écrire une note..."),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler")),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    bookmarkNotes[pageIndex.toString()] = controller.text;
                  });
                  saveBookmarks();
                  Navigator.pop(context);
                },
                child: const Text("Enregistrer"))
          ],
        );
      },
    );
  }

  void goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void showGoToPageDialog(List<BookPage> pages) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aller à une page"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              hintText: "Entrez un numéro (1 - ${pages.length})"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0 && value <= pages.length) {
                  Navigator.pop(context);
                  goToPage(value - 1);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Numéro de page invalide")),
                  );
                }
              },
              child: const Text("OK"))
        ],
      ),
    );
  }

  void showBookmarks(List<BookPage> pages) {
    if (bookmarks.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Aucun signet")));
      return;
    }

    showModalBottomSheet(
        context: context,
        builder: (_) {
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final pageIndex = bookmarks[index];
              final note = bookmarkNotes[pageIndex.toString()] ?? "";
              final pageId = pages[pageIndex].id;

              return ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 70,
                  child: Image.asset(
                    "assets/images/$pageId.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                title: Text("Page ${pageIndex + 1}"),
                subtitle: note.isNotEmpty ? Text(note) : null,
                trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => editNoteDialog(pageIndex)),
                onTap: () {
                  Navigator.pop(context);
                  goToPage(pageIndex);
                },
              );
            },
          );
        });
  }

  Widget buildSlider(List<BookPage> pages) {
    return Slider(
      min: 0,
      max: (pages.length - 1).toDouble(),
      value: currentIndex.toDouble(),
      onChanged: (value) {
        setState(() {
          currentIndex = value.toInt();
        });
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
        height: 80,
        color: Colors.black.withOpacity(0.3),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return GestureDetector(
              onTap: () => goToPage(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color:
                          index == currentIndex ? Colors.yellow : Colors.white,
                      width: 2),
                ),
                child: Image.asset(
                  "assets/images/${page.id}.jpg",
                  width: 60,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
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
        if (!snapshot.hasData) {
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
                  icon: const Icon(Icons.search),
                  onPressed: () => showGoToPageDialog(pages)),
              IconButton(
                  icon: Icon(bookmarks.contains(currentIndex)
                      ? Icons.bookmark
                      : Icons.bookmark_border),
                  onPressed: toggleBookmark),
              IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () => showBookmarks(pages)),
              IconButton(
                  icon: Icon(
                      showMiniSlider ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      showMiniSlider = !showMiniSlider;
                    });
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
                  const SizedBox(height: 10),
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
