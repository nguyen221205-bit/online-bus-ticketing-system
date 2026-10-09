import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/network/api_config.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/seat_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../features/user/my_bookings/bloc/my_tickets_bloc.dart';
import '../features/user/my_bookings/bloc/my_tickets_event.dart';
import '../features/user/notification/bloc/notification_bloc.dart';
import '../features/user/notification/bloc/notification_event.dart';
import '../features/user/profile/bloc/auth_bloc.dart';
import '../features/user/profile/bloc/auth_event.dart';
import 'routes.dart';

class VexGoApp extends StatelessWidget {
  const VexGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDemo = ApiConfig.isDemoMode;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>(
          create: (context) =>
              isDemo ? MockTripRepository() : RealTripRepository(),
        ),
        RepositoryProvider<SeatRepository>(
          create: (context) =>
              isDemo ? MockSeatRepository() : RealSeatRepository(),
        ),
        RepositoryProvider<BookingRepository>(
          create: (context) =>
              isDemo ? MockBookingRepository() : RealBookingRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) =>
              isDemo ? MockAuthRepository() : RealAuthRepository(),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (context) =>
              isDemo ? MockNotificationRepository() : RealNotificationRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MyTicketsBloc>(
            create: (context) => MyTicketsBloc(
              bookingRepository: context.read<BookingRepository>(),
            )..add(const LoadMyTicketsEvent()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(const CheckAuthStatusEvent()),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              notificationRepository: context.read<NotificationRepository>(),
            )..add(const LoadNotificationsEvent()),
          ),
        ],
        child: MaterialApp.router(
          title: 'VexGo - Đặt vé xe khách trực tuyến',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRoutes.router,
        ),
      ),
    );
  }
}
