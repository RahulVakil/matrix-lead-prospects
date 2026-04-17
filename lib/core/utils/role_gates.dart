import '../enums/user_role.dart';

/// Centralized role-gating helpers for IB & Wealth lead features.
/// Use these instead of inline `user.role == ...` checks.
class RoleGates {
  RoleGates._();

  /// Can update IB lead status (post-approval). RM, TL, IB can. Admin is read-only.
  static bool canUpdateIBStatus(UserRole role) =>
      role == UserRole.rm || role == UserRole.teamLead || role == UserRole.ib;

  /// Can view IB status history. All 4 primary roles can.
  static bool canViewIBHistory(UserRole role) =>
      role == UserRole.rm ||
      role == UserRole.teamLead ||
      role == UserRole.admin ||
      role == UserRole.ib;

  /// Can view and manage the lead pool.
  static bool canViewPool(UserRole role) => role == UserRole.admin;

  /// Can allocate leads from pool to RMs.
  static bool canAllocateLeads(UserRole role) => role == UserRole.admin;

  /// Can approve / send-back / drop IB leads.
  static bool canDecideIBLead(UserRole role) => role == UserRole.admin;

  /// Read-only viewer for IB status (Admin/MIS).
  static bool isReadOnlyForStatus(UserRole role) => role == UserRole.admin;

  /// Can create wealth leads or IB leads.
  static bool canCreateLead(UserRole role) =>
      role == UserRole.rm || role == UserRole.teamLead;

  /// IB role — used to hide IB Approval module.
  static bool isIBUser(UserRole role) => role == UserRole.ib;
}
