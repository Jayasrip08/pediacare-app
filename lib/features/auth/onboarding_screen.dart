import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _clinicName = TextEditingController();
  final _clinicAddress = TextEditingController();
  final _clinicPhone = TextEditingController();

  UserRole? _role;
  ClinicDepartment _department = ClinicDepartment.pediatrics;
  TimeOfDay _open = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 18, minute: 0);
  int _slot = 15;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _clinicName.dispose();
    _clinicAddress.dispose();
    _clinicPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_role == null) {
      showToast(context, 'Please choose how you will use PediaCare', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final openMin = _open.hour * 60 + _open.minute;
    final closeMin = _close.hour * 60 + _close.minute;
    if (_role == UserRole.doctor && closeMin <= openMin) {
      showToast(context, 'Closing time must be after opening time', error: true);
      return;
    }

    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_role == UserRole.parent) {
        await auth.createParentProfile(uid: uid, fullName: _name.text);
      } else {
        await auth.createDoctorProfile(
          uid: uid,
          fullName: _name.text,
          clinicName: _clinicName.text,
          clinicAddress: _clinicAddress.text,
          clinicPhone: _clinicPhone.text,
          openTime: formatHm(_open),
          closeTime: formatHm(_close),
          slotMinutes: _slot,
          department: _department,
        );
      }
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = _role == UserRole.doctor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to PediaCare'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('I am a…', style: AppText.h2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.family_restroom_rounded,
                      title: 'Parent',
                      subtitle: 'Track my child’s health',
                      selected: _role == UserRole.parent,
                      onTap: () => setState(() => _role = UserRole.parent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.medical_services_rounded,
                      title: 'Doctor',
                      subtitle: 'Run my clinic',
                      selected: _role == UserRole.doctor,
                      onTap: () => setState(() => _role = UserRole.doctor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isDoctor ? 'Doctor name (e.g. Dr. Kavitha R)' : 'Your name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v ?? '').trim().length >= 2 ? null : 'Please enter your name',
              ),
              if (isDoctor) ...[
                const SizedBox(height: 28),
                Text('Choose your department', style: AppText.h2),
                const SizedBox(height: 4),
                Text(
                  'The app adapts its clinical tools, records, and patient tracking to your specialty.',
                  style: AppText.small.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                ...ClinicDepartment.values.map((dept) {
                  final isSel = _department == dept;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _department = dept),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSel ? dept.color.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? dept.color : AppColors.line,
                            width: isSel ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: dept.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(dept.icon, color: dept.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dept.displayName,
                                    style: AppText.bodyBold.copyWith(
                                      color: isSel ? dept.color : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dept.description,
                                    style: AppText.small.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel)
                              Icon(Icons.check_circle_rounded, color: dept.color, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text('Clinic Details', style: AppText.h2),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clinicName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Clinic name',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter clinic name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _clinicAddress,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter clinic address' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _clinicPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Clinic phone (optional)',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Consulting hours', style: AppText.bodyBold),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: TimeTile(
                            label: 'Opens',
                            value: _open,
                            onChanged: (t) => setState(() => _open = t))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TimeTile(
                            label: 'Closes',
                            value: _close,
                            onChanged: (t) => setState(() => _close = t))),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Time per patient', style: AppText.bodyBold),
                const SizedBox(height: 10),
                ChoiceGroup<int>(
                  options: const [10, 15, 20, 30],
                  selected: _slot,
                  onChanged: (v) => setState(() => _slot = v),
                  labelOf: (v) => '$v min',
                ),
                const SizedBox(height: 12),
                Text(
                  'Doctor accounts should be verified by PediaCare before real patients are onboarded.',
                  style: AppText.small,
                ),
              ],
              const SizedBox(height: 28),
              AppButton(
                label: 'Continue',
                kind: AppButtonKind.accent,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: selected ? AppColors.navy : Colors.white,
      borderColor: selected ? AppColors.navy : AppColors.line,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: icon,
            color: selected ? Colors.white : AppColors.orange,
            background: selected ? AppColors.navyLight : AppColors.orangeSoft,
          ),
          const SizedBox(height: 14),
          Text(title, style: AppText.h2.copyWith(color: selected ? Colors.white : AppColors.ink)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppText.small.copyWith(color: selected ? Colors.white70 : AppColors.muted)),
        ],
      ),
    );
  }
}
