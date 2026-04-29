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
  /// Optional zone (parent of region) — used for the Zonal Head's dashboard
  /// scope and for filtering leads up the hierarchy.
  final String? zoneName;
  final String? designation;
  final String? email;
  final String? phone;
  /// Wealth vertical for RMs (and downstream leads they create). 'EWG' or
  /// 'PWG'; null for non-RM roles. Drives the per-vertical de-dupe rules
  /// in CoverageRepository.checkCoverage().
  final String? vertical;

  UserModel({
    required this.id,
    required this.name,
    required this.empCode,
    required this.role,
    this.branchName,
    this.teamId,
    this.teamName,
    this.regionName,
    this.zoneName,
    this.designation,
    this.email,
    this.phone,
    this.vertical,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
