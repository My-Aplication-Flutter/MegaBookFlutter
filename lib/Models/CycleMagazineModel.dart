class CycleMagazine {
  final String id;
  final String titre;
  final String cover;
  final String type;
  final String keyMagazine;
  final String periode;
  final String subtitle;
  final int nbrPages;

  CycleMagazine({
    required this.id,
    required this.titre,
    required this.cover,
    required this.type,
    required this.keyMagazine,
    required this.periode,
    required this.subtitle,
    required this.nbrPages,
  });

  factory CycleMagazine.fromJson(Map<String, dynamic> json) {
    return CycleMagazine(
      id: json["_id"] ?? "",
      titre: json["titre"] ?? "",
      cover: json["cover"] ?? "",
      type: json["type"] ?? "",
      keyMagazine: json["keyMagazine"] ?? "",
      periode: json["periode"] ?? "",
      subtitle: json["subtitle"] ?? "",
      nbrPages: json["nbr_pages"] ?? 0,
    );
  }
}
