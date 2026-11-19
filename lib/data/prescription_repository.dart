import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';
import '../models/models.dart';

class PrescriptionRepository {
  PrescriptionRepository(this._c);
  final SupabaseClient _c;

  static const _select =
      '*, children(name, dob), clinics(name, address, phone), doctor:profiles!doctor_id(full_name)';

  Future<List<Prescription>> forChild(String childId) async {
    final rows = await _c
        .from('prescriptions')
        .select(_select)
        .eq('child_id', childId)
        .order('created_at', ascending: false);
    return rows.map(Prescription.fromJson).toList();
  }

  Future<Prescription> byId(String id) async {
    final row = await _c.from('prescriptions').select(_select).eq('id', id).single();
    return Prescription.fromJson(row);
  }

  Future<String> create({
    required String clinicId,
    required String childId,
    required String doctorId,
    String? appointmentId,
    required double weightKg,
    String? diagnosis,
    required List<RxItem> items,
    String? notes,
    DateTime? followUpDate,
  }) async {
    final row = await _c
        .from('prescriptions')
        .insert({
          'clinic_id': clinicId,
          'child_id': childId,
          'doctor_id': doctorId,
          'appointment_id': appointmentId,
          'weight_kg': weightKg,
          'diagnosis': (diagnosis ?? '').trim().isEmpty ? null : diagnosis!.trim(),
          'items': items.map((e) => e.toJson()).toList(),
          'notes': (notes ?? '').trim().isEmpty ? null : notes!.trim(),
          'follow_up_date': followUpDate == null ? null : toDbDate(followUpDate),
        })
        .select('id')
        .single();
    if (appointmentId != null) {
      await _c.from('appointments').update({'status': 'completed'}).eq('id', appointmentId);
    }
    return row['id'] as String;
  }

  Future<List<DrugFormulary>> formulary() async {
    final rows = await _c.from('drug_formulary').select().order('name');
    return rows.map(DrugFormulary.fromJson).toList();
  }
}
