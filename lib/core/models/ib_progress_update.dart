import '../enums/ib_deal_type.dart';

/// One 30-day status update authored by the assigned Wealth RM after the
/// IB lead has been approved + assigned to an IB RM.
class IbProgressUpdate {
  final String id;
  final IbProgressStatus status;
  final String notes; // mandatory >= 10 chars
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  const IbProgressUpdate({
    required this.id,
    required this.status,
    required this.notes,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });
}

/// Lightweight financial-document attachment for an IB lead's
/// "Company Financial" section.
class IbFinancialDoc {
  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final DateTime uploadedAt;

  const IbFinancialDoc({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
