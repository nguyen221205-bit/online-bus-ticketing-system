import '../../models/notification_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<List<NotificationModel>> getMyNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<bool> markAsRead(dynamic id);
  Future<bool> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient client;

  NotificationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificationModel>> getNotifications() => getMyNotifications();

  @override
  Future<List<NotificationModel>> getMyNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'unreadOnly': unreadOnly,
      'page': page,
      'pageSize': pageSize,
    };

    final res = await client.get(
      ApiConfig.notifications,
      queryParams: query,
      requiresAuth: true,
    );

    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is List) {
        return data
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (res is List) {
      return res
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<bool> markAsRead(dynamic id) async {
    final res = await client.patch(
      ApiConfig.notificationRead(id),
      requiresAuth: true,
    );
    return res != null;
  }

  @override
  Future<bool> markAllAsRead() async {
    final res = await client.patch(
      ApiConfig.notificationReadAll,
      requiresAuth: true,
    );
    return res != null;
  }
}
