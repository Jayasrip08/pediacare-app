import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'doctor_bottom_nav.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Scheduled', 'Completed'
  String _searchQuery = '';

  void _showNewAppointmentModal(BuildContext context, DoctorAccount doc) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final complaintCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String gender = 'male';
    String bloodGroup = 'O+';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Schedule Walk-in / OPD Slot',
                        style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Assign appointment directly to ${doc.name}',
                        style: AppText.muted.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name *',
                          hintText: 'e.g. Child Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Enter patient name' : null,
                      ),
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: timeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Slot Time *',
                                hintText: 'e.g. 02:30 PM',
                                prefixIcon: Icon(Icons.schedule_rounded),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter time' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: complaintCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Chief Complaint / Reason *',
                          hintText: 'e.g. Persistent fever & dry cough',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Enter complaint' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final newPatient = DoctorPatient(
                              id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
                              name: nameCtrl.text.trim(),
                              ageDisplay: '${ageCtrl.text.trim()} years',
                              condition: complaintCtrl.text.trim(),
                              time: timeCtrl.text.trim(),
                              avatarPath: 'assets/images/avatar_child.png',
                              gender: gender,
                              bloodGroup: bloodGroup,
                              status: 'Scheduled',
                              lastVisit: DateTime.now(),
                            );
                            ref.read(doctorPatientsProvider.notifier).addPatientToDoctor(doc.id, newPatient);
                            Navigator.pop(ctx);
                            showToast(context, 'Appointment booked for ${newPatient.name} at ${newPatient.time}');
                          },
                          child: const Text('Confirm & Add to Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDoc = ref.watch(currentDoctorAccountProvider);
    final clinic = ref.watch(myClinicProvider).valueOrNull;
    final allPatients = ref.watch(currentDoctorPatientsProvider);

    final filteredAppointments = allPatients.where((appt) {
      if (_selectedFilter != 'All' && appt.status.toLowerCase() != _selectedFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return appt.name.toLowerCase().contains(_searchQuery) ||
            appt.condition.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/doctor/dashboard');
            }
          },
        ),
        title: Column(
          children: [
            const Text(
              'Doctor Appointments',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            Text(
              '${currentDoc.name} • ${clinic?.name ?? 'Practice'}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add OPD Appointment',
            onPressed: () => _showNewAppointmentModal(context, currentDoc),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search appointments by patient or condition...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip('All', allPatients.length),
                const SizedBox(width: 8),
                _buildFilterChip('Scheduled', allPatients.where((p) => p.status == 'Scheduled').length),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', allPatients.where((p) => p.status == 'Completed').length),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Appointments List
          Expanded(
            child: filteredAppointments.isEmpty
                ? Center(
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
                            child: const Icon(Icons.calendar_today_rounded, size: 44, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedFilter == 'All'
                                ? 'No Appointments Scheduled'
                                : 'No $_selectedFilter Appointments',
                            style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Appointments booked by parents or added by clinic reception for ${currentDoc.name} will appear here.',
                            style: AppText.muted.copyWith(fontSize: 12.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _showNewAppointmentModal(context, currentDoc),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Appointment', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = filteredAppointments[index];
                      final isCompleted = appt.status.toLowerCase() == 'completed';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCompleted ? AppColors.mint.withValues(alpha: 0.5) : AppColors.line,
                            width: isCompleted ? 1.4 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Patient Info + Time Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.asset(
                                      appt.avatarPath,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.lavender,
                                        child: const Icon(Icons.person_rounded, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              appt.name,
                                              style: AppText.h3.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
                                            ),
                                            if (appt.bloodGroup != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  appt.bloodGroup!,
                                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${appt.ageDisplay} • ${(appt.gender.isNotEmpty ? appt.gender[0].toUpperCase() + appt.gender.substring(1) : "Child")}',
                                          style: AppText.muted.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Time and Status
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.lavender.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          appt.time,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppColors.mint.withValues(alpha: 0.15)
                                              : AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          appt.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: isCompleted ? AppColors.mint : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Chief Complaint Tag
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.notes_rounded, size: 16, color: AppColors.muted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        appt.condition,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Action Buttons Row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => context.push('/doctor/patient/${appt.id}'),
                                      icon: const Icon(Icons.assignment_ind_outlined, size: 16, color: AppColors.primary),
                                      label: const Text('Patient Chart', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isCompleted ? Colors.grey.shade600 : AppColors.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        final newStatus = isCompleted ? 'Scheduled' : 'Completed';
                                        ref.read(doctorPatientsProvider.notifier).updatePatientStatus(currentDoc.id, appt.id, newStatus);
                                        final appts = ref.read(localAppointmentsProvider);
                                        for (final a in appts) {
                                          if (a.childId == appt.id || a.id == appt.id) {
                                            ref.read(localAppointmentsProvider.notifier).updateStatus(a.id, newStatus.toLowerCase());
                                          }
                                        }
                                        showToast(context, 'Appointment marked as $newStatus');
                                      },
                                      icon: Icon(isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded, size: 16),
                                      label: Text(
                                        isCompleted ? 'Mark Pending' : 'Complete Visit',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 2),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: AppColors.lavender,
      backgroundColor: Colors.grey.shade50,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppColors.primary : AppColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.line,
        ),
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }
}
