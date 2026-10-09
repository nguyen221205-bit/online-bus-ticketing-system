import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'my_tickets_event.dart';
import 'my_tickets_state.dart';

class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  final BookingRepository bookingRepository;
  final ReviewRemoteDataSource reviewRemoteDataSource;

  MyTicketsBloc({
    BookingRepository? bookingRepository,
    ReviewRemoteDataSource? reviewRemoteDataSource,
  }) : bookingRepository = bookingRepository ?? HybridBookingRepository(),
       reviewRemoteDataSource =
           reviewRemoteDataSource ??
           ReviewRemoteDataSourceImpl(client: ApiClient()),
       super(const MyTicketsState()) {
    on<LoadMyTicketsEvent>(_onLoadMyTickets);
    on<AddNewTicketEvent>(_onAddNewTicket);
    on<ChangeTabEvent>(_onChangeTab);
    on<SearchTicketsEvent>(_onSearchTickets);
    on<CancelTicketEvent>(_onCancelTicket);
    on<SubmitTicketReviewEvent>(_onSubmitReview);
  }

  Future<void> _onLoadMyTickets(
    LoadMyTicketsEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    // If already loaded and we have tickets, don't overwrite if not necessary
    if (state.tickets.isNotEmpty && state.status == MyTicketsStatus.loaded) {
      return;
    }

    emit(state.copyWith(status: MyTicketsStatus.loading, clearMessages: true));

    try {
      final loadedTickets = await bookingRepository.getMyTickets();

      emit(
        state.copyWith(
          status: MyTicketsStatus.loaded,
          tickets: loadedTickets,
          clearMessages: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MyTicketsStatus.error,
          errorMessage: 'Không thể tải danh sách vé: $e',
        ),
      );
    }
  }

  void _onAddNewTicket(AddNewTicketEvent event, Emitter<MyTicketsState> emit) {
    // Avoid duplicate
    final existingIndex = state.tickets.indexWhere(
      (t) => t.id == event.ticket.id,
    );
    List<TicketModel> updatedList;
    if (existingIndex >= 0) {
      updatedList = List.from(state.tickets);
      updatedList[existingIndex] = event.ticket;
    } else {
      updatedList = [event.ticket, ...state.tickets];
    }

    emit(
      state.copyWith(
        status: MyTicketsStatus.loaded,
        tickets: updatedList,
        selectedTab: TicketStatus.upcoming,
        successMessage:
            'Đặt vé thành công! Mã vé ${event.ticket.ticketCode} đã được lưu.',
      ),
    );
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<MyTicketsState> emit) {
    emit(state.copyWith(selectedTab: event.status, clearMessages: true));
  }

  void _onSearchTickets(
    SearchTicketsEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query, clearMessages: true));
  }

  Future<void> _onCancelTicket(
    CancelTicketEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    final ticketIndex = state.tickets.indexWhere(
      (t) => t.id == event.ticketId || t.ticketCode == event.ticketId,
    );
    if (ticketIndex == -1) {
      emit(
        state.copyWith(
          errorMessage: 'Không tìm thấy thông tin vé cần hủy.',
          clearMessages: false,
        ),
      );
      return;
    }

    final ticket = state.tickets[ticketIndex];

    // Business Rule sub_uc_huy_ve: Cancellation requires departure eligibility
    if (!ticket.canCancel) {
      emit(
        state.copyWith(
          errorMessage:
              'Không thể hủy vé vì chuyến xe khởi hành trong vòng dưới 12 giờ (dưới 3 giờ theo quy định tối thiểu nhà xe)! Vui lòng liên hệ tổng đài để được trợ giúp.',
          clearMessages: false,
        ),
      );
      return;
    }

    try {
      final cancelResult = await bookingRepository.cancelTicket(
        ticketCode: ticket.ticketCode,
        phoneNumber: ticket.passenger.phone,
        reason: event.reason,
        expectedCancelFeeRate: ticket.cancelFeeRate,
      );

      final refund =
          (cancelResult['refundAmount'] as num?)?.toInt() ?? event.refundAmount;

      final updatedTicket = ticket.copyWith(
        status: TicketStatus.cancelled,
        cancelReason: event.reason,
        refundAmount: refund,
      );

      final updatedList = List<TicketModel>.from(state.tickets);
      updatedList[ticketIndex] = updatedTicket;

      emit(
        state.copyWith(
          tickets: updatedList,
          selectedTab: TicketStatus.cancelled,
          successMessage:
              'Hủy vé ${ticket.ticketCode} thành công! Số tiền hoàn lại: $refund đ.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Không thể hủy vé: $e',
          clearMessages: false,
        ),
      );
    }
  }


  Future<void> _onSubmitReview(
    SubmitTicketReviewEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    final ticketIndex = state.tickets.indexWhere(
      (t) => t.id == event.ticketId || t.ticketCode == event.ticketId,
    );
    if (ticketIndex == -1) {
      emit(state.copyWith(errorMessage: 'Không tìm thấy vé để đánh giá.'));
      return;
    }

    final ticket = state.tickets[ticketIndex];

    // Try submitting review to backend API if numeric tripId can be parsed
    final rawTripId = ticket.trip.id;
    final tripId = int.tryParse(rawTripId) ??
        int.tryParse(rawTripId.replaceAll(RegExp(r'\D'), '')) ??
        1;

    try {
      await reviewRemoteDataSource.createReview(
        tripId: tripId,
        rating: event.review.rating.round(),
        comment: event.review.comment,
      );
    } catch (_) {
      // Local fallback preserves UX even if offline
    }

    final updatedTicket = ticket.copyWith(review: event.review);

    final updatedList = List<TicketModel>.from(state.tickets);
    updatedList[ticketIndex] = updatedTicket;

    emit(
      state.copyWith(
        tickets: updatedList,
        successMessage:
            'Cảm ơn bạn đã gửi đánh giá cho chuyến đi của nhà xe ${ticket.trip.operatorName}!',
      ),
    );
  }
}
