import 'package:equatable/equatable.dart';

enum FlightSeatClass {
  economy,
  premiumEconomy,
  business,
  firstClass,
}

extension FlightSeatClassExt on FlightSeatClass {
  String get label {
    switch (this) {
      case FlightSeatClass.economy:
        return 'Phổ thông';
      case FlightSeatClass.premiumEconomy:
        return 'Phổ thông đặc biệt';
      case FlightSeatClass.business:
        return 'Thương gia';
      case FlightSeatClass.firstClass:
        return 'Hạng nhất';
    }
  }

  String get code {
    switch (this) {
      case FlightSeatClass.economy:
        return 'ECO';
      case FlightSeatClass.premiumEconomy:
        return 'PRE';
      case FlightSeatClass.business:
        return 'BUS';
      case FlightSeatClass.firstClass:
        return 'FIR';
    }
  }
}

class AirportModel extends Equatable {
  final String id;
  final String name;
  final String fullName;
  final String city;
  final bool isPopular;

  const AirportModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.city,
    required this.isPopular,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, city];
}

class FlightPassengers extends Equatable {
  final int adults; // > 12 tuổi (Tối thiểu 1)
  final int children; // 2 - 12 tuổi
  final int infants; // 14 ngày - 2 tuổi

  const FlightPassengers({
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
  });

  int get totalPassengers => adults + children + infants;

  String get summaryText {
    final parts = <String>[];
    if (adults > 0) parts.add('$adults Người lớn');
    if (children > 0) parts.add('$children Trẻ em');
    if (infants > 0) parts.add('$infants Em bé');
    return parts.join(', ');
  }

  FlightPassengers copyWith({
    int? adults,
    int? children,
    int? infants,
  }) {
    return FlightPassengers(
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
    );
  }

  @override
  List<Object?> get props => [adults, children, infants];
}
