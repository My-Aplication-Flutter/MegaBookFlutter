class BookPageImage {
  final String id;
  final String titre;
  final String urlImage;
  final int numPage;

  BookPageImage({
    required this.id,
    required this.titre,
    required this.urlImage,
    required this.numPage,
  });

  factory BookPageImage.fromJson(Map<String, dynamic> json) {
    return BookPageImage(
      id: json["_id"] ?? "",
      titre: json["title"] ?? "",
      urlImage: json["url"] ?? "",
      numPage: json["numPage"] ?? 0,
    );
  }
}
