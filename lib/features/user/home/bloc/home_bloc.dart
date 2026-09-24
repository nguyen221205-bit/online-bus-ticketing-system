import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/service_type.dart';
import '../../../../data/repositories/trip_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository tripRepository;

  HomeBloc({required this.tripRepository})
      : super(HomeState(departureDate: DateTime.now().add(const Duration(days: 1)))) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<ChangeServiceTypeEvent>(_onChangeServiceType);
    on<SwapCitiesEvent>(_onSwapCities);
    on<SelectDepartureCityEvent>(_onSelectDepartureCity);
    on<SelectDestinationCityEvent>(_onSelectDestinationCity);
    on<SelectDepartureAirportEvent>(_onSelectDepartureAirport);
    on<SelectDestinationAirportEvent>(_onSelectDestinationAirport);
    on<SelectFlightSeatClassEvent>(_onSelectFlightSeatClass);
    on<UpdateFlightPassengersEvent>(_onUpdateFlightPassengers);
    on<SelectDepartureTrainStationEvent>(_onSelectDepartureTrainStation);
    on<SelectDestinationTrainStationEvent>(_onSelectDestinationTrainStation);
    on<UpdateTrainPassengersEvent>(_onUpdateTrainPassengers);
    on<SelectDepartureDateEvent>(_onSelectDepartureDate);
    on<SelectReturnDateEvent>(_onSelectReturnDate);
    on<ToggleRoundTripEvent>(_onToggleRoundTrip);
    on<UpdateTicketCountEvent>(_onUpdateTicketCount);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final cities = await tripRepository.getCities();
      final popularRoutes = await tripRepository.getPopularRoutes();
      final operators = await tripRepository.getOperators();
      final airports = await tripRepository.getAirports();
      final trainStations = await tripRepository.getTrainStations();

      final defaultDepartureCity = cities.firstWhere(
        (c) => c.id == 'HCM',
        orElse: () => cities.isNotEmpty ? cities.first : cities.first,
      );

      final defaultDestinationCity = cities.firstWhere(
        (c) => c.id == 'DL',
        orElse: () => cities.length > 1 ? cities[1] : cities.first,
      );

      final defaultDepartureAirport = airports.firstWhere(
        (a) => a.id == 'SGN',
        orElse: () => airports.isNotEmpty ? airports.first : airports.first,
      );

      final defaultDestinationAirport = airports.firstWhere(
        (a) => a.id == 'HAN',
        orElse: () => airports.length > 1 ? airports[1] : airports.first,
      );

      final defaultDepartureTrainStation = trainStations.firstWhere(
        (t) => t.id == 'GA_SGN',
        orElse: () => trainStations.isNotEmpty ? trainStations.first : trainStations.first,
      );

      final defaultDestinationTrainStation = trainStations.firstWhere(
        (t) => t.id == 'GA_NT',
        orElse: () => trainStations.length > 1 ? trainStations[1] : trainStations.first,
      );

      emit(state.copyWith(
        status: HomeStatus.success,
        cities: cities,
        popularRoutes: popularRoutes,
        operators: operators,
        airports: airports,
        trainStations: trainStations,
        departureCity: defaultDepartureCity,
        destinationCity: defaultDestinationCity,
        departureAirport: defaultDepartureAirport,
        destinationAirport: defaultDestinationAirport,
        departureTrainStation: defaultDepartureTrainStation,
        destinationTrainStation: defaultDestinationTrainStation,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: 'Không thể tải dữ liệu trang chủ: $e',
      ));
    }
  }

  void _onChangeServiceType(
    ChangeServiceTypeEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedService: event.serviceType));
  }

  void _onSwapCities(
    SwapCitiesEvent event,
    Emitter<HomeState> emit,
  ) {
    switch (state.selectedService) {
      case ServiceType.bus:
        final temp = state.departureCity;
        emit(state.copyWith(
          departureCity: state.destinationCity,
          destinationCity: temp,
        ));
        break;
      case ServiceType.flight:
        final temp = state.departureAirport;
        emit(state.copyWith(
          departureAirport: state.destinationAirport,
          destinationAirport: temp,
        ));
        break;
      case ServiceType.train:
        final temp = state.departureTrainStation;
        emit(state.copyWith(
          departureTrainStation: state.destinationTrainStation,
          destinationTrainStation: temp,
        ));
        break;
      case ServiceType.carRental:
        break;
    }
  }

  void _onSelectDepartureCity(
    SelectDepartureCityEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(departureCity: event.city));
  }

  void _onSelectDestinationCity(
    SelectDestinationCityEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(destinationCity: event.city));
  }

  void _onSelectDepartureAirport(
    SelectDepartureAirportEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(departureAirport: event.airport));
  }

  void _onSelectDestinationAirport(
    SelectDestinationAirportEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(destinationAirport: event.airport));
  }

  void _onSelectFlightSeatClass(
    SelectFlightSeatClassEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(flightSeatClass: event.seatClass));
  }

  void _onUpdateFlightPassengers(
    UpdateFlightPassengersEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(flightPassengers: event.passengers));
  }

  void _onSelectDepartureTrainStation(
    SelectDepartureTrainStationEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(departureTrainStation: event.station));
  }

  void _onSelectDestinationTrainStation(
    SelectDestinationTrainStationEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(destinationTrainStation: event.station));
  }

  void _onUpdateTrainPassengers(
    UpdateTrainPassengersEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(trainPassengers: event.passengers));
  }

  void _onSelectDepartureDate(
    SelectDepartureDateEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(departureDate: event.date));
  }

  void _onSelectReturnDate(
    SelectReturnDateEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(returnDate: event.date));
  }

  void _onToggleRoundTrip(
    ToggleRoundTripEvent event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(
      isRoundTrip: event.isRoundTrip,
      returnDate: event.isRoundTrip
          ? (state.returnDate ?? state.departureDate.add(const Duration(days: 2)))
          : null,
    ));
  }

  void _onUpdateTicketCount(
    UpdateTicketCountEvent event,
    Emitter<HomeState> emit,
  ) {
    if (event.count >= 1 && event.count <= 10) {
      emit(state.copyWith(ticketCount: event.count));
    }
  }
}
