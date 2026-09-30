import 'package:equatable/equatable.dart';

/// Model representing a temporary seat reservation per rule-api.md and endpoint-api.md
class SeatHoldModel extends Equatable {
  final String holdToken;
  final int tripId;
  final List<int> seatIds;
  final List<String> seatCodes;
  final DateTime expiresAt;
  final DateTime? createdAt;

  const SeatHoldModel({
    required this.holdToken,
    required this.tripId,
    required this.seatIds,
    this.seatCodes = const [],
    required this.expiresAt,
    this.createdAt,
  });

  SeatHoldModel copyWith({
    String? holdToken,
    int? tripId,
    List<int>? seatIds,
    List<String>? seatCodes,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return SeatHoldModel(
      holdToken: holdToken ?? this.holdToken,
      tripId: tripId ?? this.tripId,
      seatIds: seatIds ?? this.seatIds,
      seatCodes: seatCodes ?? this.seatCodes,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SeatHoldModel.fromJson(Map<String, dynamic> json) {
    // Parse seatIds
    List<int> parsedSeatIds = [];
    if (json['seatIds'] is List) {
      parsedSeatIds = (json['seatIds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

    // Parse seatCodes if provided
    List<String> parsedSeatCodes = [];
    if (json['seatCodes'] is List) {
      parsedSeatCodes = (json['seatCodes'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['seats'] is List) {
      parsedSeatCodes = (json['seats'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Parse dates
    DateTime parsedExpiresAt;
    if (json['expiresAt'] is String) {
      parsedExpiresAt =
          DateTime.tryParse(json['expiresAt'] as String) ??
          DateTime.now().add(const Duration(minutes: 10));
    } else {
      parsedExpiresAt = DateTime.now().add(const Duration(minutes: 10));
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String);
    }

    return SeatHoldModel(
      holdToken: json['holdToken'] as String? ?? '',
      tripId: (json['tripId'] as num?)?.toInt() ?? 0,
      seatIds: parsedSeatIds,
      seatCodes: parsedSeatCodes,
      expiresAt: parsedExpiresAt,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'holdToken': holdToken,
    'tripId': tripId,
    'seatIds': seatIds,
    if (seatCodes.isNotEmpty) 'seatCodes': seatCodes,
    'expiresAt': expiresAt.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  /// Countdown helpers
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remainingTime => expiresAt.difference(DateTime.now());
  int get remainingSeconds =>
      remainingTime.isNegative ? 0 : remainingTime.inSeconds;

  /// Returns remaining time formatted as mm:ss
  String get formattedRemainingTime {
    final secs = remainingSeconds;
    final minutes = secs ~/ 60;
    final remainingSecs = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [holdToken, tripId, seatIds, expiresAt];
}
