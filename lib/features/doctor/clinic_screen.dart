import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/department_models.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'doctor_bottom_nav.dart';

class ClinicScreen extends ConsumerWidget {
  const ClinicScreen({super.key});

  void _editHours(BuildContext context, WidgetRef ref, Clinic clinic) {
    showAppSheet<void>(context, builder: (_) => _EditHoursForm(clinic: clinic));
  }

  void _manageDepartments(BuildContext context, WidgetRef ref, Clinic clinic) {
    showAppSheet<void>(
      context,
      builder: (_) => _ManageDepartmentsSheet(clinic: clinic),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClinicProvider);
    final currentDoc = ref.watch(currentDoctorAccountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Clinic Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AsyncValueView<Clinic?>(
        value: async,
        onRetry: () => ref.invalidate(myClinicProvider),
        data: (clinic) {
          if (clinic == null) {
            return _RegisterClinicView(doctor: currentDoc);
          }

          final availableDepts = clinic.availableDepartments.isNotEmpty
              ? clinic.availableDepartments
              : [clinic.department];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // 1. Clinic Primary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3478ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clinic.name,
                                style: AppText.h1.copyWith(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (clinic.address != null) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        clinic.address!,
                                        style: AppText.muted.copyWith(color: Colors.white70, fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (clinic.phone != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      clinic.phone!,
                                      style: AppText.muted.copyWith(color: Colors.white70, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Active Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${clinic.openTime} – ${clinic.closeTime} • ${clinic.slotMinutes}m per patient',
                            style: AppText.body.copyWith(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _editHours(context, ref, clinic),
                          child: const Text('Edit Hours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Departments Available at this Clinic Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Departments Available (${availableDepts.length})',
                      style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15.5),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _manageDepartments(context, ref, clinic),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Add / Manage', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // List of available departments
              ...availableDepts.map((dept) {
                final isPrimary = clinic.department == dept;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPrimary ? dept.color.withValues(alpha: 0.6) : AppColors.line,
                      width: isPrimary ? 1.6 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dept.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(dept.icon, color: dept.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dept.displayName,
                                  style: AppText.bodyBold.copyWith(fontSize: 14.5, color: AppColors.ink),
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: dept.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'PRIMARY',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: dept.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dept.description,
                              style: AppText.muted.copyWith(fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 3. Patient Onboarding QR & Join Code Section
              Text(
                'Patient Reception QR & Clinic Pass',
                style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15.5),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: QrImageView(
                        data: '${AppConfig.clinicQrPrefix}${clinic.joinCode}',
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('CLINIC JOIN CODE', style: AppText.label.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          clinic.joinCode,
                          style: AppText.display.copyWith(
                            letterSpacing: 4,
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: clinic.joinCode));
                            if (context.mounted) showToast(context, 'Clinic code copied to clipboard');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parents scan this QR in the PediaCare app to link their child profile to your clinic.',
                      style: AppText.small.copyWith(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Assigned Pediatrician Profile Card
              Text(
                'Licensed Medical Practitioner',
                style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15.5),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        currentDoc.avatarPath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(currentDoc.name, style: AppText.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.mint.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'RBAC VERIFIED',
                                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.mint),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(currentDoc.specialty, style: AppText.small.copyWith(color: AppColors.muted)),
                          Text('Reg No: ${currentDoc.regNo}', style: AppText.small.copyWith(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 5. Sign Out Button
              AppButton(
                label: 'Sign Out of Doctor Session',
                icon: Icons.logout_rounded,
                kind: AppButtonKind.outline,
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Sign out of Doctor Portal?',
                    message: 'Your active clinical queue and records are securely preserved.',
                    confirmLabel: 'Sign Out',
                  );
                  if (ok && context.mounted) {
                    ref.read(currentUserRoleProvider.notifier).state = null;
                    context.go('/choose-role');
                  }
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }
}

// ============================================================================
// REGISTER CLINIC VIEW (When no clinic is found)
// ============================================================================
class _RegisterClinicView extends ConsumerStatefulWidget {
  const _RegisterClinicView({required this.doctor});

  final DoctorAccount doctor;

  @override
  ConsumerState<_RegisterClinicView> createState() => _RegisterClinicViewState();
}

class _RegisterClinicViewState extends ConsumerState<_RegisterClinicView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;

  TimeOfDay _open = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 18, minute: 0);
  int _slotMinutes = 15;
  ClinicDepartment _primaryDept = ClinicDepartment.pediatrics;
  final Set<ClinicDepartment> _selectedDepts = {ClinicDepartment.pediatrics};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.doctor.name.isNotEmpty ? '${widget.doctor.name} Clinic' : '',
    );
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: widget.doctor.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateClinic() async {
    if (!_formKey.currentState!.validate()) return;
    if (_close.hour * 60 + _close.minute <= _open.hour * 60 + _open.minute) {
      showToast(context, 'Closing time must be after opening time', error: true);
      return;
    }

    setState(() => _saving = true);
    final randomCode = 'CARE${(math.Random().nextInt(8999) + 1000)}';
    final clinicId = 'clinic_${widget.doctor.id}_${DateTime.now().millisecondsSinceEpoch}';

    final newClinic = Clinic(
      id: clinicId,
      doctorId: widget.doctor.id,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      joinCode: randomCode,
      openTime: formatHm(_open),
      closeTime: formatHm(_close),
      slotMinutes: _slotMinutes,
      department: _primaryDept,
      availableDepartments: _selectedDepts.toList(),
    );

    // Save locally into doctor clinics
    ref.read(localClinicsProvider.notifier).setClinic(widget.doctor.id, newClinic);

    // Update doctor account with clinic id
    final updatedDoc = widget.doctor.copyWith(clinicId: clinicId);
    ref.read(doctorAccountsProvider.notifier).updateDoctor(updatedDoc);

    // Sync to remote Supabase if connected
    try {
      final uid = ref.read(userIdProvider);
      if (uid != null) {
        await ref.read(authRepositoryProvider).createDoctorProfile(
              uid: uid,
              fullName: widget.doctor.name,
              clinicName: newClinic.name,
              clinicAddress: newClinic.address ?? '',
              clinicPhone: newClinic.phone ?? '',
              openTime: newClinic.openTime,
              closeTime: newClinic.closeTime,
              slotMinutes: newClinic.slotMinutes,
              department: newClinic.department,
            );
      }
    } catch (_) {}

    ref.invalidate(myClinicProvider);
    if (mounted) {
      setState(() => _saving = false);
      showToast(context, 'Clinic practice created successfully! Join Code: $randomCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner for Clinic Registration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lavender, AppColors.mintSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register Your Clinic',
                          style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'No clinic practice found for ${widget.doctor.name}. Set up your clinic and departments to start accepting patients.',
                          style: AppText.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Clinic Name Field
            Text('Clinic Practice Details', style: AppText.h3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Clinic / Hospital Name *',
                hintText: 'e.g., St. Jude Children Care Clinic',
                prefixIcon: Icon(Icons.business_rounded, color: AppColors.primary),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter clinic name' : null,
            ),
            const SizedBox(height: 12),

            // Address Field
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Clinic Physical Address *',
                hintText: 'e.g., Suite 101, Medical Enclave, Chennai',
                prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.primary),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter clinic address' : null,
            ),
            const SizedBox(height: 12),

            // Phone Field
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Clinic Reception Phone',
                hintText: 'e.g., +91 98401 23456',
                prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // Working Hours & Consultation Duration
            Text('Consulting Hours & Slots', style: AppText.h3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TimeTile(
                    label: 'Opens At',
                    value: _open,
                    onChanged: (t) => setState(() => _open = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TimeTile(
                    label: 'Closes At',
                    value: _close,
                    onChanged: (t) => setState(() => _close = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Consultation Slot Duration', style: AppText.bodyBold.copyWith(fontSize: 13)),
            const SizedBox(height: 8),
            ChoiceGroup<int>(
              options: const [10, 15, 20, 30, 45],
              selected: _slotMinutes,
              onChanged: (v) => setState(() => _slotMinutes = v),
              labelOf: (v) => '$v mins',
            ),
            const SizedBox(height: 22),

            // Departments Available Selection
            Text('Departments & Specialties Available', style: AppText.h3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Select all pediatric clinical services offered by your clinic:',
              style: AppText.muted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 10),

            ...ClinicDepartment.values.map((dept) {
              final isChecked = _selectedDepts.contains(dept);
              final isPrimary = _primaryDept == dept;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isChecked ? dept.color.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? dept.color : AppColors.line,
                    width: isChecked ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      activeColor: dept.color,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedDepts.add(dept);
                          } else {
                            if (_selectedDepts.length > 1) {
                              _selectedDepts.remove(dept);
                              if (_primaryDept == dept) {
                                _primaryDept = _selectedDepts.first;
                              }
                            } else {
                              showToast(context, 'At least one department is required', error: true);
                            }
                          }
                        });
                      },
                    ),
                    Icon(dept.icon, color: dept.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dept.displayName, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                          Text(dept.description, style: AppText.muted.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    if (isChecked)
                      TextButton(
                        onPressed: () => setState(() => _primaryDept = dept),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          isPrimary ? 'Primary' : 'Make Primary',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                            color: isPrimary ? dept.color : AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saving ? null : _handleCreateClinic,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.add_business_rounded),
                label: Text(
                  _saving ? 'Creating Practice...' : 'Register Clinic & Generate QR',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EDIT HOURS FORM
// ============================================================================
class _EditHoursForm extends ConsumerStatefulWidget {
  const _EditHoursForm({required this.clinic});

  final Clinic clinic;

  @override
  ConsumerState<_EditHoursForm> createState() => _EditHoursFormState();
}

class _EditHoursFormState extends ConsumerState<_EditHoursForm> {
  late TimeOfDay _open = parseHm(widget.clinic.openTime);
  late TimeOfDay _close = parseHm(widget.clinic.closeTime);
  late int _slot = widget.clinic.slotMinutes;
  bool _saving = false;

  Future<void> _save() async {
    if (_close.hour * 60 + _close.minute <= _open.hour * 60 + _open.minute) {
      showToast(context, 'Closing time must be after opening time', error: true);
      return;
    }
    setState(() => _saving = true);
    final updated = widget.clinic.copyWith(
      openTime: formatHm(_open),
      closeTime: formatHm(_close),
      slotMinutes: _slot,
    );
    ref.read(localClinicsProvider.notifier).setClinic(widget.clinic.doctorId, updated);
    try {
      await ref.read(clinicRepositoryProvider).updateClinic(
            widget.clinic.id,
            openTime: formatHm(_open),
            closeTime: formatHm(_close),
            slotMinutes: _slot,
          );
    } catch (_) {}
    ref.invalidate(myClinicProvider);
    if (mounted) {
      showToast(context, 'Consulting hours updated');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consulting Hours', style: AppText.h1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TimeTile(
                label: 'Opens At',
                value: _open,
                onChanged: (t) => setState(() => _open = t),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TimeTile(
                label: 'Closes At',
                value: _close,
                onChanged: (t) => setState(() => _close = t),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Time per patient', style: AppText.bodyBold),
        const SizedBox(height: 10),
        ChoiceGroup<int>(
          options: const [10, 15, 20, 30, 45],
          selected: _slot,
          onChanged: (v) => setState(() => _slot = v),
          labelOf: (v) => '$v min',
        ),
        const SizedBox(height: 22),
        AppButton(label: 'Save Hours', kind: AppButtonKind.accent, loading: _saving, onPressed: _save),
      ],
    );
  }
}

// ============================================================================
// MANAGE DEPARTMENTS SHEET (Add / remove / change departments)
// ============================================================================
class _ManageDepartmentsSheet extends ConsumerStatefulWidget {
  const _ManageDepartmentsSheet({required this.clinic});

  final Clinic clinic;

  @override
  ConsumerState<_ManageDepartmentsSheet> createState() => _ManageDepartmentsSheetState();
}

class _ManageDepartmentsSheetState extends ConsumerState<_ManageDepartmentsSheet> {
  late Set<ClinicDepartment> _selected;
  late ClinicDepartment _primary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(
      widget.clinic.availableDepartments.isNotEmpty
          ? widget.clinic.availableDepartments
          : [widget.clinic.department],
    );
    _primary = widget.clinic.department;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.clinic.copyWith(
      department: _primary,
      availableDepartments: _selected.toList(),
    );
    ref.read(localClinicsProvider.notifier).setClinic(widget.clinic.doctorId, updated);
    try {
      await ref.read(clinicRepositoryProvider).setClinicDepartment(widget.clinic.id, _primary);
    } catch (_) {}
    ref.invalidate(myClinicProvider);
    if (mounted) {
      showToast(context, 'Departments updated for ${widget.clinic.name}');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Manage Clinic Departments', style: AppText.h2),
          const SizedBox(height: 6),
          Text(
            'Select which specialties are offered by your clinic. You can also pick which department serves as your primary practice.',
            style: AppText.small.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ...ClinicDepartment.values.map((dept) {
            final isChecked = _selected.contains(dept);
            final isPrimary = _primary == dept;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isChecked ? dept.color.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChecked ? dept.color : AppColors.line,
                  width: isChecked ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: dept.color,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.add(dept);
                        } else {
                          if (_selected.length > 1) {
                            _selected.remove(dept);
                            if (_primary == dept) {
                              _primary = _selected.first;
                            }
                          } else {
                            showToast(context, 'At least 1 department is required', error: true);
                          }
                        }
                      });
                    },
                  ),
                  Icon(dept.icon, color: dept.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dept.displayName, style: AppText.bodyBold.copyWith(fontSize: 13.5)),
                        Text(dept.description, style: AppText.muted.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  if (isChecked)
                    TextButton(
                      onPressed: () => setState(() => _primary = dept),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        isPrimary ? 'PRIMARY' : 'Set Primary',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                          color: isPrimary ? dept.color : AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          AppButton(
            label: 'Save Department Changes',
            kind: AppButtonKind.accent,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
