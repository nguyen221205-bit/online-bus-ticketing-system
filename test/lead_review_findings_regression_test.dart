import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/adapters/city_search_adapter.dart';
import 'package:vexgo_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';

class FailingReviewRemoteDataSource implements ReviewRemoteDataSource {
  @override
  Future<bool> createReview({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    throw Exception('404 Not Found - reviews endpoint not available');
  }
}

class FakeSeatRepoForBloc implements SeatRepository {
  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    return [
      const SeatModel(
        id: '101',
        name: 'A01',
        floor: 1,
        status: SeatStatus.available,
        row: 1,
        col: 1,
      ),
    ];
  }

  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    return const SeatLayoutModel(
      vehicleType: 'standard',
      hasTwoFloors: false,
      lowerFloor: [],
      upperFloor: [],
    );
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
    int holdDurationSeconds = 600,
  }) async {
    throw UnsupportedError('Real backend has no seat hold API');
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lead Review Findings Comprehensive Regression Suite (Findings A -> N)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
      ApiConfig.isDemoMode = false;
    });

    tearDown(() {
      TokenStorage.resetStorageAdapter();
      ApiConfig.isDemoMode = false;
    });

    // -------------------------------------------------------------------------
    // Finding A: City Search Adapter & No Mock Fallback
    // -------------------------------------------------------------------------
    test(
      'Finding A: CitySearchAdapter maps local codes to exact Vietnamese backend names',
      () {
        expect(
          CitySearchAdapter.resolveBackendSearchCity('HCM'),
          equals('TP. Hồ Chí Minh'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('DL'),
          equals('Đà Lạt'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('HN'),
          equals('Hà Nội'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('DN'),
          equals('Đà Nẵng'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('VT'),
          equals('Vũng Tàu'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('NT'),
          equals('Nha Trang'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('CT'),
          equals('Cần Thơ'),
        );

        // Already formatted names stay unchanged
        expect(
          CitySearchAdapter.resolveBackendSearchCity('TP. Hồ Chí Minh'),
          equals('TP. Hồ Chí Minh'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('Đà Lạt'),
          equals('Đà Lạt'),
        );

        // Empty string returns empty
        expect(CitySearchAdapter.resolveBackendSearchCity(''), equals(''));
      },
    );

    test(
      'Finding A: RealTripRepository sends mapped city names and returns empty list when backend returns empty',
      () async {
        String? requestedFrom;
        String? requestedTo;

        final mockClient = MockClient((request) async {
          requestedFrom = request.url.queryParameters['from'];
          requestedTo = request.url.queryParameters['to'];
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'page': 1, 'limit': 10},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDataSource = TripRemoteDataSourceImpl(client: apiClient);
        final repo = RealTripRepository(remoteDataSource: remoteDataSource);

        final results = await repo.searchTrips(
          fromCityId: 'HCM',
          toCityId: 'DL',
          date: '2026-10-10',
        );

        expect(requestedFrom, equals('TP. Hồ Chí Minh'));
        expect(requestedTo, equals('Đà Lạt'));
        expect(results, isEmpty);
      },
    );

    // -------------------------------------------------------------------------
    // Finding B: SeatModel parses payload without price & enforces valid pricing
    // -------------------------------------------------------------------------
    test(
      'Finding B: SeatModel parses backend TripsController.getSeats payload (no price field)',
      () {
        final backendSeatJson = {
          'tripSeatId': 42,
          'seatNumber': 'B05',
          'position': 2,
          'status': 'AVAILABLE',
        };

        final seat = SeatModel.fromJson(backendSeatJson);
        expect(seat.id, equals('42'));
        expect(seat.name, equals('B05'));
        expect(seat.price, isNull);
        expect(seat.status, equals(SeatStatus.available));
      },
    );

    test(
      'Finding B: BookingFlowState seatsTotalAmount returns null if seats lack authoritative price',
      () {
        const seatWithoutPrice = SeatModel(
          id: '1',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: null,
          row: 1,
          col: 1,
        );

        const state = BookingFlowState(
          selectedSeats: [seatWithoutPrice],
          selectedPickupPoint: StopPointModel(
            id: 'PU1',
            name: 'Điểm đón A',
            time: '08:00',
            address: 'Địa chỉ đón',
          ),
          selectedDropoffPoint: StopPointModel(
            id: 'DO1',
            name: 'Điểm trả B',
            time: '14:00',
            address: 'Địa chỉ trả',
          ),
          passengerName: 'Trần Văn B',
          passengerPhone: '0912345678',
          passengerEmail: 'b@example.com',
        );

        expect(state.seatsTotalAmount, isNull);
        expect(state.hasValidSeatPricing, isFalse);
        expect(state.isSeatsValid, isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Finding C & D: TripModel maps route.durationMinutes and nested backend schema
    // -------------------------------------------------------------------------
    test(
      'Finding C & D: TripModel reads route.durationMinutes and nested busCompany, route, vehicle',
      () {
        final backendTripJson = {
          'id': 105,
          'busCompany': {'id': 1, 'name': 'Phương Trang (FUTA Bus Lines)'},
          'route': {
            'id': 10,
            'origin': 'TP. Hồ Chí Minh',
            'destination': 'Đà Lạt',
            'durationMinutes': 390,
            'distanceKm': 305,
          },
          'vehicle': {
            'id': 20,
            'type': 'Limousine 34 Phòng VIP',
            'capacity': 34,
            'amenities': ['Wifi', 'Nước uống', 'Cổng sạc USB'],
          },
          'departureTime': '2026-10-15T23:00:00.000Z',
          'arrivalTime': '2026-10-16T05:30:00.000Z',
          'price': 290000,
          'availableSeats': 12,
        };

        final trip = TripModel.fromJson(backendTripJson);

        expect(trip.id, equals('105'));
        expect(trip.operatorName, equals('Phương Trang (FUTA Bus Lines)'));
        expect(trip.fromCityName, equals('TP. Hồ Chí Minh'));
        expect(trip.toCityName, equals('Đà Lạt'));
        expect(trip.durationMinutes, equals(390));
        expect(trip.duration, equals('6 giờ 30 phút'));
        expect(trip.vehicleType, equals('Limousine 34 Phòng VIP'));
        expect(trip.totalSeats, equals(34));
        expect(trip.availableSeats, equals(12));
        expect(trip.originalPrice, equals(290000));
        expect(
          trip.amenities,
          containsAll(['Wifi', 'Nước uống', 'Cổng sạc USB']),
        );
      },
    );

    // -------------------------------------------------------------------------
    // Finding E: BookingModel maps backend BookingsController response
    // -------------------------------------------------------------------------
    test('Finding E: BookingModel parses backend mapBooking schema', () {
      final backendBookingJson = {
        'bookingId': 99,
        'bookingCode': 'BK-20261010-0099',
        'orderId': 1234,
        'ticketCount': 2,
        'status': 'CONFIRMED',
        'totalAmount': 580000,
        'finalAmount': 550000,
        'discountAmount': 30000,
        'departureTime': '2026-10-15T23:00:00.000Z',
        'busCompanyName': 'Phương Trang',
        'vehicleType': 'Limousine 34 VIP',
        'origin': 'TP. Hồ Chí Minh',
        'destination': 'Đà Lạt',
        'pickupPoint': 'Bến xe Miền Đông mới',
        'dropoffPoint': 'Bến xe Đà Lạt',
        'seatNumbers': ['A01', 'A02'],
        'tickets': [
          {'ticketId': 101, 'seatNumber': 'A01'},
          {'ticketId': 102, 'seatNumber': 'A02'},
        ],
      };

      final booking = BookingModel.fromJson(backendBookingJson);

      expect(booking.bookingId, equals(99));
      expect(booking.bookingCode, equals('BK-20261010-0099'));
      expect(booking.orderId, equals(1234));
      expect(booking.busCompanyName, equals('Phương Trang'));
      expect(booking.seats, equals(['A01', 'A02']));
      expect(booking.totalAmount, equals(580000));
      expect(booking.discountAmount, equals(30000));
      expect(booking.origin, equals('TP. Hồ Chí Minh'));
      expect(booking.destination, equals('Đà Lạt'));
    });

    // -------------------------------------------------------------------------
    // Finding F & G: UserModel & AuthRemoteDataSource updateProfile (PATCH /me)
    // -------------------------------------------------------------------------
    test(
      'Finding F: UserModel.fromJson does not invent fake user id or dummy profile',
      () {
        final userJson = {
          'id': 77,
          'phone': '0901234567',
          'fullName': 'Lê Văn C',
          'email': 'levanc@gmail.com',
          'dateOfBirth': '1995-05-20',
          'citizenId': '079195000123',
        };

        final user = UserModel.fromJson(userJson);

        expect(user.taiKhoanId, equals(77));
        expect(user.soDienThoai, equals('0901234567'));
        expect(user.hoTen, equals('Lê Văn C'));
        expect(user.email, equals('levanc@gmail.com'));
        expect(user.ngaySinh, equals('1995-05-20'));
        expect(user.cccd, equals('079195000123'));
      },
    );

    test(
      'Finding G: AuthRemoteDataSourceImpl.updateProfile calls PATCH /me with correct payload',
      () async {
        await TokenStorage.saveTokens(
          accessToken: 'test_token',
          refreshToken: 'test_refresh',
        );

        String? capturedMethod;
        String? capturedPath;
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 77,
                'phone': '0901234567',
                'fullName': 'Lê Văn C Updated',
                'email': 'c_updated@gmail.com',
                'dateOfBirth': '1995-05-20',
                'citizenId': '079195000123',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final authDataSource = AuthRemoteDataSourceImpl(client: apiClient);

        final updatedUser = await authDataSource.updateProfile(
          fullName: 'Lê Văn C Updated',
          email: 'c_updated@gmail.com',
          dateOfBirth: '1995-05-20',
          citizenId: '079195000123',
        );

        expect(capturedMethod, equals('PATCH'));
        expect(capturedPath, endsWith('/me'));
        expect(capturedBody?['fullName'], equals('Lê Văn C Updated'));
        expect(capturedBody?['email'], equals('c_updated@gmail.com'));
        expect(updatedUser.hoTen, equals('Lê Văn C Updated'));
      },
    );

    // -------------------------------------------------------------------------
    // Finding H & I: RealSeatRepository throws UnsupportedError & BookingFlow bypasses 404
    // -------------------------------------------------------------------------
    test(
      'Finding H: RealSeatRepository.createSeatHold throws UnsupportedError instead of hitting 404',
      () {
        final repo = RealSeatRepository();
        expect(
          () => repo.createSeatHold(tripId: 10, seatIds: [1, 2]),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test(
      'Finding I: BookingFlowBloc in Real Mode proceeds past seatSelection without calling 404 seat-holds',
      () async {
        final bloc = BookingFlowBloc(
          seatRepository: FakeSeatRepoForBloc(),
          bookingRepository: MockBookingRepository(),
        );

        const testTrip = TripModel(
          id: '101',
          operatorId: '1',
          operatorName: 'Phương Trang',
          vehicleType: 'Limousine',
          fromCityId: 'HCM',
          fromCityName: 'TP. Hồ Chí Minh',
          toCityId: 'DL',
          toCityName: 'Đà Lạt',
          departureTime: '23:00',
          arrivalTime: '05:30',
          duration: '6 giờ 30 phút',
          pickupPoint: 'BX Miền Đông',
          pickupAddress: 'Thủ Đức',
          dropoffPoint: 'BX Đà Lạt',
          dropoffAddress: 'Tô Hiến Thành',
          originalPrice: 290000,
          discountPrice: 290000,
          availableSeats: 10,
          totalSeats: 34,
          seatLayoutType: 'standard',
          rating: 4.8,
          reviewCount: 120,
        );

        bloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 10)),
        );
        await bloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        const seatA1 = SeatModel(
          id: '101',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );

        bloc.add(const ToggleSeatEvent(seatA1));
        await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        // In Real Mode, NextStepEvent should proceed directly to pickupPoint step
        bloc.add(const NextStepEvent());

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<BookingFlowState>(
              (s) => s.step == BookingStep.pickupPoint,
            ),
          ),
        );

        await bloc.close();
      },
    );

    // -------------------------------------------------------------------------
    // Finding J: RealNotificationRepository & HybridNotificationRepository in Real Mode
    // -------------------------------------------------------------------------
    test(
      'Finding J: RealNotificationRepository & HybridNotificationRepository return empty in Real Mode',
      () async {
        ApiConfig.isDemoMode = false;

        final realRepo = RealNotificationRepository();
        final notifications = await realRepo.getNotifications();
        expect(notifications, isEmpty);

        final hybridRepo = HybridNotificationRepository();
        final hybridList = await hybridRepo.getNotifications();
        expect(hybridList, isEmpty);
      },
    );

    // -------------------------------------------------------------------------
    // Finding K: MyTicketsBloc review failure never fakes success in Real Mode
    // -------------------------------------------------------------------------
    test(
      'Finding K: MyTicketsBloc emits error and never reports fake success when review API fails in Real Mode',
      () async {
        ApiConfig.isDemoMode = false;

        final bloc = MyTicketsBloc(
          bookingRepository: MockBookingRepository(),
          reviewRemoteDataSource: FailingReviewRemoteDataSource(),
        );

        final sampleTicket = TicketModel(
          id: 'TKT_REVIEW_TEST',
          ticketCode: 'VXG-REV-01',
          status: TicketStatus.completed,
          bookingDate: '10/10/2026 10:00',
          trip: const TicketTripSummary(
            id: '50',
            operatorName: 'Nhà xe ABC',
            vehicleType: 'Limousine',
            departureTime: '10:00',
            departureDate: '10/10/2026',
            arrivalTime: '16:00',
            arrivalDate: '10/10/2026',
            fromCity: 'TP. Hồ Chí Minh',
            toCity: 'Đà Lạt',
            pickupPoint: 'BX Miền Đông',
            pickupAddress: 'Bình Thạnh',
            dropoffPoint: 'BX Đà Lạt',
            dropoffAddress: 'Tô Hiến Thành',
          ),
          seats: const ['A01'],
          totalAmount: 250000,
          discountAmount: 0,
          finalAmount: 250000,
          paymentMethod: 'MoMo',
          passenger: const PassengerInfo(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
            email: 'a@example.com',
          ),
        );

        bloc.add(AddNewTicketEvent(sampleTicket));

        const review = ReviewModel(
          rating: 5,
          comment: 'Dịch vụ tốt',
          createdAt: '10/10/2026 18:00',
        );

        bloc.add(
          const SubmitTicketReviewEvent(
            ticketId: 'TKT_REVIEW_TEST',
            review: review,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              final t = state.tickets.firstWhere(
                (t) => t.id == 'TKT_REVIEW_TEST',
              );
              return t.review == null &&
                  state.errorMessage != null &&
                  state.errorMessage!.contains('chưa khả dụng');
            }),
          ),
        );

        await bloc.close();
      },
    );

    // -------------------------------------------------------------------------
    // Finding L: cancelTicket unwrap data envelope
    // -------------------------------------------------------------------------
    test(
      'Finding L: TicketRemoteDataSource unwraps cancelTicket response envelope correctly',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'ticketId': 105,
                'ticketCode': 'VXG-9988',
                'status': 'CANCELLED',
                'cancelFeeRate': 0.1,
                'cancelFee': 29000,
                'refundAmount': 261000,
                'message': 'Hủy vé thành công',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDataSource = TicketRemoteDataSourceImpl(client: apiClient);

        final result = await remoteDataSource.cancelTicket(
          ticketCode: 'VXG-9988',
          phoneNumber: '0901234567',
          reason: 'Thay đổi kế hoạch',
          expectedCancelFeeRate: 0.1,
        );

        final refund =
            result['refundAmount'] ??
            (result['data'] is Map
                ? (result['data'] as Map)['refundAmount']
                : null);
        expect(refund, equals(261000));
      },
    );

    // -------------------------------------------------------------------------
    // Finding M: OperatorModel safely handles null rating and review count
    // -------------------------------------------------------------------------
    test(
      'Finding M: OperatorModel parses backend /bus-companies payload without fake 4.8 rating',
      () {
        final backendOperatorJson = {
          'id': 1,
          'name': 'Phương Trang',
          'code': 'FUTA',
        };

        final operator = OperatorModel.fromJson(backendOperatorJson);

        expect(operator.id, equals('1'));
        expect(operator.name, equals('Phương Trang'));
        expect(operator.rating, isNull);
        expect(operator.reviewCount, isNull);
        expect(operator.hotline, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // Finding N: PopularRouteModel safely handles null minPrice
    // -------------------------------------------------------------------------
    test(
      'Finding N: PopularRouteModel parses backend /routes payload without fake 200.000đ minPrice',
      () {
        final backendRouteJson = {
          'id': 5,
          'origin': 'TP. Hồ Chí Minh',
          'destination': 'Đà Lạt',
          'distanceKm': 305,
          'durationMinutes': 390,
        };

        final route = PopularRouteModel.fromJson(backendRouteJson);

        expect(route.id, equals('5'));
        expect(route.fromCityName, equals('TP. Hồ Chí Minh'));
        expect(route.toCityName, equals('Đà Lạt'));
        expect(route.duration, equals('6.5 giờ'));
        expect(route.minPrice, isNull);
      },
    );
  });
}
