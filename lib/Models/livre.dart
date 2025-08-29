class Book {
  final String id;
  final String titre;
  final String cover;
  final String auteur;
  final String year;
  final String subtitle;
  final String keyTheme;
  final int nbrPages;

  Book({
    required this.id,
    required this.titre,
    required this.cover,
    required this.auteur,
    required this.year,
    required this.subtitle,
    required this.keyTheme,
    required this.nbrPages,
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
      nbrPages: json["nbr_pages"] ?? 0,
    );
  }
}
