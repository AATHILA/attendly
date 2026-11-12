import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/entities/user_entity.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/blocs/admin/admin_bloc.dart';
import 'presentation/blocs/attendance/attendance_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/employee/employee_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        RepositoryProvider<AttendanceRepository>(
          create: (_) => AttendanceRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const CheckAuthStatus()),
          ),
          BlocProvider<AdminBloc>(
            create: (context) => AdminBloc(
              attendanceRepository: context.read<AttendanceRepository>(),
            ),
          ),
          BlocProvider<AttendanceBloc>(
            create: (context) => AttendanceBloc(
              attendanceRepository: context.read<AttendanceRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Professional Indigo
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.black87),
            ),
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                if (state.user.role == UserRole.admin) {
                  return const AdminDashboardScreen();
                } else {
                  return EmployeeHomeScreen(user: state.user);
                }
              }
              return const LoginScreen();
            },
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/admin':
                return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
              case '/employee':
                return MaterialPageRoute(
                  builder: (context) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      return EmployeeHomeScreen(user: authState.user);
                    }
                    return const LoginScreen();
                  },
                );
              default:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
          },
        ),
      ),
    );
  }
}