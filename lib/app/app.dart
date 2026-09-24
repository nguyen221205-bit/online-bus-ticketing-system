import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/seat_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../features/user/my_bookings/bloc/my_tickets_bloc.dart';
import '../features/user/my_bookings/bloc/my_tickets_event.dart';
import 'routes.dart';

class VexGoApp extends StatelessWidget {
  const VexGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>(
          create: (context) => MockTripRepository(),
        ),
        RepositoryProvider<SeatRepository>(
          create: (context) => MockSeatRepository(),
        ),
        RepositoryProvider<BookingRepository>(
          create: (context) => MockBookingRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MyTicketsBloc>(
            create: (context) => MyTicketsBloc()..add(const LoadMyTicketsEvent()),
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
