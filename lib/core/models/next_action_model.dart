import '../enums/next_action_type.dart';

class NextActionModel {
  final NextActionType type;
  final DateTime? dueAt;
  final String? notes;

  const NextActionModel({
    required this.type,
    this.dueAt,
    this.notes,
  });

  bool get isDueSoon {
    if (dueAt == null) return false;
    final delta = dueAt!.difference(DateTime.now());
    return delta.inMinutes >= -5 && delta.inMinutes <= 30;
  }

  bool get isOverdue {
    if (dueAt == null) return false;
    return dueAt!.isBefore(DateTime.now());
  }

  String get dueDisplay {
    if (dueAt == null) return type.label;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueAt!.year, dueAt!.month, dueAt!.day);
    final diffDays = dueDay.difference(today).inDays;
    final hh = dueAt!.hour;
    final mm = dueAt!.minute.toString().padLeft(2, '0');
    final period = hh >= 12 ? 'PM' : 'AM';
    final h12 = hh > 12 ? hh - 12 : (hh == 0 ? 12 : hh);
    final timePart = '$h12:$mm $period';

    if (diffDays == 0) return '${type.label} · Today $timePart';
    if (diffDays == 1) return '${type.label} · Tomorrow $timePart';
    if (diffDays == -1) return '${type.label} · Yesterday $timePart';
    if (diffDays > 1 && diffDays < 7) return '${type.label} · In ${diffDays}d';
    return '${type.label} · ${dueAt!.day}/${dueAt!.month}';
  }

  NextActionModel copyWith({
    NextActionType? type,
    DateTime? dueAt,
    String? notes,
  }) {
    return NextActionModel(
      type: type ?? this.type,
      dueAt: dueAt ?? this.dueAt,
      notes: notes ?? this.notes,
    );
  }
}
