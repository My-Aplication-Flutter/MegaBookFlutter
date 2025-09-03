import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Models/MagazineModel.dart';
import 'ListCyclesMagazine.dart'; // Assure-toi que ce fichier existe et est importé

class MagazinesByThemePage extends StatefulWidget {
  final String theme;

  const MagazinesByThemePage({super.key, required this.theme});

  @override
  State<MagazinesByThemePage> createState() => _MagazinesByThemePageState();
}

class _MagazinesByThemePageState extends State<MagazinesByThemePage> {
  late Future<List<Magazine>> futureMagazines;

  @override
  void initState() {
    super.initState();
    futureMagazines = fetchMagazines(widget.theme);
  }

  Future<List<Magazine>> fetchMagazines(String theme) async {
    final response = await http.post(
      Uri.parse(
          'https://backend-mega-book-theta.vercel.app/api/listMagazinesBytheme'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"keyTheme": theme}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = decoded["listMagazines"] as List<dynamic>;
      return list.map((e) => Magazine.fromJson(e)).toList();
    } else {
      throw Exception('Erreur de récupération des magazines');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.theme,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Magazine>>(
        future: futureMagazines,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aucun magazine trouvé pour ce thème.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final magazines = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: magazines.length,
            itemBuilder: (context, index) {
              final magazine = magazines[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CyclesByMagazinePage(
                        magazineId: magazine.id,
                        titreMagazine: magazine.titre,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Image du magazine avec Hero
                      Hero(
                        tag: 'magazine_${magazine.id}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Image.network(
                            magazine.cover,
                            height: 160, // 🔥 plus grand qu’avant
                            width: 160, // 🔥 élargi aussi
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Texte
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                magazine.titre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "📖 Appuyez pour découvrir",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
