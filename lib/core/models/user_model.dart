import '../enums/user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String empCode;
  final UserRole role;
  final String? branchName;
  final String? teamId;
  final String? teamName;
  final String? regionName;
  final String? designation;
  final String? email;
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.empCode,
    required this.role,
    this.branchName,
    this.teamId,
    this.teamName,
    this.regionName,
    this.designation,
    this.email,
    this.phone,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
