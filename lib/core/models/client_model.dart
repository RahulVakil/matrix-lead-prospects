/// Minimal client entity used by the Phase 1 Clients module stub.
/// Full client master will be modelled in a later phase.
class ClientModel {
  final String id;
  final String clientCode;
  final String fullName;
  final String? groupName;
  final String? phone;
  final String? email;
  final String? city;
  final double aum;
  final List<String> products;
  final String assignedRmId;
  final String assignedRmName;
  final bool isDirect; // direct relationship vs. via reportee
  final bool hasIbLead; // whether this client has an IB lead conversion
  final DateTime onboardedAt;

  const ClientModel({
    required this.id,
    required this.clientCode,
    required this.fullName,
    this.groupName,
    this.phone,
    this.email,
    this.city,
    required this.aum,
    this.products = const [],
    required this.assignedRmId,
    required this.assignedRmName,
    this.hasIbLead = false,
    this.isDirect = true,
    required this.onboardedAt,
  });

  String get aumDisplay {
    if (aum >= 10000000) {
      return '₹${(aum / 10000000).toStringAsFixed(2)} Cr';
    }
    if (aum >= 100000) {
      return '₹${(aum / 100000).toStringAsFixed(1)} L';
    }
    return '₹${aum.toStringAsFixed(0)}';
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }
}
