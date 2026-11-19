import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class ClinicRepository {
  ClinicRepository(this._c);
  final SupabaseClient _c;

  // ---- parent side -------------------------------------------------------
  Future<Clinic?> clinicOfChild(String childId) async {
    final rows =
        await _c.from('clinic_patients').select('clinics(*)').eq('child_id', childId).limit(1);
    if (rows.isEmpty) return null;
    final c = rows.first['clinics'];
    return c == null ? null : Clinic.fromJson(Map<String, dynamic>.from(c as Map));
  }

  Future<Clinic> joinClinic(String code, String childId) async {
    final res = await _c.rpc('join_clinic', params: {
      'p_code': code.trim().toUpperCase(),
      'p_child': childId,
    });
    return Clinic.fromJson(Map<String, dynamic>.from(res as Map));
  }

  // ---- doctor side -------------------------------------------------------
  Future<Clinic?> myClinic(String doctorId) async {
    final row = await _c.from('clinics').select().eq('doctor_id', doctorId).maybeSingle();
    return row == null ? null : Clinic.fromJson(row);
  }

  Future<void> updateClinic(
    String clinicId, {
    required String openTime,
    required String closeTime,
    required int slotMinutes,
    ClinicDepartment? department,
  }) async {
    final payload = <String, dynamic>{
      'open_time': openTime,
      'close_time': closeTime,
      'slot_minutes': slotMinutes,
    };
    if (department != null) {
      payload['department'] = department.key;
    }
    await _c.from('clinics').update(payload).eq('id', clinicId);
  }

  Future<void> setClinicDepartment(String clinicId, ClinicDepartment department) async {
    await _c.from('clinics').update({'department': department.key}).eq('id', clinicId);
  }

  Future<DoctorStats> stats(String clinicId) async {
    final res = await _c.rpc('doctor_stats', params: {'p_clinic': clinicId});
    return DoctorStats.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<Patient>> patients(String clinicId) async {
    final rows = await _c
        .from('clinic_patients')
        .select(
            'last_visit_at, children(id, parent_id, name, dob, gender, blood_group, allergies, profiles!parent_id(full_name, phone))')
        .eq('clinic_id', clinicId);
    final list = rows.map((r) {
      final last = r['last_visit_at'] as String?;
      return Patient(
        child: Child.fromJson(Map<String, dynamic>.from(r['children'] as Map)),
        lastVisit: last == null ? null : DateTime.parse(last).toLocal(),
      );
    }).toList();
    list.sort((a, b) => a.child.name.toLowerCase().compareTo(b.child.name.toLowerCase()));
    return list;
  }

  Future<List<MissedFollowUp>> missedFollowups(String clinicId) async {
    final rows = await _c
        .from('missed_followups')
        .select()
        .eq('clinic_id', clinicId)
        .order('follow_up_date');
    return rows.map(MissedFollowUp.fromJson).toList();
  }

  Future<List<PendingVaccine>> pendingVaccines(String clinicId) async {
    final rows = await _c
        .from('clinic_pending_vaccines')
        .select()
        .eq('clinic_id', clinicId)
        .order('due_date');
    return rows.map(PendingVaccine.fromJson).toList();
  }

  Future<List<ChatThread>> chatThreads(String clinicId) async {
    final res = await _c.rpc('doctor_chat_threads', params: {'p_clinic': clinicId});
    return (res as List)
        .map((e) => ChatThread.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
