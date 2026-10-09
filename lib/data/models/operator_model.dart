import 'package:equatable/equatable.dart';

class OperatorModel extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String hotline;
  final double rating;
  final int reviewCount;
  final String logoUrl;
  final String policy;

  const OperatorModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.hotline,
    required this.rating,
    required this.reviewCount,
    required this.logoUrl,
    required this.policy,
  });

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    final id = json['busCompanyId']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? json['tenNhaXe'] as String? ?? '';
    final shortName = json['shortName'] as String? ?? json['code'] as String? ?? name;
    final hotline = json['hotline'] as String? ??
        json['contactInfo'] as String? ??
        json['thongTinLienHe'] as String? ??
        '1900 6067';
    final rating = (json['rating'] as num?)?.toDouble() ?? 4.8;
    final reviewCount = json['reviewCount'] as int? ?? 1250;
    final logoUrl = json['logoUrl'] as String? ??
        'https://cdn.vexere.com/v3/2022/07/logo-futa.png';
    final policy = json['policy'] as String? ??
        'Chính sách hủy vé linh hoạt theo quy định của nhà xe.';

    return OperatorModel(
      id: id,
      name: name,
      shortName: shortName,
      hotline: hotline,
      rating: rating,
      reviewCount: reviewCount,
      logoUrl: logoUrl,
      policy: policy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'hotline': hotline,
    'rating': rating,
    'reviewCount': reviewCount,
    'logoUrl': logoUrl,
    'policy': policy,
  };

  @override
  List<Object?> get props => [id, name, rating];
}
