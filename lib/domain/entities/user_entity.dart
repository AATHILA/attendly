import 'package:equatable/equatable.dart';

enum UserRole {
  employee,
  admin;

  static UserRole fromString(String role) {
    return role.toLowerCase() == 'admin' ? UserRole.admin : UserRole.employee;
  }
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? token;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [id, name, email, role, token];
}