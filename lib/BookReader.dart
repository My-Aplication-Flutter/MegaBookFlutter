import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Book.dart';

class BookReader extends StatefulWidget {
  final Book book;

  const BookReader({super.key, required this.book});

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  late Future<List<dynamic>> futurePages;
  final PageController _pageController = PageController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    futurePages = loadBook();
  }

  Future<List<dynamic>> loadBook() async {
    final prefs = await SharedPreferences.getInstance();
    currentIndex = prefs.getInt("lastPage_${widget.book.token}") ?? 0;

    final response =
        await rootBundle.loadString('assets/books/${widget.book.token}.json');
    return json.decode(response);
  }

  Future<void> saveLastPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastPage_${widget.book.token}", index);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: futurePages,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final pages = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.book.titre),
          ),
          body: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              currentIndex = index;
              saveLastPage(index);
            },
            itemBuilder: (context, index) {
              final page = pages[index];
              return Image.asset(
                "assets/images/${page['_id']}.jpg",
                fit: BoxFit.contain,
              );
            },
          ),
        );
      },
    );
  }
}
