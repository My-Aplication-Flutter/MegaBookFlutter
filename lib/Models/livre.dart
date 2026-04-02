class Sommaire {
  final String titre;
  final int page;

  Sommaire({
    required this.titre,
    required this.page,
  });

  factory Sommaire.fromJson(Map<String, dynamic> json) {
    return Sommaire(
      titre: json["titre"] ?? "",
      page: json["page"] ?? 0,
    );
  }
}

class Book {
  final String id;
  final String titre;
  final String cover;
  final String auteur;
  final String year;
  final String subtitle;
  final String keyTheme;
  final String langue;
  final int nbrPages;
  // 🔥 NOUVEAU
  final List<Sommaire> listSommaires;

  Book({
    required this.id,
    required this.titre,
    required this.cover,
    required this.auteur,
    required this.year,
    required this.subtitle,
    required this.keyTheme,
    required this.langue,
    required this.nbrPages,
    required this.listSommaires,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json["_id"] ?? "",
      titre: json["titre"] ?? "",
      cover: json["cover"] ?? "",
      auteur: json["auteur"] ?? "",
      year: json["year"] ?? "",
      subtitle: json["subtitle"] ?? "",
      keyTheme: json["keyTheme"] ?? "",
      langue: json["langue"] ?? "",
      nbrPages: json["nbr_pages"] ?? 0,
      // 🔥 PARSING LISTE SOMMAIRES
      listSommaires: (json["listSommaires"] as List<dynamic>?)
              ?.map((e) => Sommaire.fromJson(e))
              .toList() ??
          [],
    );
  }
}
