import 'package:equatable/equatable.dart';

class TrainStationModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final bool isPopular;

  const TrainStationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.isPopular,
  });

  factory TrainStationModel.fromJson(Map<String, dynamic> json) {
    return TrainStationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, city];
}

class TrainPassengers extends Equatable {
  final int adults; // Người lớn
  final int children; // Trẻ em (6 - 10 tuổi)
  final int seniors; // Người cao tuổi (>= 60 tuổi)
  final int students; // Sinh viên
  final int unionMembers; // Đoàn viên công đoàn

  const TrainPassengers({
    this.adults = 1,
    this.children = 0,
    this.seniors = 0,
    this.students = 0,
    this.unionMembers = 0,
  });

  int get totalPassengers => adults + children + seniors + students + unionMembers;

  String get summaryText {
    final parts = <String>[];
    if (adults > 0) parts.add('$adults Người lớn');
    if (children > 0) parts.add('$children Trẻ em');
    if (seniors > 0) parts.add('$seniors Cao tuổi');
    if (students > 0) parts.add('$students Sinh viên');
    if (unionMembers > 0) parts.add('$unionMembers Công đoàn');
    return parts.isEmpty ? '1 Người lớn' : parts.join(', ');
  }

  TrainPassengers copyWith({
    int? adults,
    int? children,
    int? seniors,
    int? students,
    int? unionMembers,
  }) {
    return TrainPassengers(
      adults: adults ?? this.adults,
      children: children ?? this.children,
      seniors: seniors ?? this.seniors,
      students: students ?? this.students,
      unionMembers: unionMembers ?? this.unionMembers,
    );
  }

  @override
  List<Object?> get props => [adults, children, seniors, students, unionMembers];
}
