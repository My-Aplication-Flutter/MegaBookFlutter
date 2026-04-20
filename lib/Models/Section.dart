class Section {
  final String key;
  final String value;
  final String activation;

  Section({
    required this.key,
    required this.value,
    required this.activation,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      key: json['key'],
      value: json['value'],
      activation: json['activation'],
    );
  }
}
