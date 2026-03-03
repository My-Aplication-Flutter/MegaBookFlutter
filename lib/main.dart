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

class BookPage {
  final String id;
  final int numPage;

  BookPage({required this.id, required this.numPage});

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      id: json['_id'] ?? '',
      numPage: json['numPage'] ?? 0,
    );
  }
}

class Sommaire {
  final String titre;
  final int page;

  Sommaire({required this.titre, required this.page});

  factory Sommaire.fromJson(Map<String, dynamic> json) {
    return Sommaire(
      titre: json['titre'],
      page: json['page'],
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
  final ScrollController _miniSliderController = ScrollController();

  int currentIndex = 0;
  String bookTitle = "";
  List<Sommaire> listSommaires = [];

  List<int> bookmarks = [];
  Map<String, String> bookmarkNotes = {};
  bool showMiniSlider = true;

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

    final livreData = await rootBundle.loadString('assets/data-livre.json');
    final List<dynamic> livreJson = json.decode(livreData);
    final livre = livreJson.first;

    bookTitle = livre['titre'] ?? "";

    listSommaires = (livre['listSommaires'] as List)
        .map((e) => Sommaire.fromJson(e))
        .toList();

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
      builder: (_) => AlertDialog(
        title: Text("Note page ${pageIndex + 1}"),
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
      ),
    );
  }

  void goToPage(int index) {
    _pageController.animateToPage(
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

  void showGoToPageDialog(List<BookPage> pages) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Aller à une page"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "1 - ${pages.length}"),
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
        builder: (_) => ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final pageIndex = bookmarks[index];
                final note = bookmarkNotes[pageIndex.toString()] ?? "";

                return ListTile(
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
            ));
  }

  void showTableOfContents(List<BookPage> pages) {
    if (listSommaires.isEmpty) return;

    int activeIndex = 0;
    for (int i = 0; i < listSommaires.length; i++) {
      if (currentIndex + 1 >= listSommaires[i].page) {
        activeIndex = i;
      }
    }

    final ScrollController scrollController =
        ScrollController(initialScrollOffset: activeIndex * 70);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView.builder(
          controller: scrollController,
          itemCount: listSommaires.length,
          itemBuilder: (context, index) {
            final item = listSommaires[index];
            final bool isActive = index == activeIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5)
                    : null,
              ),
              child: ListTile(
                leading: Icon(
                  Icons.menu_book,
                  color:
                      isActive ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  item.titre,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: Text("Page ${item.page}"),
                onTap: () {
                  Navigator.pop(context);
                  if (item.page - 1 < pages.length) {
                    goToPage(item.page - 1);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildMiniSlider(List<BookPage> pages) {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Container(
        height: 95,
        color: Colors.black.withOpacity(0.4),
        child: ListView.builder(
          controller: _miniSliderController,
          scrollDirection: Axis.horizontal,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            final isCurrent = index == currentIndex;

            return GestureDetector(
              onTap: () => goToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                width: isCurrent ? 70 : 50,
                height: isCurrent ? 85 : 60,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isCurrent ? Colors.yellow : Colors.white,
                      width: 2),
                ),
                child: Transform.scale(
                  scale: isCurrent ? 1.2 : 1.0,
                  child: Opacity(
                    opacity: isCurrent ? 1.0 : 0.6,
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookPage>>(
      future: futurePages,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final pages = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(bookTitle),
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
                  icon: const Icon(Icons.menu_book),
                  onPressed: () => showTableOfContents(pages)),
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
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
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
