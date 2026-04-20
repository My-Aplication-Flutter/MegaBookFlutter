class CycleMagazinePageImage {
  final String id;
  final String titre;
  final String urlImage;
  final int numPage;

  CycleMagazinePageImage({
    required this.id,
    required this.titre,
    required this.urlImage,
    required this.numPage,
  });

  factory CycleMagazinePageImage.fromJson(Map<String, dynamic> json) {
    return CycleMagazinePageImage(
      id: json["_id"] ?? "",
      titre: json["title"] ?? "",
      urlImage: json["url"] ?? "",
      numPage: json["numPage"] ?? 0,
    );
  }

  /// ✅ AJOUT ICI
  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "title": titre,
      "url": urlImage,
      "numPage": numPage,
    };
  }
}
