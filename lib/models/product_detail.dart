class ProductDetail {
  final String code;
  final String name;
  final String category; // 'Ф', 'З', 'F'
  final double percentage;

  ProductDetail({
    required this.code,
    required this.name,
    required this.category,
    required this.percentage,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      code: json['code'],
      name: json['name'],
      category: json['category'],
      percentage: json['percentage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'category': category,
      'percentage': percentage,
    };
  }
}
