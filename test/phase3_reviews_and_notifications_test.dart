import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/datasources/remote/notification_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_bloc.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_event.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_state.dart';

class FakeReviewRemoteDataSource implements ReviewRemoteDataSource {
  bool called = false;
  Map<String, dynamic>? lastBody;
  bool shouldThrow = false;

  @override
  Future<bool> createReview({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    called = true;
    lastBody = {
      'tripId': tripId,
      'rating': rating,
      'comment': comment,
    };
    if (shouldThrow) throw Exception('Review submit failed');
    return true;
  }
}

class FakeNotificationRemoteDataSource implements NotificationRemoteDataSource {
  bool shouldThrow = false;
  List<NotificationModel> mockList = [];
  dynamic lastReadId;
  bool markAllCalled = false;

  @override
  Future<List<NotificationModel>> getMyNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (shouldThrow) throw Exception('Notification fetch failed');
    return mockList;
  }

  @override
  Future<bool> markAsRead(dynamic id) async {
    lastReadId = id;
    if (shouldThrow) throw Exception('Mark read failed');
    return true;
  }

  @override
  Future<bool> markAllAsRead() async {
    markAllCalled = true;
    if (shouldThrow) throw Exception('Mark all read failed');
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3: Reviews & Notifications Integration Tests', () {
    late FakeReviewRemoteDataSource fakeReviewDataSource;
    late FakeNotificationRemoteDataSource fakeNotifDataSource;
    late HybridNotificationRepository hybridNotifRepo;

    final sampleNotification = NotificationModel(
      id: 'NOTIF_1',
      title: 'Xác nhận đặt vé thành công',
      message: 'Mã vé VXG-100001 đã sẵn sàng.',
      category: NotificationCategory.trip,
      createdAt: DateTime.now(),
      isRead: false,
    );

    final completedTicket = TicketModel(
      id: 'TKT_COMPLETED_1',
      ticketCode: 'VXG-999888',
      status: TicketStatus.completed,
      bookingDate: '01/10/2026 08:00',
      trip: const TicketTripSummary(
        id: '25',
        operatorName: 'Phương Trang',
        vehicleType: 'Limousine',
        departureTime: '08:00',
        departureDate: '01/10/2026',
        arrivalTime: '14:00',
        arrivalDate: '01/10/2026',
        fromCity: 'TP. Hồ Chí Minh',
        toCity: 'Đà Lạt',
        pickupPoint: 'BX Miền Đông',
        pickupAddress: 'Bình Thạnh',
        dropoffPoint: 'BX Đà Lạt',
        dropoffAddress: 'Tô Hiến Thành',
      ),
      seats: const ['A05'],
      totalAmount: 300000,
      discountAmount: 0,
      finalAmount: 300000,
      paymentMethod: 'MoMo',
      passenger: const PassengerInfo(
        fullName: 'Nguyễn Văn An',
        phone: '0901234567',
        email: 'an@gmail.com',
      ),
    );

    setUp(() {
      fakeReviewDataSource = FakeReviewRemoteDataSource();
      fakeNotifDataSource = FakeNotificationRemoteDataSource();
      hybridNotifRepo = HybridNotificationRepository(
        remoteDataSource: fakeNotifDataSource,
      );
    });

    test('SubmitTicketReviewEvent calls ReviewRemoteDataSource with correct tripId and rating', () async {
      final bloc = MyTicketsBloc(
        reviewRemoteDataSource: fakeReviewDataSource,
      );

      bloc.add(AddNewTicketEvent(completedTicket));

      const review = ReviewModel(
        rating: 5,
        comment: 'Tài xế lái rất êm và cẩn thận',
        createdAt: '2026-10-09T00:00:00.000Z',
      );

      bloc.add(
        const SubmitTicketReviewEvent(
          ticketId: 'TKT_COMPLETED_1',
          review: review,
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MyTicketsState>((state) {
            final t = state.tickets.firstWhere((t) => t.id == 'TKT_COMPLETED_1');
            return t.review != null &&
                t.review!.rating == 5 &&
                state.successMessage != null;
          }),
        ),
      );

      expect(fakeReviewDataSource.called, isTrue);
      expect(fakeReviewDataSource.lastBody?['tripId'], equals(25));
      expect(fakeReviewDataSource.lastBody?['rating'], equals(5));
      expect(fakeReviewDataSource.lastBody?['comment'], equals('Tài xế lái rất êm và cẩn thận'));

      await bloc.close();
    });

    test('HybridNotificationRepository.getNotifications returns remote data', () async {
      fakeNotifDataSource.mockList = [sampleNotification];
      final list = await hybridNotifRepo.getNotifications();

      expect(list.length, equals(1));
      expect(list.first.title, equals('Xác nhận đặt vé thành công'));
    });

    test('HybridNotificationRepository.getNotifications falls back to mock on remote error', () async {
      fakeNotifDataSource.shouldThrow = true;
      final list = await hybridNotifRepo.getNotifications();

      // Successfully loads mock notifications without throwing
      expect(list, isNotEmpty);
    });

    test('NotificationBloc interacts with HybridNotificationRepository seamlessly', () async {
      fakeNotifDataSource.mockList = [sampleNotification];
      final bloc = NotificationBloc(notificationRepository: hybridNotifRepo);

      bloc.add(const LoadNotificationsEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<NotificationState>((state) {
            return state.notifications.length == 1 &&
                state.notifications.first.id == 'NOTIF_1';
          }),
        ),
      );

      bloc.add(const MarkNotificationAsReadEvent('NOTIF_1'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<NotificationState>((state) {
            return state.unreadCount == 0;
          }),
        ),
      );

      expect(fakeNotifDataSource.lastReadId, equals('NOTIF_1'));

      await bloc.close();
    });
  });
}
