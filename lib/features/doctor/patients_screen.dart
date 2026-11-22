import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'doctor_bottom_nav.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String _query = '';

  void _showAddPatientDialog(BuildContext context, DoctorAccount doctor) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();
    final parentCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String gender = 'male';
    String bloodGroup = 'B+';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Add Patient to ${doctor.name}',
                style: AppText.h2.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Child Full Name *',
                          hintText: 'e.g. Maya Krishnan',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Enter patient name' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age (Years) *',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter age' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: gender,
                              decoration: const InputDecoration(labelText: 'Gender'),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Boy')),
                                DropdownMenuItem(value: 'female', child: Text('Girl')),
                              ],
                              onChanged: (v) => setDlgState(() => gender = v ?? 'male'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: conditionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis / Chief Complaint',
                          hintText: 'e.g. Mild wheezing, fever',
                          prefixIcon: Icon(Icons.healing_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: parentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Parent / Guardian Name',
                          hintText: 'e.g. Radhika K',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Parent Contact Phone',
                          hintText: 'e.g. +91 98765 00000',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final patientId = 'child_${DateTime.now().millisecondsSinceEpoch}';
                    final newDocPatient = DoctorPatient(
                      id: patientId,
                      name: nameCtrl.text.trim(),
                      ageDisplay: '${ageCtrl.text.trim()} years',
                      condition: conditionCtrl.text.trim().isEmpty ? 'General Checkup' : conditionCtrl.text.trim(),
                      time: '11:30 AM',
                      avatarPath: gender == 'female'
                          ? 'assets/images/avatar_divya.png'
                          : 'assets/images/avatar_child.png',
                      gender: gender,
                      bloodGroup: bloodGroup,
                      parentName: parentCtrl.text.trim().isEmpty ? null : parentCtrl.text.trim(),
                      parentPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      lastVisit: DateTime.now(),
                    );

                    ref.read(doctorPatientsProvider.notifier).addPatientToDoctor(doctor.id, newDocPatient);
                    ref.invalidate(patientsProvider);
                    Navigator.pop(ctx);
                    showToast(context, 'Patient ${newDocPatient.name} added to ${doctor.name} practice');
                  },
                  child: const Text('Add Patient'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientsProvider);
    final currentDoc = ref.watch(currentDoctorAccountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Assigned Patients', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(
              '${currentDoc.name} • Private Directory',
              style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            tooltip: 'Add Walk-in Patient',
            onPressed: () => _showAddPatientDialog(context, currentDoc),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search patients of ${currentDoc.name}...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView<List<Patient>>(
              value: async,
              onRetry: () => ref.invalidate(patientsProvider),
              data: (all) {
                final list = all
                    .where((p) =>
                        _query.isEmpty ||
                        p.child.name.toLowerCase().contains(_query) ||
                        (p.child.parentName ?? '').toLowerCase().contains(_query))
                    .toList();

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lavender.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_rounded, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Patients Assigned to ${currentDoc.name}',
                            style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Each doctor maintains their own private patient list. Parents join your clinic by scanning your Clinic QR code, or you can register walk-in patients.',
                            style: AppText.muted.copyWith(fontSize: 12.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _showAddPatientDialog(context, currentDoc),
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Add Walk-in Patient', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(patientsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return AppCard(
                        onTap: () => context.push('/doctor/patient/${p.child.id}'),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            InitialAvatar(name: p.child.name, size: 48),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(p.child.name, style: AppText.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                                      if (p.child.bloodGroup != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.child.bloodGroup!,
                                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.child.age} • ${p.child.gender[0].toUpperCase()}${p.child.gender.substring(1)}'
                                    '${p.child.parentName == null ? '' : ' • Parent: ${p.child.parentName}'}',
                                    style: AppText.small.copyWith(color: AppColors.muted),
                                  ),
                                  Text(
                                    p.lastVisit == null
                                        ? 'Active today in waiting room'
                                        : 'Last visit: ${fmtDate(p.lastVisit!)}',
                                    style: AppText.small.copyWith(fontSize: 11, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 1),
    );
  }
}
