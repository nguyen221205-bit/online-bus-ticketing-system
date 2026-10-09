import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_storage.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String phone, required String password});
  Future<String> sendOtp({required String phone});
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
    String? challengeId,
  });
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({
    String? fullName,
    String? dateOfBirth,
    String? email,
    String? citizenId,
  });
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final body = {'phoneNumber': formattedPhone, 'password': password};

    final res = await client.post(
      ApiConfig.authLogin,
      body: body,
      requiresAuth: false,
    );

    if (res is Map<String, dynamic>) {
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      final userJson = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(userJson);
    }
    throw Exception('Phản hồi đăng nhập không hợp lệ');
  }

  @override
  Future<String> sendOtp({required String phone}) async {
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final res = await client.post(
      ApiConfig.authRequestOtp,
      body: {'phoneNumber': formattedPhone},
      requiresAuth: false,
    );
    if (res is Map<String, dynamic>) {
      final challengeId =
          res['challengeId'] as String? ??
          (res['data'] is Map<String, dynamic>
              ? res['data']['challengeId'] as String?
              : null);
      if (challengeId != null && challengeId.isNotEmpty) {
        return challengeId;
      }
    }
    return '';
  }

  @override
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
    String? challengeId,
  }) async {
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final verifyBody = <String, dynamic>{
      'phoneNumber': formattedPhone,
      'otp': otp,
    };
    if (challengeId != null && challengeId.isNotEmpty) {
      verifyBody['challengeId'] = challengeId;
    }
    final verifyRes = await client.post(
      ApiConfig.authVerifyOtp,
      body: verifyBody,
      requiresAuth: false,
    );

    String otpProof = '';
    if (verifyRes is Map<String, dynamic>) {
      otpProof =
          verifyRes['otpProof'] as String? ??
          (verifyRes['data'] is Map<String, dynamic>
              ? verifyRes['data']['otpProof'] as String? ?? ''
              : '');
    }

    final registerRes = await client.post(
      ApiConfig.authRegister,
      body: {
        'fullName': fullName,
        'phoneNumber': formattedPhone,
        'password': password,
        'otpProof': otpProof,
      },
      requiresAuth: false,
    );

    if (registerRes is Map<String, dynamic>) {
      final data = registerRes['data'] is Map<String, dynamic>
          ? registerRes['data'] as Map<String, dynamic>
          : registerRes;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      final userJson = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(userJson);
    }
    throw Exception('Phản hồi đăng ký không hợp lệ');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final hasToken = await TokenStorage.hasAccessToken();
    if (!hasToken) return null;

    try {
      final res = await client.get(ApiConfig.authSession, requiresAuth: true);
      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        final userJson = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? dateOfBirth,
    String? email,
    String? citizenId,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (email != null) body['email'] = email;
    if (citizenId != null) body['citizenId'] = citizenId;
    final res = await client.patch(
      ApiConfig.me,
      body: body,
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      return UserModel.fromJson(data);
    }
    throw Exception('Phản hồi cập nhật thông tin không hợp lệ');
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await client.post(
          ApiConfig.authLogout,
          body: {'refreshToken': refreshToken},
          requiresAuth: false,
        );
      }
    } catch (_) {
      // Ignore network / token errors to guarantee local state clearance
    } finally {
      await TokenStorage.clearTokens();
    }
  }
}
