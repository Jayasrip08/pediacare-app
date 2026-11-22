import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/department_models.dart';
import '../../models/models.dart';
import '../../providers.dart';

class DoctorRegisterScreen extends ConsumerStatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  ConsumerState<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends ConsumerState<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Clinic Affiliation Controllers
  final _clinicCodeCtrl = TextEditingController();
  bool _isNewClinic = false;
  final _newClinicNameCtrl = TextEditingController();
  final _newClinicAddressCtrl = TextEditingController();

  Clinic? _verifiedClinic;
  String? _clinicVerificationError;
  bool _isVerifyingCode = false;

  // Doctor Professional Information Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  String _selectedSpecialty = 'General Pediatrics & Adolescent Care';

  bool _obscurePin = true;
  bool _submitting = false;

  final List<String> _specialties = const [
    'General Pediatrics & Adolescent Care',
    'Pediatric Pulmonology & Allergy',
    'Pediatric Cardiology & Neonatal Care',
    'Pediatric Neurology & Child Development',
    'Pediatric Dermatology & Skin Regimens',
    'Pediatric Nutrition & Metabolic Care',
    'Neonatology & Premature Infant Care',
    'Pediatric Ophthalmology & Vision Care',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-verify prefilled demo code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyClinicCode();
    });
  }

  @override
  void dispose() {
    _clinicCodeCtrl.dispose();
    _newClinicNameCtrl.dispose();
    _newClinicAddressCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _phoneCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  void _verifyClinicCode() {
    final code = _clinicCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _verifiedClinic = null;
        _clinicVerificationError = 'Please enter a clinic join code';
      });
      return;
    }

    setState(() {
      _isVerifyingCode = true;
      _clinicVerificationError = null;
    });

    final clinicsNotifier = ref.read(localClinicsProvider.notifier);
    final clinic = clinicsNotifier.findClinicByCode(code);

    setState(() {
      _isVerifyingCode = false;
      if (clinic != null) {
        _verifiedClinic = clinic;
        _clinicVerificationError = null;
      } else {
        _verifiedClinic = null;
        _clinicVerificationError = 'No clinic found matching code "$code". Check with your clinic administrator or register a new clinic.';
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isNewClinic && _verifiedClinic == null) {
      showToast(context, 'Please verify a valid Clinic Join Code before proceeding', error: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final newDoctorId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      var formattedName = _nameCtrl.text.trim();
      if (!formattedName.toLowerCase().startsWith('dr.')) {
        formattedName = 'Dr. $formattedName';
      }

      String targetClinicId;
      if (_isNewClinic) {
        final generatedCode = 'CARE${(math.Random().nextInt(8999) + 1000)}';
        targetClinicId = 'clinic_${newDoctorId}';
        final newClinic = Clinic(
          id: targetClinicId,
          doctorId: newDoctorId,
          name: _newClinicNameCtrl.text.trim(),
          address: _newClinicAddressCtrl.text.trim().isEmpty ? 'Medical Center' : _newClinicAddressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          joinCode: generatedCode,
          openTime: '09:00',
          closeTime: '18:00',
          slotMinutes: 15,
          department: ClinicDepartment.pediatrics,
          availableDepartments: const [ClinicDepartment.pediatrics],
        );
        ref.read(localClinicsProvider.notifier).setClinic(newDoctorId, newClinic);
      } else {
        targetClinicId = _verifiedClinic!.id;
        // Associate this doctor with the verified clinic
        ref.read(localClinicsProvider.notifier).registerDoctorToClinic(newDoctorId, _verifiedClinic!);
      }

      final newDoctor = DoctorAccount(
        id: newDoctorId,
        name: formattedName,
        email: _emailCtrl.text.trim(),
        pin: _pinCtrl.text.trim(),
        specialty: _selectedSpecialty,
        regNo: _regNoCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? '+91 98400 00000' : _phoneCtrl.text.trim(),
        avatarPath: 'assets/images/avatar_doctor.png',
        clinicId: targetClinicId,
      );

      // 1. Add doctor to roster
      ref.read(doctorAccountsProvider.notifier).addDoctor(newDoctor);

      // 2. Set active doctor & activate RBAC
      ref.read(activeDoctorIdProvider.notifier).state = newDoctorId;
      ref.read(currentUserRoleProvider.notifier).state = UserRole.doctor;

      // 3. Invalidate clinic provider to refresh workspace
      ref.invalidate(myClinicProvider);

      if (mounted) {
        showToast(context, 'Welcome, $formattedName! Doctor workspace activated with RBAC.');
        context.go('/doctor/dashboard');
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Registration error: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login?role=doctor'),
        ),
        centerTitle: true,
        title: const BrandMark(size: 34, showName: true, light: false),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFF3E8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: Color(0xFF7C3AED), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doctor Registration',
                              style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF5B21B6)),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Register with your clinical credentials and link to your clinic practice.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B21A8), height: 1.25),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // SECTION 1: CLINIC AFFILIATION & JOIN CODE
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '1. Clinic Practice Affiliation',
                      style: AppText.h3.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter the 6-character Clinic Join Code provided by the hospital or clinic administrator where you will practice.',
                  style: AppText.muted.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),

                if (!_isNewClinic) ...[
                  // Clinic Code Input with Verify Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clinicCodeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Clinic Join Code *',
                            hintText: 'e.g. MEERA24, KARTHIK08',
                            prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                          ),
                          onChanged: (_) => _verifyClinicCode(),
                          validator: (v) {
                            if (_isNewClinic) return null;
                            if (v == null || v.trim().isEmpty) return 'Enter clinic code';
                            if (_verifiedClinic == null) return 'Verify a valid clinic code';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lavender,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _verifyClinicCode,
                          child: _isVerifyingCode
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Verify', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Verification Status Card
                  if (_verifiedClinic != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mint.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _verifiedClinic!.name,
                                  style: AppText.bodyBold.copyWith(fontSize: 13.5, color: const Color(0xFF065F46)),
                                ),
                                if (_verifiedClinic!.address != null)
                                  Text(
                                    _verifiedClinic!.address!,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.mint)),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_clinicVerificationError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _clinicVerificationError!,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // New Clinic Registration Fields
                  TextFormField(
                    controller: _newClinicNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New Clinic / Hospital Practice Name *',
                      hintText: 'e.g. Star Pediatric Care Clinic',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    validator: (v) => _isNewClinic && (v == null || v.trim().isEmpty) ? 'Enter clinic name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newClinicAddressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Clinic Physical Address *',
                      hintText: 'e.g. 142 Anna Salai, Chennai',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => _isNewClinic && (v == null || v.trim().isEmpty) ? 'Enter address' : null,
                  ),
                ],

                const SizedBox(height: 8),
                // Toggle between joining existing clinic vs creating new practice
                Row(
                  children: [
                    Checkbox(
                      value: _isNewClinic,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isNewClinic = val ?? false;
                          if (!_isNewClinic) _verifyClinicCode();
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'I am registering an independent new clinic practice (No code needed)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SECTION 2: DOCTOR IDENTIFICATION & LOGIN CREDENTIALS
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.badge_rounded, color: Color(0xFF7C3AED), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2. Doctor Login Credentials',
                      style: AppText.h3.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Doctor Full Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Full Name *',
                    hintText: 'e.g. Dr. Rajesh Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter doctor name' : null,
                ),
                const SizedBox(height: 12),

                // Work Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Work Email *',
                    hintText: 'e.g. dr.rajesh@pediacare.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 6-Digit PIN
                TextFormField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: _obscurePin,
                  decoration: InputDecoration(
                    labelText: '6-Digit Security Login PIN *',
                    hintText: 'e.g. 581920',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter PIN';
                    if (v.trim().length != 6) return 'PIN must be exactly 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Contact Phone
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Personal / Duty Phone',
                    hintText: 'e.g. +91 98401 23456',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 3: CLINICAL SPECIALTY & REGISTRATION
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.mint, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '3. Clinical Specialty & License',
                      style: AppText.h3.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Medical Council Registration Number
                TextFormField(
                  controller: _regNoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medical Council Reg. Number *',
                    hintText: 'e.g. MCI-TN-48201',
                    prefixIcon: Icon(Icons.card_membership_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Medical Council Reg. No.' : null,
                ),
                const SizedBox(height: 12),

                // Clinical Specialty Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Specialty *',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  items: _specialties.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedSpecialty = v ?? _selectedSpecialty),
                ),
                const SizedBox(height: 28),

                // Submit Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _submitting ? null : _handleRegister,
                    icon: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.how_to_reg_rounded),
                    label: Text(
                      _submitting ? 'Registering Doctor...' : 'Complete Doctor Registration',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Login Link
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login?role=doctor'),
                    child: const Text(
                      'Already registered? Sign In to Doctor Portal',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
