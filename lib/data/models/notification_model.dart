import 'package:equatable/equatable.dart';

enum NotificationType { tripReminder, promotion, bookingSuccess, system }

class NotificationModel extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String createdAt;
  final bool isRead;
  final String? ticketId;
  final String? promoCode;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.ticketId,
    this.promoCode,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? typeStr) {
      switch (typeStr) {
        case 'TRIP_REMINDER':
          return NotificationType.tripReminder;
        case 'PROMOTION':
          return NotificationType.promotion;
        case 'BOOKING_SUCCESS':
          return NotificationType.bookingSuccess;
        default:
          return NotificationType.system;
      }
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: parseType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      ticketId: json['ticketId'] as String?,
      promoCode: json['promoCode'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, isRead, createdAt];
}
