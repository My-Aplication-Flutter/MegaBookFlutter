// Modèle de données pour une catégorie de livre
class BookCategory {
  final String keyTheme;
  final String valueTheme;
  final String keySection;

  BookCategory({
    required this.keyTheme,
    required this.valueTheme,
    required this.keySection,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      keyTheme: json['keyTheme'] ?? '',
      valueTheme: json['valueTheme'] ?? '',
      keySection: json['keySection'] ?? '',
    );
  }
}
