import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/qr_crypto_helper.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../../domain/entities/qr_session_entity.dart';
import '../../../domain/repositories/attendance_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AttendanceRepository attendanceRepository;
  final Uuid uuid;
  Timer? _countdownTimer;

  AdminBloc({
    required this.attendanceRepository,
    Uuid? uuidGenerator,
  })  : uuid = uuidGenerator ?? const Uuid(),
        super(const AdminState()) {
    on<FetchAllRecordsEvent>(_onFetchAllRecords);
    on<GenerateQRSessionEvent>(_onGenerateQRSession);
    on<TimerTickEvent>(_onTimerTick);
  }

  Future<void> _onFetchAllRecords(
    FetchAllRecordsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading));
    try {
      final records = await attendanceRepository.getAllAttendanceRecords();
      emit(state.copyWith(
        status: AdminStatus.success,
        records: records,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Failed to fetch attendance records.',
      ));
    }
  }

  void _onGenerateQRSession(
    GenerateQRSessionEvent event,
    Emitter<AdminState> emit,
  ) {
    _countdownTimer?.cancel();

    final sessionId = uuid.v4();
    final validFrom = DateTime.now();
    final validUntil = validFrom.add(
      const Duration(seconds: AppConstants.qrValiditySeconds),
    );

    // Create cryptographically signed QR payload
    final qrPayload = QrCryptoHelper.createSignedQrPayload(
      sessionId: sessionId,
      type: event.type == AttendanceType.checkIn ? 'CHECK_IN' : 'CHECK_OUT',
      validFrom: validFrom,
      validUntil: validUntil,
    );

    final session = QRSessionEntity(
      sessionId: sessionId,
      type: event.type,
      validFrom: validFrom,
      validUntil: validUntil,
      signature: QrCryptoHelper.generateSignature(sessionId),
    );

    emit(state.copyWith(
      currentSession: session,
      qrPayloadString: qrPayload,
      remainingSeconds: AppConstants.qrValiditySeconds,
      selectedType: event.type,
      status: AdminStatus.success,
    ));

    // Start 1-second countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        // Automatically regenerate a fresh QR session on expiry
        add(GenerateQRSessionEvent(state.selectedType));
      } else {
        add(TimerTickEvent(remaining));
      }
    });
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<AdminState> emit,
  ) {
    emit(state.copyWith(remainingSeconds: event.remainingSeconds));
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}