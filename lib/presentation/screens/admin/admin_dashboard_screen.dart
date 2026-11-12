import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../blocs/admin/admin_bloc.dart';
import '../../blocs/admin/admin_event.dart';
import '../../blocs/admin/admin_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Generate initial Check-In QR session and fetch existing records
    context.read<AdminBloc>().add(
          const GenerateQRSessionEvent(AttendanceType.checkIn),
        );
    context.read<AdminBloc>().add(const FetchAllRecordsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onLogout() {
    context.read<AuthBloc>().add(const LogoutRequested());
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'Dynamic QR'),
            Tab(icon: Icon(Icons.table_chart_outlined), text: 'Attendance Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDynamicQRTab(theme),
          _buildAttendanceRecordsTab(theme),
        ],
      ),
    );
  }

  Widget _buildDynamicQRTab(ThemeData theme) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final progress = state.remainingSeconds / AppConstants.qrValiditySeconds;
        final isCheckIn = state.selectedType == AttendanceType.checkIn;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Session Type Segmented Buttons
              SegmentedButton<AttendanceType>(
                segments: const [
                  ButtonSegment(
                    value: AttendanceType.checkIn,
                    label: Text('Check-In Session'),
                    icon: Icon(Icons.login),
                  ),
                  ButtonSegment(
                    value: AttendanceType.checkOut,
                    label: Text('Check-Out Session'),
                    icon: Icon(Icons.logout),
                  ),
                ],
                selected: {state.selectedType},
                onSelectionChanged: (newSelection) {
                  context.read<AdminBloc>().add(
                        GenerateQRSessionEvent(newSelection.first),
                      );
                },
              ),
              const SizedBox(height: 24),

              // QR Code Box with Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: state.qrPayloadString != null
                    ? QrImageView(
                        data: state.qrPayloadString!,
                        version: QrVersions.auto,
                        size: 240.0,
                        backgroundColor: Colors.white,
                      )
                    : const SizedBox(
                        height: 240,
                        width: 240,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
              const SizedBox(height: 20),

              // Live Countdown Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    state.remainingSeconds > 10 ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Regenerating in: ${state.remainingSeconds}s',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Security Info Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isCheckIn ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCheckIn ? Colors.blue.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: isCheckIn ? Colors.blue.shade800 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'HMAC-SHA256 Signed & Time-Limited',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCheckIn ? Colors.blue.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Manual Regenerate Button
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Force Regenerate QR'),
                onPressed: () {
                  context.read<AdminBloc>().add(
                        GenerateQRSessionEvent(state.selectedType),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRecordsTab(ThemeData theme) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.status == AdminStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = state.records;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AdminBloc>().add(const FetchAllRecordsEvent());
          },
          child: Column(
            children: [
              // Summary Metrics Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildMetricCard(
                      'Total Logs',
                      records.length.toString(),
                      Icons.assignment_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Check-Ins',
                      records.where((r) => r.type == AttendanceType.checkIn).length.toString(),
                      Icons.login,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Check-Outs',
                      records.where((r) => r.type == AttendanceType.checkOut).length.toString(),
                      Icons.logout,
                      Colors.orange,
                    ),
                  ],
                ),
              ),

              // List of Records
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance records recorded yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final isCheckIn = item.type == AttendanceType.checkIn;
                          final dateStr = DateFormat('MMM dd, yyyy – hh:mm a')
                              .format(item.timestamp);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCheckIn
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                child: Icon(
                                  isCheckIn ? Icons.login : Icons.logout,
                                  color: isCheckIn ? Colors.green : Colors.orange,
                                ),
                              ),
                              title: Text(
                                item.employeeName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.employeeId} • $dateStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Text(
                                        'GPS: ${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  item.isSynced ? 'Synced' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: item.isSynced ? Colors.teal : Colors.deepOrange,
                                  ),
                                ),
                                backgroundColor: item.isSynced
                                    ? Colors.teal.shade50
                                    : Colors.deepOrange.shade50,
                                side: BorderSide.none,
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
    );
  }

  Widget _buildMetricCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

