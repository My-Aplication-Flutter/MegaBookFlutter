class Magazine {
  final String id;
  final String titre;
  final String cover;
  final String keyTheme;

  Magazine(
      {required this.id,
      required this.titre,
      required this.cover,
      required this.keyTheme});

  factory Magazine.fromJson(Map<String, dynamic> json) {
    return Magazine(
        id: json["_id"] ?? "",
        titre: json["titre"] ?? "",
        cover: json["cover"] ?? "",
        keyTheme: json["keyTheme"] ?? "");
  }
}
