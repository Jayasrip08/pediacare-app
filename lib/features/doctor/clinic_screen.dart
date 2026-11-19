import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class ClinicScreen extends ConsumerWidget {
  const ClinicScreen({super.key});

  void _editHours(BuildContext context, WidgetRef ref, Clinic clinic) {
    showAppSheet<void>(context, builder: (_) => _EditHoursForm(clinic: clinic));
  }

  void _editDepartment(BuildContext context, WidgetRef ref, Clinic clinic) {
    showAppSheet<void>(
      context,
      builder: (_) => _EditDepartmentSheet(clinic: clinic),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClinicProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('My clinic')),
      body: AsyncValueView<Clinic?>(
        value: async,
        onRetry: () => ref.invalidate(myClinicProvider),
        data: (clinic) {
          if (clinic == null) return const ErrorView(message: 'No clinic found.');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              AppCard(
                color: AppColors.navy,
                borderColor: AppColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clinic.name, style: AppText.h1.copyWith(color: Colors.white)),
                    if (clinic.address != null) ...[
                      const SizedBox(height: 4),
                      Text(clinic.address!, style: AppText.muted.copyWith(color: Colors.white70)),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: AppColors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${clinic.openTime} – ${clinic.closeTime} · ${clinic.slotMinutes} min per patient',
                            style: AppText.body.copyWith(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _editHours(context, ref, clinic),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                borderColor: clinic.department.color.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: clinic.department.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(clinic.department.icon,
                              color: clinic.department.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CLINIC SPECIALTY / DEPARTMENT',
                                  style: AppText.label.copyWith(fontSize: 10)),
                              const SizedBox(height: 2),
                              Text(clinic.department.displayName,
                                  style: AppText.bodyBold.copyWith(fontSize: 15)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _editDepartment(context, ref, clinic),
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clinic.department.description,
                      style: AppText.small.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: clinic.department.tabs.map((tab) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(tab,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SectionHeader('Patient onboarding QR'),
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
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: AppColors.navy),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square, color: AppColors.navy),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('CLINIC CODE', style: AppText.label),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(clinic.joinCode, style: AppText.display.copyWith(letterSpacing: 4)),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: clinic.joinCode));
                            if (context.mounted) showToast(context, 'Code copied');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Parents scan this QR in the PediaCare app to join your clinic. '
                      'Display it at the reception desk.',
                      style: AppText.small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SectionHeader('Account'),
              AppCard(
                child: Row(
                  children: [
                    InitialAvatar(name: profile?.fullName ?? '?'),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.fullName ?? '', style: AppText.h3),
                          Text(profile?.phone == null ? 'Doctor' : '+${profile!.phone}',
                              style: AppText.small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                kind: AppButtonKind.outline,
                onPressed: () async {
                  final ok = await confirmDialog(context,
                      title: 'Sign out?',
                      message: 'You can sign back in any time.',
                      confirmLabel: 'Sign out');
                  if (ok) await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

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
    try {
      await ref.read(clinicRepositoryProvider).updateClinic(
            widget.clinic.id,
            openTime: formatHm(_open),
            closeTime: formatHm(_close),
            slotMinutes: _slot,
          );
      ref.invalidate(myClinicProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showToast(context, errorMessage(e), error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consulting hours', style: AppText.h1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: TimeTile(
                    label: 'Opens', value: _open, onChanged: (t) => setState(() => _open = t))),
            const SizedBox(width: 12),
            Expanded(
                child: TimeTile(
                    label: 'Closes', value: _close, onChanged: (t) => setState(() => _close = t))),
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
        const SizedBox(height: 22),
        AppButton(label: 'Save', kind: AppButtonKind.accent, loading: _saving, onPressed: _save),
      ],
    );
  }
}

class _EditDepartmentSheet extends StatefulWidget {
  const _EditDepartmentSheet({required this.clinic});

  final Clinic clinic;

  @override
  State<_EditDepartmentSheet> createState() => _EditDepartmentSheetState();
}

class _EditDepartmentSheetState extends State<_EditDepartmentSheet> {
  late ClinicDepartment _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.clinic.department;
  }

  Future<void> _save(WidgetRef ref) async {
    setState(() => _saving = true);
    try {
      await ref.read(clinicRepositoryProvider).setClinicDepartment(widget.clinic.id, _selected);
      ref.invalidate(myClinicProvider);
      if (mounted) {
        showToast(context, 'Department updated to ${_selected.displayName}');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, errorMessage(e), error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Clinic Specialty', style: AppText.h2),
              const SizedBox(height: 6),
              Text(
                'Changing your department dynamically switches clinical workspaces, records, and patient tracking tools.',
                style: AppText.small.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              ...ClinicDepartment.values.map((dept) {
                final isSelected = _selected == dept;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selected = dept),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? dept.color.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? dept.color : AppColors.line,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: dept.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
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
                                    color: isSelected ? dept.color : AppColors.ink,
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
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: dept.color, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              AppButton(
                label: 'Confirm Specialty',
                kind: AppButtonKind.accent,
                loading: _saving,
                onPressed: () => _save(ref),
              ),
            ],
          ),
        );
      },
    );
  }
}
