import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Models/MagazineModel.dart';
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
        title: Text(widget.theme,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
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
                child: Text('Aucun magazine trouvé pour ce thème.'));
          }
          final magazines = snapshot.data!;
          return ListView.builder(
            itemCount: magazines.length,
            itemBuilder: (context, index) {
              final magazine = magazines[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(magazine.cover),
                    radius: 25,
                  ),
                  title: Text(magazine.titre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
