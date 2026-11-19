import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AuthRepository {
  AuthRepository(this._c);
  final SupabaseClient _c;

  Future<void> sendOtp(String phone) => _c.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyOtp(String phone, String token) =>
      _c.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _c.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail(String email, String password) =>
      _c.auth.signUp(email: email, password: password);

  Future<void> signOut() => _c.auth.signOut();

  Future<Profile?> fetchProfile(String uid) async {
    final row = await _c.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<void> createParentProfile({required String uid, required String fullName}) async {
    final cleanName = fullName.trim().isEmpty ? 'Parent' : fullName.trim();
    final safeName = cleanName.length < 2 ? '$cleanName.' : cleanName;
    await _c.from('profiles').upsert({
      'id': uid,
      'role': 'parent',
      'full_name': safeName,
      'phone': _c.auth.currentUser?.phone,
    });
  }

  Future<void> createDoctorProfile({
    required String uid,
    required String fullName,
    required String clinicName,
    required String clinicAddress,
    required String clinicPhone,
    required String openTime,
    required String closeTime,
    required int slotMinutes,
    ClinicDepartment department = ClinicDepartment.pediatrics,
  }) async {
    final cleanName = fullName.trim().isEmpty ? 'Doctor' : fullName.trim();
    final safeName = cleanName.length < 2 ? '$cleanName.' : cleanName;
    await _c.from('profiles').upsert({
      'id': uid,
      'role': 'doctor',
      'full_name': safeName,
      'phone': _c.auth.currentUser?.phone,
    });
    final cleanClinicName = clinicName.trim().isEmpty ? 'Care Clinic' : clinicName.trim();
    await _c.from('clinics').upsert({
      'doctor_id': uid,
      'name': cleanClinicName,
      'address': clinicAddress.trim().isEmpty ? null : clinicAddress.trim(),
      'phone': clinicPhone.trim().isEmpty ? null : clinicPhone.trim(),
      'open_time': openTime,
      'close_time': closeTime,
      'slot_minutes': slotMinutes,
      'department': department.key,
    }, onConflict: 'doctor_id');
  }
}
