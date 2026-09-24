import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/flight_search_model.dart';
import 'package:vexgo_app/data/models/service_type.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../screens/select_airport_sheet.dart';
import '../screens/select_city_sheet.dart';
import '../screens/select_train_station_sheet.dart';
import 'flight_passengers_sheet.dart';
import 'train_passengers_sheet.dart';

class SearchFormCard extends StatelessWidget {
  const SearchFormCard({super.key});

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required ValueChanged<DateTime> onDateSelected,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 120)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final homeBloc = context.read<HomeBloc>();
        final service = state.selectedService;

        // Departure & destination titles & values depending on service
        String originLabel;
        String originValue;
        String destinationLabel;
        String destinationValue;
        VoidCallback onSelectOrigin;
        VoidCallback onSelectDestination;

        switch (service) {
          case ServiceType.bus:
            originLabel = 'Nơi xuất phát';
            originValue = state.departureCity?.name ?? 'Chọn điểm đi';
            destinationLabel = 'Nơi đến';
            destinationValue = state.destinationCity?.name ?? 'Chọn điểm đến';
            onSelectOrigin = () async {
              final city = await SelectCitySheet.show(
                context,
                title: 'Chọn điểm xuất phát',
                cities: state.cities,
                currentCity: state.departureCity,
              );
              if (city != null) homeBloc.add(SelectDepartureCityEvent(city));
            };
            onSelectDestination = () async {
              final city = await SelectCitySheet.show(
                context,
                title: 'Chọn điểm đến',
                cities: state.cities,
                currentCity: state.destinationCity,
              );
              if (city != null) homeBloc.add(SelectDestinationCityEvent(city));
            };
            break;

          case ServiceType.flight:
            originLabel = 'Sân bay đi';
            originValue = state.departureAirport?.name ?? 'Chọn sân bay đi';
            destinationLabel = 'Sân bay đến';
            destinationValue = state.destinationAirport?.name ?? 'Chọn sân bay đến';
            onSelectOrigin = () async {
              final airport = await SelectAirportSheet.show(
                context,
                title: 'Chọn sân bay xuất phát',
                airports: state.airports,
                currentAirport: state.departureAirport,
              );
              if (airport != null) homeBloc.add(SelectDepartureAirportEvent(airport));
            };
            onSelectDestination = () async {
              final airport = await SelectAirportSheet.show(
                context,
                title: 'Chọn sân bay đến',
                airports: state.airports,
                currentAirport: state.destinationAirport,
              );
              if (airport != null) homeBloc.add(SelectDestinationAirportEvent(airport));
            };
            break;

          case ServiceType.train:
            originLabel = 'Ga xuất phát';
            originValue = state.departureTrainStation?.name ?? 'Chọn ga đi';
            destinationLabel = 'Ga đến';
            destinationValue = state.destinationTrainStation?.name ?? 'Chọn ga đến';
            onSelectOrigin = () async {
              final station = await SelectTrainStationSheet.show(
                context,
                title: 'Chọn ga tàu xuất phát',
                stations: state.trainStations,
                currentStation: state.departureTrainStation,
              );
              if (station != null) homeBloc.add(SelectDepartureTrainStationEvent(station));
            };
            onSelectDestination = () async {
              final station = await SelectTrainStationSheet.show(
                context,
                title: 'Chọn ga tàu đến',
                stations: state.trainStations,
                currentStation: state.destinationTrainStation,
              );
              if (station != null) homeBloc.add(SelectDestinationTrainStationEvent(station));
            };
            break;

          case ServiceType.carRental:
            originLabel = 'Điểm nhận xe';
            originValue = 'TP. Hồ Chí Minh';
            destinationLabel = 'Điểm trả xe';
            destinationValue = 'TP. Hồ Chí Minh';
            onSelectOrigin = () {};
            onSelectDestination = () {};
            break;
        }

        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final isToday = state.departureDate.year == today.year &&
            state.departureDate.month == today.month &&
            state.departureDate.day == today.day;
        final isTomorrow = state.departureDate.year == tomorrow.year &&
            state.departureDate.month == tomorrow.month &&
            state.departureDate.day == tomorrow.day;

        return Card(
          elevation: 6,
          shadowColor: const Color(0x1F000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin & Destination Row with Swap Button
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                      children: [
                        // Nơi xuất phát
                        InkWell(
                          onTap: onSelectOrigin,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.md,
                              vertical: AppDimensions.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(color: AppColors.neutral200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        originLabel,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.neutral500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        originValue,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppDimensions.sm),

                        // Nơi đến
                        InkWell(
                          onTap: onSelectDestination,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.md,
                              vertical: AppDimensions.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(color: AppColors.neutral200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: AppDimensions.md - 2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        destinationLabel,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.neutral500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        destinationValue,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Swap Button Floating on the right
                    Positioned(
                      right: 12,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          onTap: () => homeBloc.add(const SwapCitiesEvent()),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(AppDimensions.xs + 2),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.md),

                // Departure Date Section
                InkWell(
                  onTap: () => _pickDate(
                    context,
                    initialDate: state.departureDate,
                    firstDate: DateTime.now(),
                    onDateSelected: (date) {
                      homeBloc.add(SelectDepartureDateEvent(date));
                    },
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ngày đi',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormatter.formatFullDate(state.departureDate),
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Quick buttons: Hôm nay, Ngày mai
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => homeBloc.add(SelectDepartureDateEvent(today)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isToday ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                  border: Border.all(
                                    color: isToday ? AppColors.primary : AppColors.neutral300,
                                  ),
                                ),
                                child: Text(
                                  'Hôm nay',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isToday ? Colors.white : AppColors.neutral700,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => homeBloc.add(SelectDepartureDateEvent(tomorrow)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isTomorrow ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                  border: Border.all(
                                    color: isTomorrow ? AppColors.primary : AppColors.neutral300,
                                  ),
                                ),
                                child: Text(
                                  'Ngày mai',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isTomorrow ? Colors.white : AppColors.neutral700,
                                    fontWeight: isTomorrow ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Return Date Row (if Roundtrip)
                if (state.isRoundTrip) ...[
                  const SizedBox(height: AppDimensions.sm),
                  InkWell(
                    onTap: () => _pickDate(
                      context,
                      initialDate: state.returnDate ?? state.departureDate.add(const Duration(days: 2)),
                      firstDate: state.departureDate,
                      onDateSelected: (date) {
                        homeBloc.add(SelectReturnDateEvent(date));
                      },
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_repeat_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ngày về (Khứ hồi)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.returnDate != null
                                      ? DateFormatter.formatFullDate(state.returnDate!)
                                      : 'Chọn ngày về',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.md),

                // Dynamic options row according to ServiceType
                if (service == ServiceType.bus) ...[
                  // XE KHÁCH: Khứ hồi & Số lượng vé
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 36,
                            child: Switch(
                              value: state.isRoundTrip,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => homeBloc.add(ToggleRoundTripEvent(val)),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text(
                            'Khứ hồi',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: state.isRoundTrip ? AppColors.primary : AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Số vé:',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral600,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          InkWell(
                            onTap: state.ticketCount > 1
                                ? () => homeBloc.add(UpdateTicketCountEvent(state.ticketCount - 1))
                                : null,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: state.ticketCount > 1 ? AppColors.neutral100 : AppColors.neutral50,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: state.ticketCount > 1 ? AppColors.neutral800 : AppColors.neutral300,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                            child: Text(
                              '${state.ticketCount}',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          InkWell(
                            onTap: state.ticketCount < 10
                                ? () => homeBloc.add(UpdateTicketCountEvent(state.ticketCount + 1))
                                : null,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: state.ticketCount < 10 ? AppColors.neutral100 : AppColors.neutral50,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: state.ticketCount < 10 ? AppColors.neutral800 : AppColors.neutral300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else if (service == ServiceType.flight) ...[
                  // MÁY BAY: Khứ hồi + Chọn Hạng ghế & 3 nhóm tuổi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 36,
                            child: Switch(
                              value: state.isRoundTrip,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => homeBloc.add(ToggleRoundTripEvent(val)),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text(
                            'Khứ hồi',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: state.isRoundTrip ? AppColors.primary : AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${state.flightPassengers.totalPassengers} hành khách',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  InkWell(
                    onTap: () async {
                      final result = await FlightPassengersSheet.show(
                        context,
                        seatClass: state.flightSeatClass,
                        passengers: state.flightPassengers,
                      );
                      if (result != null) {
                        homeBloc.add(SelectFlightSeatClassEvent(result['seatClass'] as FlightSeatClass));
                        homeBloc.add(UpdateFlightPassengersEvent(result['passengers'] as FlightPassengers));
                      }
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.airline_seat_recline_extra_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hạng ghế: ${state.flightSeatClass.label}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  state.flightPassengers.summaryText,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.neutral700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 20, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ] else if (service == ServiceType.train) ...[
                  // TÀU HỎA: Khứ hồi + Chọn 5 đối tượng hành khách
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 36,
                            child: Switch(
                              value: state.isRoundTrip,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => homeBloc.add(ToggleRoundTripEvent(val)),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text(
                            'Khứ hồi',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: state.isRoundTrip ? AppColors.primary : AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${state.trainPassengers.totalPassengers} vé',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  InkWell(
                    onTap: () async {
                      final result = await TrainPassengersSheet.show(
                        context,
                        passengers: state.trainPassengers,
                      );
                      if (result != null) {
                        homeBloc.add(UpdateTrainPassengersEvent(result));
                      }
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đối tượng hành khách:',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  state.trainPassengers.summaryText,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.neutral700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 20, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.base),

                // CTA Button
                CustomButton(
                  text: service == ServiceType.bus
                      ? 'TÌM CHUYẾN XE'
                      : (service == ServiceType.flight ? 'TÌM CHUYẾN BAY' : 'TÌM CHUYẾN TÀU'),
                  width: double.infinity,
                  height: 50,
                  type: ButtonType.secondary,
                  prefixIcon: Icon(
                    service == ServiceType.bus
                        ? Icons.search_rounded
                        : (service == ServiceType.flight ? Icons.flight_takeoff_rounded : Icons.train_rounded),
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    if (service == ServiceType.bus) {
                      context.push(
                        '/search-trips',
                        extra: {
                          'fromCity': state.departureCity,
                          'toCity': state.destinationCity,
                          'date': state.departureDate,
                          'ticketCount': state.ticketCount,
                        },
                      );
                    } else if (service == ServiceType.flight) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: const [
                              Icon(Icons.flight_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tìm Vé Máy Bay',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            'Hành trình: ${state.departureAirport?.name} -> ${state.destinationAirport?.name}\n'
                            'Ngày bay: ${DateFormatter.formatFullDate(state.departureDate)}\n'
                            'Hạng ghế: ${state.flightSeatClass.label}\n'
                            'Hành khách: ${state.flightPassengers.summaryText}\n\n'
                            '(Chức năng tìm kiếm chuyến bay đã sẵn sàng kết nối API hãng hàng không!)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    } else if (service == ServiceType.train) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: const [
                              Icon(Icons.train_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tìm Vé Tàu Hỏa',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            'Hành trình: ${state.departureTrainStation?.name} -> ${state.destinationTrainStation?.name}\n'
                            'Ngày đi: ${DateFormatter.formatFullDate(state.departureDate)}\n'
                            'Đối tượng: ${state.trainPassengers.summaryText}\n\n'
                            '(Chức năng tìm kiếm chuyến tàu đã sẵn sàng kết nối hệ thống Đường Sắt Việt Nam!)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
