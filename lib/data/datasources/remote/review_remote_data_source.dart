import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class ReviewRemoteDataSource {
  Future<bool> createReview({
    required int tripId,
    required int rating,
    String? comment,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient client;

  ReviewRemoteDataSourceImpl({required this.client});

  @override
  Future<bool> createReview({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'tripId': tripId,
      'rating': rating,
    };
    if (comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
    }

    final res = await client.post(
      ApiConfig.reviews,
      body: body,
      requiresAuth: true,
    );

    return res != null;
  }
}
