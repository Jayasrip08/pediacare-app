import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';
import '../models/models.dart';

class AppointmentRepository {
  AppointmentRepository(this._c);
  final SupabaseClient _c;

  static const _select = '*, children(name, dob), clinics(name)';

  Future<List<Appointment>> forChild(String childId) async {
    final rows = await _c
        .from('appointments')
        .select(_select)
        .eq('child_id', childId)
        .order('scheduled_at', ascending: false);
    return rows.map(Appointment.fromJson).toList();
  }

  Future<List<DateTime>> takenSlots(String clinicId, DateTime day) async {
    final res = await _c.rpc('taken_slots', params: {
      'p_clinic': clinicId,
      'p_day': toDbDate(day),
    });
    return (res as List).map((e) => DateTime.parse(e as String).toLocal()).toList();
  }

  Future<void> book({
    required String clinicId,
    required String childId,
    required String parentId,
    required DateTime scheduledAt,
    String? reason,
    String? symptoms,
  }) async {
    await _c.from('appointments').insert({
      'clinic_id': clinicId,
      'child_id': childId,
      'parent_id': parentId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'reason': reason,
      'symptoms': (symptoms ?? '').trim().isEmpty ? null : symptoms!.trim(),
    });
  }

  Future<void> setStatus(String id, String status) async {
    await _c.from('appointments').update({'status': status}).eq('id', id);
  }

  Future<QueueStatus?> queueStatus(String appointmentId) async {
    final res = await _c.rpc('queue_status', params: {'p_appointment': appointmentId});
    if (res == null) return null;
    return QueueStatus.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Doctor: all of today's appointments in time order.
  Future<List<Appointment>> todaysQueue(String clinicId) async {
    final start = dateOnly(DateTime.now());
    final end = start.add(const Duration(days: 1));
    final rows = await _c
        .from('appointments')
        .select(_select)
        .eq('clinic_id', clinicId)
        .gte('scheduled_at', start.toUtc().toIso8601String())
        .lt('scheduled_at', end.toUtc().toIso8601String())
        .neq('status', 'cancelled')
        .order('scheduled_at');
    return rows.map(Appointment.fromJson).toList();
  }

  /// Doctor: all appointments for a given child at this clinic.
  Future<List<Appointment>> forChildAtClinic(String clinicId, String childId) async {
    final rows = await _c
        .from('appointments')
        .select(_select)
        .eq('clinic_id', clinicId)
        .eq('child_id', childId)
        .order('scheduled_at', ascending: false);
    return rows.map(Appointment.fromJson).toList();
  }
}
