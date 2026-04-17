import 'ib_progress_update.dart';

/// One entry in the IB lead sent-back / resubmit conversation thread.
/// Admin sends remarks (role=admin); RM replies with a response + optional
/// document attachments (role=rm).
class IbRemarkEntry {
  final String id;
  final String authorId;
  final String authorName;
  final IbRemarkRole role;
  final String text;
  final List<IbFinancialDoc> docs;
  final DateTime createdAt;

  const IbRemarkEntry({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.role,
    required this.text,
    this.docs = const [],
    required this.createdAt,
  });
}

enum IbRemarkRole { admin, rm }
