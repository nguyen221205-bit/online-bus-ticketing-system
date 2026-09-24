import 'package:equatable/equatable.dart';
import '../../../../data/models/city_model.dart';
import '../../../../data/models/flight_search_model.dart';
import '../../../../data/models/operator_model.dart';
import '../../../../data/models/popular_route_model.dart';
import '../../../../data/models/service_type.dart';
import '../../../../data/models/train_search_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final ServiceType selectedService;

  // Xe khách data
  final List<CityModel> cities;
  final List<PopularRouteModel> popularRoutes;
  final List<OperatorModel> operators;
  final CityModel? departureCity;
  final CityModel? destinationCity;
  final int ticketCount;

  // Máy bay data
  final List<AirportModel> airports;
  final AirportModel? departureAirport;
  final AirportModel? destinationAirport;
  final FlightSeatClass flightSeatClass;
  final FlightPassengers flightPassengers;

  // Tàu hỏa data
  final List<TrainStationModel> trainStations;
  final TrainStationModel? departureTrainStation;
  final TrainStationModel? destinationTrainStation;
  final TrainPassengers trainPassengers;

  // Common dates & trip type
  final DateTime departureDate;
  final DateTime? returnDate;
  final bool isRoundTrip;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.selectedService = ServiceType.bus,
    this.cities = const [],
    this.popularRoutes = const [],
    this.operators = const [],
    this.departureCity,
    this.destinationCity,
    this.ticketCount = 1,
    this.airports = const [],
    this.departureAirport,
    this.destinationAirport,
    this.flightSeatClass = FlightSeatClass.economy,
    this.flightPassengers = const FlightPassengers(),
    this.trainStations = const [],
    this.departureTrainStation,
    this.destinationTrainStation,
    this.trainPassengers = const TrainPassengers(),
    required this.departureDate,
    this.returnDate,
    this.isRoundTrip = false,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    ServiceType? selectedService,
    List<CityModel>? cities,
    List<PopularRouteModel>? popularRoutes,
    List<OperatorModel>? operators,
    CityModel? departureCity,
    CityModel? destinationCity,
    int? ticketCount,
    List<AirportModel>? airports,
    AirportModel? departureAirport,
    AirportModel? destinationAirport,
    FlightSeatClass? flightSeatClass,
    FlightPassengers? flightPassengers,
    List<TrainStationModel>? trainStations,
    TrainStationModel? departureTrainStation,
    TrainStationModel? destinationTrainStation,
    TrainPassengers? trainPassengers,
    DateTime? departureDate,
    DateTime? returnDate,
    bool? isRoundTrip,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedService: selectedService ?? this.selectedService,
      cities: cities ?? this.cities,
      popularRoutes: popularRoutes ?? this.popularRoutes,
      operators: operators ?? this.operators,
      departureCity: departureCity ?? this.departureCity,
      destinationCity: destinationCity ?? this.destinationCity,
      ticketCount: ticketCount ?? this.ticketCount,
      airports: airports ?? this.airports,
      departureAirport: departureAirport ?? this.departureAirport,
      destinationAirport: destinationAirport ?? this.destinationAirport,
      flightSeatClass: flightSeatClass ?? this.flightSeatClass,
      flightPassengers: flightPassengers ?? this.flightPassengers,
      trainStations: trainStations ?? this.trainStations,
      departureTrainStation: departureTrainStation ?? this.departureTrainStation,
      destinationTrainStation: destinationTrainStation ?? this.destinationTrainStation,
      trainPassengers: trainPassengers ?? this.trainPassengers,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedService,
        cities,
        popularRoutes,
        operators,
        departureCity,
        destinationCity,
        ticketCount,
        airports,
        departureAirport,
        destinationAirport,
        flightSeatClass,
        flightPassengers,
        trainStations,
        departureTrainStation,
        destinationTrainStation,
        trainPassengers,
        departureDate,
        returnDate,
        isRoundTrip,
        errorMessage,
      ];
}
