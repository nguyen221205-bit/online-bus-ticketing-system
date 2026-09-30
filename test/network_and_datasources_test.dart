import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/payment_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/payment_transaction_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.resetBaseUrl();
  });

  group('Task 2: Network Client & Data Sources Tests', () {
    // -------------------------------------------------------------------------
    // 1. ApiConfig & TokenStorage Tests
    // -------------------------------------------------------------------------
    group('ApiConfig & TokenStorage', () {
      test('ApiConfig allows custom base URL and trims trailing slash', () {
        expect(ApiConfig.baseUrl, contains('/api/v1'));
        ApiConfig.setCustomBaseUrl('http://192.168.1.100:3000/api/v1/');
        expect(ApiConfig.baseUrl, equals('http://192.168.1.100:3000/api/v1'));

        ApiConfig.resetBaseUrl();
        expect(ApiConfig.baseUrl, isNot(equals('http://192.168.1.100:3000/api/v1')));
      });

      test('ApiConfig paths generation', () {
        expect(ApiConfig.tripDetail(101), equals('/trips/101'));
        expect(ApiConfig.tripSeats(101), equals('/trips/101/seats'));
        expect(ApiConfig.seatHoldRelease('token_123'), equals('/seat-holds/token_123'));
        expect(ApiConfig.bookingDetail(202), equals('/bookings/202'));
        expect(ApiConfig.paymentStatus(303), equals('/payments/303/status'));
      });

      test('TokenStorage saves, reads, and clears tokens', () async {
        await TokenStorage.init();
        expect(TokenStorage.currentToken, isNull);

        await TokenStorage.saveTokens(
          accessToken: 'mock_access_jwt',
          refreshToken: 'mock_refresh_jwt',
        );

        expect(TokenStorage.currentToken, equals('mock_access_jwt'));
        final readAccess = await TokenStorage.getAccessToken();
        final readRefresh = await TokenStorage.getRefreshToken();
        expect(readAccess, equals('mock_access_jwt'));
        expect(readRefresh, equals('mock_refresh_jwt'));

        await TokenStorage.clearTokens();
        expect(TokenStorage.currentToken, isNull);
        expect(await TokenStorage.getAccessToken(), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 2. ApiClient with Mock HTTP Client
    // -------------------------------------------------------------------------
    group('ApiClient HTTP & Error Handling', () {
      test('GET request attaches Bearer token and returns JSON', () async {
        await TokenStorage.saveTokens(accessToken: 'valid_bearer_token');

        final mockClient = MockClient((request) async {
          expect(request.headers['Authorization'], equals('Bearer valid_bearer_token'));
          expect(request.headers['Accept'], equals('application/json'));
          return http.Response(
            jsonEncode({'data': {'message': 'success'}}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final res = await apiClient.get('/test');
        expect(res['data']['message'], equals('success'));
      });

      test('POST request encodes body properly', () async {
        final mockClient = MockClient((request) async {
          final bodyMap = jsonDecode(request.body) as Map<String, dynamic>;
          expect(bodyMap['tripId'], equals(123));
          return http.Response(
            jsonEncode({'data': {'holdToken': 'token_abc'}}),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final res = await apiClient.post('/test-post', body: {'tripId': 123});
        expect(res['data']['holdToken'], equals('token_abc'));
      });

      test('401 response throws UnauthorizedException', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'statusCode': 401, 'error': 'UNAUTHORIZED', 'message': 'Token hết hạn'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        expect(
          () => apiClient.get('/protected'),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('409 SEAT_UNAVAILABLE response throws ApiException with details', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'statusCode': 409,
              'error': 'SEAT_UNAVAILABLE',
              'message': 'Ghế đã được đặt bởi khách khác.',
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        try {
          await apiClient.post('/seat-holds', body: {'seatIds': [10]});
          fail('Should throw ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, equals(409));
          expect(e.errorCode, equals('SEAT_UNAVAILABLE'));
          expect(e.message, contains('Ghế đã được đặt'));
        }
      });
    });

    // -------------------------------------------------------------------------
    // 3. Remote DataSources Tests
    // -------------------------------------------------------------------------
    group('Remote DataSources', () {
      test('TripRemoteDataSourceImpl searches trips', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['from'], equals('SGN'));
          expect(request.url.queryParameters['to'], equals('DLT'));
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'tripId': 101,
                  'busCompanyId': 1,
                  'busCompanyName': 'Phương Trang',
                  'vehicleTypeName': 'Limousine',
                  'price': 280000,
                  'availableSeats': 10,
                  'totalSeats': 34,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final ds = TripRemoteDataSourceImpl(client: ApiClient(httpClient: mockClient));
        final trips = await ds.searchTrips(from: 'SGN', to: 'DLT');
        expect(trips.length, equals(1));
        expect(trips.first.id, equals('101'));
        expect(trips.first.operatorName, equals('Phương Trang'));
      });

      test('SeatRemoteDataSourceImpl creates and releases hold', () async {
        final mockClient = MockClient((request) async {
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({
                'data': {
                  'holdToken': 'hold_uuid_test',
                  'tripId': 101,
                  'seatIds': [10, 11],
                  'expiresAt': '2026-10-01T12:00:00.000Z',
                }
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          } else {
            // DELETE
            return http.Response(jsonEncode({'data': {'success': true}}), 200);
          }
        });

        final ds = SeatRemoteDataSourceImpl(client: ApiClient(httpClient: mockClient));
        final hold = await ds.createSeatHold(tripId: 101, seatIds: [10, 11]);
        expect(hold.holdToken, equals('hold_uuid_test'));
        expect(hold.seatIds, equals([10, 11]));

        final released = await ds.releaseSeatHold('hold_uuid_test');
        expect(released, isTrue);
      });

      test('BookingRemoteDataSourceImpl quotes and creates booking', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/quote')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'unitPrice': 250000,
                  'seatCount': 2,
                  'originalTotal': 500000,
                  'discountAmount': 50000,
                  'finalTotal': 450000,
                  'currency': 'VND',
                  'appliedPromotionCode': 'SUMMER26',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (request.url.path.contains('/validate')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'code': 'SUMMER26',
                  'isValid': true,
                  'discountAmount': 50000,
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else {
            // Create booking
            return http.Response(
              jsonEncode({
                'data': {
                  'bookingId': 999,
                  'bookingCode': 'VXG-999',
                  'tripId': 101,
                  'status': 'CHO_THANH_TOAN',
                  'contact': {
                    'fullName': 'Nguyễn Văn An',
                    'phone': '0901234567',
                    'email': 'an@test.com',
                  },
                  'pickupPoint': 'Bến xe Miền Đông',
                  'dropoffPoint': 'Bến xe Đà Lạt',
                  'seats': ['A01', 'A02'],
                  'seatIds': [10, 11],
                  'totalAmount': 450000,
                }
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
        });

        final ds = BookingRemoteDataSourceImpl(client: ApiClient(httpClient: mockClient));
        final quote = await ds.getBookingQuote(tripId: 101, seatIds: [10, 11], promotionCode: 'SUMMER26');
        expect(quote.finalTotal, equals(450000));

        final promo = await ds.validatePromotion(code: 'SUMMER26', tripId: 101, seatCount: 2, totalAmount: 500000);
        expect(promo.isValid, isTrue);

        final booking = await ds.createBooking(
          tripId: 101,
          seatIds: [10, 11],
          pickupPoint: 'Bến xe Miền Đông',
          dropoffPoint: 'Bến xe Đà Lạt',
          contact: const PassengerInfo(fullName: 'Nguyễn Văn An', phone: '0901234567', email: 'an@test.com'),
        );
        expect(booking.bookingId, equals(999));
        expect(booking.isPending, isTrue);
      });

      test('PaymentRemoteDataSourceImpl creates payment and checks status', () async {
        final mockClient = MockClient((request) async {
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({
                'data': {
                  'paymentId': 555,
                  'bookingId': 999,
                  'provider': 'MOMO',
                  'amount': 450000,
                  'paymentUrl': 'https://pay.momo.vn/pay?id=555',
                  'deeplink': 'momo://app?id=555',
                  'status': 'PENDING',
                }
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          } else {
            return http.Response(
              jsonEncode({
                'data': {
                  'paymentId': 555,
                  'bookingId': 999,
                  'provider': 'MOMO',
                  'amount': 450000,
                  'status': 'SUCCESS',
                  'paidAt': '2026-10-01T12:05:00.000Z',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        });

        final ds = PaymentRemoteDataSourceImpl(client: ApiClient(httpClient: mockClient));
        final payment = await ds.createPayment(bookingId: 999, provider: 'MOMO');
        expect(payment.paymentId, equals(555));
        expect(payment.provider, equals(PaymentProvider.momo));
        expect(payment.status, equals(PaymentStatus.pending));

        final status = await ds.getPaymentStatus(555);
        expect(status.status, equals(PaymentStatus.success));
        expect(status.isSuccess, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 4. Hybrid Repositories Fallback Mechanism
    // -------------------------------------------------------------------------
    group('Hybrid Repositories Fallback', () {
      test('HybridTripRepository falls back to Mock on NetworkException', () async {
        // MockClient throwing NetworkException by returning 500 or failing
        final failingClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        final hybridRepo = HybridTripRepository(
          remoteDataSource: TripRemoteDataSourceImpl(client: ApiClient(httpClient: failingClient)),
          mockFallback: MockTripRepository(),
        );

        final trips = await hybridRepo.searchTrips(fromCityId: 'SGN', toCityId: 'DLT');
        expect(trips, isNotEmpty);
      });

      test('HybridSeatRepository falls back to Mock on error', () async {
        final failingClient = MockClient((request) async {
          throw http.ClientException('Server down');
        });

        final hybridRepo = HybridSeatRepository(
          remoteDataSource: SeatRemoteDataSourceImpl(client: ApiClient(httpClient: failingClient)),
          mockFallback: MockSeatRepository(),
        );

        final hold = await hybridRepo.createSeatHold(tripId: 101, seatIds: [10, 11]);
        expect(hold.holdToken, contains('mock-hold'));
        expect(hold.seatIds, equals([10, 11]));
      });

      test('HybridBookingRepository falls back to Mock on error', () async {
        final failingClient = MockClient((request) async {
          throw http.ClientException('Server down');
        });

        final hybridRepo = HybridBookingRepository(
          remoteBookingDataSource: BookingRemoteDataSourceImpl(client: ApiClient(httpClient: failingClient)),
          remotePaymentDataSource: PaymentRemoteDataSourceImpl(client: ApiClient(httpClient: failingClient)),
          mockFallback: MockBookingRepository(),
        );

        final quote = await hybridRepo.getBookingQuote(tripId: 101, seatIds: [10, 11]);
        expect(quote.finalTotal, greaterThan(0));

        final promo = await hybridRepo.validatePromotion(code: 'VEXGO50', tripId: 101, seatCount: 2, totalAmount: 500000);
        expect(promo.isValid, isTrue);

        final booking = await hybridRepo.createApiBooking(
          tripId: 101,
          seatIds: [10, 11],
          pickupPoint: 'Bến xe',
          dropoffPoint: 'Bến xe',
          contact: const PassengerInfo(fullName: 'An', phone: '0901', email: 'an@test.com'),
        );
        expect(booking.bookingId, greaterThan(0));
        expect(booking.isPending, isTrue);
      });
    });
  });
}
