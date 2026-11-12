import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_event.dart';
import '../../blocs/attendance/attendance_state.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final UserEntity user;

  const AttendanceHistoryScreen({super.key, required this.user});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(
          FetchEmployeeHistoryRequested(widget.user.id),
        );
  }

  void _onSyncPressed() {
    context.read<AttendanceBloc>().add(
          SyncPendingRecordsRequested(widget.user.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Offline Records',
            onPressed: _onSyncPressed,
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state.successMessage != null && state.successMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.teal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final history = state.history;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_outlined,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No attendance records found yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan an active QR code to mark your first check-in.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final unsyncedCount = history.where((r) => !r.isSynced).length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AttendanceBloc>().add(
                    FetchEmployeeHistoryRequested(widget.user.id),
                  );
            },
            child: Column(
              children: [
                if (unsyncedCount > 0)
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, size: 18, color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$unsyncedCount offline record(s) pending sync.',
                            style: const TextStyle(fontSize: 12, color: Colors.brown),
                          ),
                        ),
                        TextButton(
                          onPressed: _onSyncPressed,
                          child: const Text('SYNC NOW', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = history[index];
                      final isCheckIn = record.type == AttendanceType.checkIn;
                      final dateFormatted = DateFormat('EEEE, MMM dd, yyyy')
                          .format(record.timestamp);
                      final timeFormatted = DateFormat('hh:mm a')
                          .format(record.timestamp);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isCheckIn
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      isCheckIn ? Icons.login : Icons.logout,
                                      size: 18,
                                      color: isCheckIn
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.type.toDisplayString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        dateFormatted,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    timeFormatted,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'GPS: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      record.isSynced ? 'Synced' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: record.isSynced
                                            ? Colors.teal
                                            : Colors.deepOrange,
                                      ),
                                    ),
                                    backgroundColor: record.isSynced
                                        ? Colors.teal.shade50
                                        : Colors.deepOrange.shade50,
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}