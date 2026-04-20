import 'dart:io';
import 'package:flutter/material.dart';
import '../../Services/cache_service.dart';

class OfflineCycleMagazinePage extends StatefulWidget {
  final String cycleMagazineId;
  final String titreCycleMagazine;

  const OfflineCycleMagazinePage({
    super.key,
    required this.cycleMagazineId,
    required this.titreCycleMagazine,
  });

  @override
  State<OfflineCycleMagazinePage> createState() =>
      _OfflineCycleMagazinePageState();
}

class _OfflineCycleMagazinePageState extends State<OfflineCycleMagazinePage> {
  final MagazineCacheService _cacheService = MagazineCacheService();

  List<dynamic> pages = [];
  bool isLoading = true;

  PageController _pageController = PageController();
  int currentPage = 0;

  ////////////////////////////////////////////////////////////
  /// 📥 LOAD OFFLINE PAGES
  ////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    _loadOfflinePages();
  }

  Future<void> _loadOfflinePages() async {
    final data = await _cacheService.getPages(widget.cycleMagazineId);

    if (data == null || data.isEmpty) {
      setState(() {
        isLoading = false;
      });

      return;
    }

    setState(() {
      pages = data;
      isLoading = false;
    });
  }

  ////////////////////////////////////////////////////////////
  /// 🖼 BUILD IMAGE OFFLINE
  ////////////////////////////////////////////////////////////
  Widget _buildPageImage(dynamic page) {
    final localPath = page["image_local"];

    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.contain,
      );
    }

    return const Center(
      child: Icon(Icons.broken_image, size: 50),
    );
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titreCycleMagazine),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "${currentPage + 1}/${pages.length}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages.isEmpty
              ? const Center(
                  child: Text("❌ Aucun contenu offline disponible"),
                )
              : Column(
                  children: [
                    ////////////////////////////////////////////////////////////
                    /// 📖 VIEWER
                    ////////////////////////////////////////////////////////////
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pages.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final page = pages[index];

                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: _buildPageImage(page),
                            ),
                          );
                        },
                      ),
                    ),

                    ////////////////////////////////////////////////////////////
                    /// 🎮 CONTROLS
                    ////////////////////////////////////////////////////////////
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: currentPage > 0
                                ? () {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                          Text(
                            "Page ${currentPage + 1}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            onPressed: currentPage < pages.length - 1
                                ? () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
