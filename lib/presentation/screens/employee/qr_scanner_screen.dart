import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/qr_crypto_helper.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_event.dart';
import '../../blocs/attendance/attendance_state.dart';

class QRScannerScreen extends StatefulWidget {
  final UserEntity user;
  final AttendanceType sessionType;

  const QRScannerScreen({
    super.key,
    required this.user,
    required this.sessionType,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;

    if (rawValue != null && rawValue.isNotEmpty) {
      setState(() => _hasScanned = true);

      // Dispatch scan event to AttendanceBloc
      context.read<AttendanceBloc>().add(
            MarkAttendanceRequested(
              rawQrPayload: rawValue,
              employeeId: widget.user.id,
              employeeName: widget.user.name,
              type: widget.sessionType,
            ),
          );
    }
  }

  void _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (isSuccess) {
                      Navigator.of(context).pop(); // Back to home
                    } else {
                      // Allow re-scanning on error
                      setState(() => _hasScanned = false);
                    }
                  },
                  child: Text(isSuccess ? 'Done' : 'Try Again'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = widget.sessionType == AttendanceType.checkIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCheckIn ? 'Scan for Check-In' : 'Scan for Check-Out'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state.status == AttendanceStatus.success) {
            final rec = state.latestRecord;
            final loc = rec != null
                ? '\nGPS Location: (${rec.latitude.toStringAsFixed(4)}, ${rec.longitude.toStringAsFixed(4)})\nStatus: ${rec.isSynced ? "Synced to Cloud" : "Saved to Local SQLite"}'
                : '';
            _showResultDialog(
              isSuccess: true,
              title: state.successMessage ?? 'Success',
              message: 'Attendance recorded successfully at ${DateTime.now().toLocal().toString().substring(11, 16)}.$loc',
            );
          } else if (state.status == AttendanceStatus.failure) {
            _showResultDialog(
              isSuccess: false,
              title: 'Validation Failed',
              message: state.errorMessage ?? 'Could not mark attendance.',
            );
          }
        },
        child: Stack(
          children: [
            // Live Scanner View
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Visual Viewfinder Overlay
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCheckIn ? Colors.greenAccent : Colors.orangeAccent,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Bottom Instructions & Quick Test Banner
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Point camera at the dynamic QR code displayed on the Admin screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.flash_on, size: 16, color: Colors.amberAccent),
                      label: Text(
                        isCheckIn
                            ? '⚡ Test Scan Check-In (Single Device Demo)'
                            : '⚡ Test Scan Check-Out (Single Device Demo)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        final dummyPayload = QrCryptoHelper.createSignedQrPayload(
                          sessionId: const Uuid().v4(),
                          type: isCheckIn ? 'CHECK_IN' : 'CHECK_OUT',
                          validFrom: DateTime.now(),
                          validUntil: DateTime.now().add(
                            const Duration(seconds: AppConstants.qrValiditySeconds),
                          ),
                        );
                        context.read<AttendanceBloc>().add(
                              MarkAttendanceRequested(
                                rawQrPayload: dummyPayload,
                                employeeId: widget.user.id,
                                employeeName: widget.user.name,
                                type: widget.sessionType,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}