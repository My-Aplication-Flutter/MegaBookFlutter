
class FavoriteItem {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String type; // "book" | "magazine"
  final int pages;

  FavoriteItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.type,
    required this.pages,
  });
}