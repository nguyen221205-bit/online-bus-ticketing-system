import 'package:flutter/material.dart';

enum ServiceType { bus, flight, train, carRental }

extension ServiceTypeExt on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.bus:
        return 'Xe khách';
      case ServiceType.flight:
        return 'Máy bay';
      case ServiceType.train:
        return 'Tàu hỏa';
      case ServiceType.carRental:
        return 'Thuê xe';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.bus:
        return Icons.directions_bus_rounded;
      case ServiceType.flight:
        return Icons.flight_rounded;
      case ServiceType.train:
        return Icons.train_rounded;
      case ServiceType.carRental:
        return Icons.directions_car_rounded;
    }
  }

  bool get isAvailable {
    switch (this) {
      case ServiceType.bus:
      case ServiceType.flight:
      case ServiceType.train:
        return true;
      case ServiceType.carRental:
        return false; // Coming soon
    }
  }
}
