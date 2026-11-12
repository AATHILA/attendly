import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_event.dart';
import '../../blocs/attendance/attendance_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import 'attendance_history_screen.dart';
import 'qr_scanner_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final UserEntity user;

  const EmployeeHomeScreen({super.key, required this.user});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial attendance state
    context.read<AttendanceBloc>().add(
          FetchEmployeeHistoryRequested(widget.user.id),
        );
  }

  void _onLogout() {
    context.read<AuthBloc>().add(const LogoutRequested());
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _navigateToScanner(AttendanceType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          user: widget.user,
          sessionType: type,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceHistoryScreen(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final hasCheckedIn = state.hasCheckedInToday;
          final hasCheckedOut = state.hasCheckedOutToday;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : 'E',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${widget.user.id} • ${widget.user.role.name.toUpperCase()}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.user.email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Today's Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasCheckedIn ? Icons.verified : Icons.access_time_outlined,
                        color: hasCheckedIn ? Colors.green : Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Attendance Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            hasCheckedOut
                                ? 'Status: Checked Out for the day'
                                : (hasCheckedIn
                                    ? 'Status: Currently Checked In'
                                    : 'Status: Not Checked In Yet'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Scan for Check-In Action
                _buildActionCard(
                  title: 'Scan QR for Check-In',
                  subtitle: hasCheckedIn
                      ? 'You have already checked in today.'
                      : 'Scan dynamic office QR to mark arrival.',
                  icon: Icons.login_rounded,
                  color: Colors.green,
                  isEnabled: !hasCheckedIn,
                  onTap: () => _navigateToScanner(AttendanceType.checkIn),
                ),
                const SizedBox(height: 14),

                // Scan for Check-Out Action
                _buildActionCard(
                  title: 'Scan QR for Check-Out',
                  subtitle: !hasCheckedIn
                      ? 'You must check in first before checking out.'
                      : (hasCheckedOut
                          ? 'You have already checked out today.'
                          : 'Scan dynamic office QR to mark departure.'),
                  icon: Icons.logout_rounded,
                  color: Colors.orange,
                  isEnabled: hasCheckedIn && !hasCheckedOut,
                  onTap: () => _navigateToScanner(AttendanceType.checkOut),
                ),
                const SizedBox(height: 14),

                // View Attendance History Action
                _buildActionCard(
                  title: 'Attendance Records & History',
                  subtitle: 'View check-in logs, timestamps, and GPS records.',
                  icon: Icons.history_rounded,
                  color: Colors.blue,
                  isEnabled: true,
                  onTap: _navigateToHistory,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEnabled ? color.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      color: isEnabled ? color.withOpacity(0.04) : Colors.grey.shade50,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? color.withOpacity(0.12) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? color : Colors.grey.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isEnabled ? Colors.black87 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? color : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}