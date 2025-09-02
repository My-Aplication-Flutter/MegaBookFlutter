// Modèle de données pour une catégorie de livre
class MagazineCategory {
  final String keyTheme;
  final String valueTheme;
  final String keySection;

  MagazineCategory({
    required this.keyTheme,
    required this.valueTheme,
    required this.keySection,
  });

  factory MagazineCategory.fromJson(Map<String, dynamic> json) {
    return MagazineCategory(
      keyTheme: json['keyTheme'] ?? '',
      valueTheme: json['valueTheme'] ?? '',
      keySection: json['keySection'] ?? '',
    );
  }
}
