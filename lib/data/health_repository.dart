import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/utils.dart';
import '../models/models.dart';

/// Children, vaccines, growth and the records vault.
class HealthRepository {
  HealthRepository(this._c);
  final SupabaseClient _c;

  // ---- children ----------------------------------------------------------
  Future<List<Child>> myChildren(String parentId) async {
    final rows =
        await _c.from('children').select().eq('parent_id', parentId).order('created_at');
    return rows.map(Child.fromJson).toList();
  }

  Future<Child> addChild({
    required String parentId,
    required String name,
    required DateTime dob,
    required String gender,
    String? bloodGroup,
    String? allergies,
    double? weightKg,
    double? heightCm,
    double? birthWeightKg,
    String? chronicConditions,
    String? emergencyContact,
    String? pediatrician,
  }) async {
    final payload = <String, dynamic>{
      'parent_id': parentId,
      'name': name.trim(),
      'dob': toDbDate(dob),
      'gender': gender,
      'blood_group': bloodGroup,
      'allergies': (allergies ?? '').trim().isEmpty ? null : allergies!.trim(),
      'consent_given_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (weightKg != null) payload['weight_kg'] = weightKg;
    if (heightCm != null) payload['height_cm'] = heightCm;
    if (birthWeightKg != null) payload['birth_weight_kg'] = birthWeightKg;
    if (chronicConditions != null) payload['chronic_conditions'] = chronicConditions;
    if (emergencyContact != null) payload['emergency_contact'] = emergencyContact;
    if (pediatrician != null) payload['pediatrician'] = pediatrician;

    final row = await _c
        .from('children')
        .insert(payload)
        .select()
        .single();
    return Child.fromJson(row);
  }

  Future<Child> childById(String childId) async {
    final row = await _c
        .from('children')
        .select('*, profiles!parent_id(full_name, phone)')
        .eq('id', childId)
        .single();
    return Child.fromJson(row);
  }

  // ---- vaccines ----------------------------------------------------------
  Future<List<ChildVaccine>> vaccines(String childId) async {
    final rows = await _c
        .from('child_vaccines')
        .select('*, vaccine_templates(name, protects_against, age_label)')
        .eq('child_id', childId)
        .order('due_date')
        .order('template_id');
    return rows.map(ChildVaccine.fromJson).toList();
  }

  Future<void> setVaccineDone(String id, {required bool done, DateTime? givenOn}) async {
    await _c.from('child_vaccines').update({
      'status': done ? 'done' : 'pending',
      'given_on': done ? toDbDate(givenOn ?? DateTime.now()) : null,
    }).eq('id', id);
  }

  /// Marks several vaccines as given on their due date (catch-up for older children).
  Future<void> markManyDone(List<ChildVaccine> items) async {
    for (final v in items) {
      await setVaccineDone(v.id, done: true, givenOn: v.dueDate);
    }
  }

  // ---- growth ------------------------------------------------------------
  Future<List<GrowthRecord>> growth(String childId) async {
    final rows =
        await _c.from('growth_records').select().eq('child_id', childId).order('measured_on');
    return rows.map(GrowthRecord.fromJson).toList();
  }

  Future<void> addGrowth({
    required String childId,
    required DateTime measuredOn,
    double? weightKg,
    double? heightCm,
    double? headCm,
  }) async {
    await _c.from('growth_records').insert({
      'child_id': childId,
      'measured_on': toDbDate(measuredOn),
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'head_cm': headCm,
    });
  }

  Future<void> deleteGrowth(String id) => _c.from('growth_records').delete().eq('id', id);

  // ---- records vault -----------------------------------------------------
  Future<List<MedicalRecord>> records(String childId) async {
    final rows = await _c
        .from('medical_records')
        .select()
        .eq('child_id', childId)
        .order('created_at', ascending: false);
    return rows.map(MedicalRecord.fromJson).toList();
  }

  Future<void> uploadRecord({
    required String childId,
    required String title,
    required String category,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$childId/records/${DateTime.now().millisecondsSinceEpoch}_${safeName(fileName)}';
    await _c.storage
        .from(AppConfig.storageBucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeOf(fileName)));
    await _c.from('medical_records').insert({
      'child_id': childId,
      'title': title.trim(),
      'category': category,
      'file_path': path,
    });
  }

  Future<void> deleteRecord(MedicalRecord r) async {
    await _c.from('medical_records').delete().eq('id', r.id);
    await _c.storage.from(AppConfig.storageBucket).remove([r.filePath]);
  }

  Future<String> signedUrl(String path) =>
      _c.storage.from(AppConfig.storageBucket).createSignedUrl(path, 3600);
}

String safeName(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

String mimeOf(String fileName) {
  final ext = fileName.toLowerCase().split('.').last;
  return switch (ext) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}

bool isImagePath(String path) {
  final ext = path.toLowerCase().split('.').last;
  return ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp';
}
