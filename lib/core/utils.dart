import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String toDbDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

int ageInMonths(DateTime dob, [DateTime? now]) {
  final n = now ?? DateTime.now();
  var m = (n.year - dob.year) * 12 + (n.month - dob.month);
  if (n.day < dob.day) m--;
  return m < 0 ? 0 : m;
}

/// "2y 4m", "10m", "3w", "5d"
String ageLabel(DateTime dob, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final months = ageInMonths(dob, n);
  if (months >= 12) {
    final y = months ~/ 12;
    final m = months % 12;
    return m == 0 ? '${y}y' : '${y}y ${m}m';
  }
  if (months >= 1) return '${months}m';
  final days = dateOnly(n).difference(dateOnly(dob)).inDays;
  if (days >= 7) return '${days ~/ 7}w';
  return '${days < 0 ? 0 : days}d';
}

final _dmy = DateFormat('d MMM yyyy');
final _dm = DateFormat('d MMM');
final _time = DateFormat('h:mm a');
final _dayDate = DateFormat('EEE, d MMM');

String fmtDate(DateTime d) => _dmy.format(d);
String fmtShortDate(DateTime d) => _dm.format(d);
String fmtTime(DateTime d) => _time.format(d);
String fmtDayDate(DateTime d) => _dayDate.format(d);
String fmtDateTime(DateTime d) => '${_dm.format(d)}, ${_time.format(d)}';

String relativeDays(DateTime date) {
  final diff = dateOnly(date).difference(dateOnly(DateTime.now())).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1) return 'in $diff days';
  return '${-diff} days ago';
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// 12.0 -> "12", 12.54 -> "12.5"
String numFmt(num v) {
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

/// Human readable message for any error.
String errorMessage(Object e) {
  if (e is PostgrestException) return e.message;
  if (e is AuthException) return e.message;
  if (e is StorageException) return e.message;
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}
