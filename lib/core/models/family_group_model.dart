/// A family / group in the wealth management context.
/// Group Name is the identifier — one family can have multiple members,
/// potentially across different RMs (shared AUM scenario).
class FamilyMember {
  final String name;
  final String? clientCode;
  final String? phone;
  final String relationship; // 'Self', 'Spouse', 'Parent', 'Child', etc.
  final bool isClient; // true = existing client, false = prospect/lead
  final String? assignedRmName;

  const FamilyMember({
    required this.name,
    this.clientCode,
    this.phone,
    required this.relationship,
    this.isClient = false,
    this.assignedRmName,
  });
}

class FamilyGroupModel {
  final String id;
  final String groupName;
  final List<FamilyMember> members;
  final String? primaryRmId;
  final String? primaryRmName;
  final String? secondaryRmId;
  final String? secondaryRmName;
  final double totalAum;
  final String? city;

  const FamilyGroupModel({
    required this.id,
    required this.groupName,
    required this.members,
    this.primaryRmId,
    this.primaryRmName,
    this.secondaryRmId,
    this.secondaryRmName,
    this.totalAum = 0,
    this.city,
  });

  int get memberCount => members.length;
  int get clientCount => members.where((m) => m.isClient).length;

  String get aumDisplay {
    if (totalAum >= 10000000) {
      return '₹${(totalAum / 10000000).toStringAsFixed(1)} Cr';
    }
    if (totalAum >= 100000) {
      return '₹${(totalAum / 100000).toStringAsFixed(1)} L';
    }
    return '₹${totalAum.toStringAsFixed(0)}';
  }

  String get summaryDisplay =>
      '$groupName · ${memberCount} member${memberCount == 1 ? '' : 's'} · $aumDisplay';
}
