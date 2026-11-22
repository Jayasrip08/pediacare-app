import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import '../shared/growth_view.dart';
import '../shared/vaccines_view.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({
    super.key,
    required this.childId,
    this.appointmentId,
  });

  final String childId;
  final String? appointmentId;

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog(BuildContext context, Child child) {
    final noteCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Clinical Note for ${child.name}',
          style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16.5),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note Title / Subject',
                  hintText: 'e.g. Clinical Consultation Note',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter note title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Doctor Observations & Advice',
                  hintText: 'e.g. Chest clear on auscultation. Throat mild congestion. Advised steam inhalation.',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter clinical note' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final newRecord = MedicalRecord(
                id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                childId: child.id,
                title: titleCtrl.text.trim(),
                category: 'other',
                filePath: 'notes/clinical_${child.id}.pdf',
                createdAt: DateTime.now(),
              );
              ref.read(localRecordsProvider.notifier).addRecord(newRecord);
              ref.invalidate(recordsProvider(child.id));
              Navigator.pop(ctx);
              showToast(context, 'Clinical note added to patient record');
            },
            child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showScheduleFollowUpDialog(BuildContext context, Child child) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 30);
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Schedule Follow-up: ${child.name}',
                style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16.5),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Review Date:', style: AppText.small.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        setDlgState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(DateFormat('EEE, d MMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Follow-up',
                      hintText: 'e.g. Routine Follow-up & Review',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final currentDoc = ref.read(currentDoctorAccountProvider);
                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    final newAppt = Appointment(
                      id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
                      clinicId: 'clinic_${currentDoc.id}',
                      childId: child.id,
                      childName: child.name,
                      doctorName: currentDoc.name,
                      specialty: currentDoc.specialty,
                      doctorAvatar: currentDoc.avatarPath,
                      clinicName: "Apollo Children's Specialty Clinic",
                      scheduledAt: scheduledDateTime,
                      status: 'booked',
                      tokenNo: 5,
                      reason: reasonCtrl.text.trim(),
                    );
                    ref.read(localAppointmentsProvider.notifier).addAppointment(newAppt);
                    ref.invalidate(childAppointmentsProvider(child.id));

                    // Add patient to doctor roster if needed
                    final docPatient = DoctorPatient(
                      id: child.id,
                      name: child.name,
                      ageDisplay: child.age,
                      condition: reasonCtrl.text.trim(),
                      time: DateFormat('hh:mm a').format(scheduledDateTime),
                      avatarPath: 'assets/images/avatar_child.png',
                      gender: child.gender,
                      bloodGroup: child.bloodGroup,
                      weightKg: child.weightKg,
                      status: 'Scheduled',
                    );
                    ref.read(doctorPatientsProvider.notifier).addPatientToDoctor(currentDoc.id, docPatient);

                    Navigator.pop(ctx);
                    showToast(context, 'Follow-up visit scheduled for ${fmtDayDate(scheduledDateTime)}');
                  },
                  child: const Text('Confirm Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdateRecordDialog(BuildContext context, Child child) {
    final weightCtrl = TextEditingController(text: child.weightKg != null ? numFmt(child.weightKg!) : '18.5');
    final heightCtrl = TextEditingController(text: child.heightCm != null ? numFmt(child.heightCm!) : '115.0');
    final allergiesCtrl = TextEditingController(text: child.allergies ?? 'None');
    final conditionsCtrl = TextEditingController(text: child.chronicConditions ?? 'None');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Update Vitals & Health Record', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Update physical measurements and clinical tags for ${child.name}', style: AppText.muted.copyWith(fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_rounded)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: allergiesCtrl,
                  decoration: const InputDecoration(labelText: 'Known Allergies', prefixIcon: Icon(Icons.shield_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: conditionsCtrl,
                  decoration: const InputDecoration(labelText: 'Chronic Conditions', prefixIcon: Icon(Icons.healing_outlined)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final w = double.tryParse(weightCtrl.text.trim()) ?? child.weightKg;
                      final h = double.tryParse(heightCtrl.text.trim()) ?? child.heightCm;
                      final updated = child.copyWith(
                        weightKg: w,
                        heightCm: h,
                        allergies: allergiesCtrl.text.trim(),
                        chronicConditions: conditionsCtrl.text.trim(),
                      );
                      ref.read(localChildrenProvider.notifier).updateChild(updated);
                      ref.invalidate(childByIdProvider(child.id));
                      ref.invalidate(growthProvider(child.id));
                      Navigator.pop(ctx);
                      showToast(context, 'Patient clinical record updated successfully');
                    },
                    child: const Text('Save Record Updates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final childAsync = ref.watch(childByIdProvider(widget.childId));
    final allDocPatients = ref.watch(currentDoctorPatientsProvider);
    final docPatient = allDocPatients.where((p) => p.id == widget.childId).firstOrNull;
    final child = childAsync.valueOrNull ??
        Child(
          id: widget.childId,
          parentId: '',
          name: docPatient?.name ?? 'Patient',
          dob: DateTime.now().subtract(const Duration(days: 365 * 3)),
          gender: docPatient?.gender ?? 'child',
          bloodGroup: docPatient?.bloodGroup,
          weightKg: docPatient?.weightKg,
          parentName: docPatient?.parentName,
          parentPhone: docPatient?.parentPhone,
        );

    final childName = child.name.isNotEmpty ? child.name : (docPatient?.name ?? 'Patient');
    final childAge = child.age.isNotEmpty ? child.age : (docPatient?.ageDisplay ?? 'Child');
    final childGender = child.gender.isNotEmpty
        ? (child.gender[0].toUpperCase() + child.gender.substring(1))
        : (docPatient != null && docPatient.gender.isNotEmpty ? docPatient.gender[0].toUpperCase() + docPatient.gender.substring(1) : 'Male');
    final bloodGroup = child.bloodGroup ?? docPatient?.bloodGroup ?? '—';
    final weight = child.weightKg ?? docPatient?.weightKg ?? 12.0;
    final allergies = child.allergies != null && child.allergies!.isNotEmpty && child.allergies != 'None'
        ? child.allergies!
        : 'No Known Drug Allergies';
    final conditions = child.chronicConditions != null && child.chronicConditions!.isNotEmpty && child.chronicConditions != 'None'
        ? child.chronicConditions!
        : (docPatient?.condition ?? 'General Pediatric Care');
    final parentName = child.parentName ?? docPatient?.parentName ?? 'Guardian';
    final parentPhone = child.parentPhone ?? docPatient?.parentPhone ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Patient Details',
          style: AppText.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            tooltip: 'Update Record',
            onPressed: () => _showUpdateRecordDialog(context, child),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Patient Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        docPatient?.avatarPath ?? 'assets/images/avatar_child.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.lavender,
                          child: const Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  childName,
                                  style: AppText.h2.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bloodGroup,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$childAge • $childGender • ${numFmt(weight)} kg',
                            style: AppText.muted.copyWith(fontSize: 12.5),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Parent: $parentName ($parentPhone)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Growth'),
                Tab(text: 'Vaccines'),
              ],
            ),
            const Divider(color: AppColors.line, height: 1),

            // Tab Bar View content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Overview Tab
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Medical Details Cards
                      _ClinicalInfoCard(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.danger,
                        title: 'Allergies & Drug Sensitivities',
                        content: allergies,
                      ),
                      const SizedBox(height: 12),
                      _ClinicalInfoCard(
                        icon: Icons.healing_outlined,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Chief Complaint / Chronic Conditions',
                        content: conditions,
                      ),
                      const SizedBox(height: 12),
                      _ClinicalInfoCard(
                        icon: Icons.monitor_weight_outlined,
                        iconColor: AppColors.mint,
                        title: 'Physical Vitals',
                        content: 'Weight: ${numFmt(weight)} kg • Height: ${numFmt(child.heightCm ?? 115.0)} cm • Blood: $bloodGroup',
                      ),
                      const SizedBox(height: 12),
                      _ClinicalInfoCard(
                        icon: Icons.phone_in_talk_outlined,
                        iconColor: AppColors.primary,
                        title: 'Parent & Emergency Contact',
                        content: '$parentName • Phone: $parentPhone',
                      ),
                      const SizedBox(height: 24),

                      // Quick Action Buttons (Prescription, Add Note, Follow-up)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionIconButton(
                            label: 'Prescription',
                            imageAsset: 'assets/images/prescription_badge.png',
                            onTap: () {
                              context.push(
                                '/doctor/patient/${widget.childId}/prescribe${widget.appointmentId != null ? "?appointmentId=${widget.appointmentId}" : ""}',
                              );
                            },
                          ),
                          _ActionIconButton(
                            label: 'Add Note',
                            icon: Icons.note_add_outlined,
                            onTap: () => _showAddNoteDialog(context, child),
                          ),
                          _ActionIconButton(
                            label: 'Follow-up',
                            imageAsset: 'assets/images/book_appointment.png',
                            onTap: () => _showScheduleFollowUpDialog(context, child),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // History Tab (Past Visits & Prescriptions)
                  _PatientHistoryTab(childId: child.id),

                  // Growth Tab (Percentile Curves & Measurements)
                  GrowthView(key: ValueKey(child.id), child: child),

                  // Vaccines Tab (Immunization Status)
                  VaccinesView(key: ValueKey(child.id), childId: child.id),
                ],
              ),
            ),

            // Bottom Update Record Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateRecordDialog(context, child),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Update Clinical Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientHistoryTab extends ConsumerWidget {
  const _PatientHistoryTab({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(prescriptionsProvider(childId));
    final appointmentsAsync = ref.watch(childAppointmentsProvider(childId));
    final recordsAsync = ref.watch(recordsProvider(childId));

    final prescriptions = prescriptionsAsync.valueOrNull ?? [];
    final appointments = appointmentsAsync.valueOrNull ?? [];
    final records = recordsAsync.valueOrNull ?? [];

    if (prescriptions.isEmpty && appointments.isEmpty && records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.lavender.withValues(alpha: 0.5), shape: BoxShape.circle),
                child: const Icon(Icons.history_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text('No Past Visits Yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Consultation history and prescriptions will appear here.', style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (prescriptions.isNotEmpty) ...[
          const Text('Prescriptions & Diagnoses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 8),
          ...prescriptions.map((rx) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: InkWell(
                onTap: () => context.push('/prescription/${rx.id}'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rx.diagnosis ?? 'Prescription', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${rx.doctorName ?? "Consulting Doctor"} • ${fmtDate(rx.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          Text('${rx.items.length} prescribed medication(s)', style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        if (appointments.isNotEmpty) ...[
          const Text('Consultation Appointments', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 8),
          ...appointments.map((a) {
            final isCompleted = a.status == 'completed';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isCompleted ? AppColors.mint.withValues(alpha: 0.4) : AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.mint.withValues(alpha: 0.1) : AppColors.lavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event_available_rounded, color: isCompleted ? AppColors.mint : AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.reason ?? 'Pediatric Visit', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${fmtDayDate(a.scheduledAt)} • ${fmtTime(a.scheduledAt)}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        Text(a.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isCompleted ? AppColors.mint : AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        if (records.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Clinical Notes & Vault Reports', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 8),
          ...records.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.description_outlined, color: AppColors.ink, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text(fmtDate(r.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _ClinicalInfoCard extends StatelessWidget {
  const _ClinicalInfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.small.copyWith(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: AppText.bodyBold.copyWith(
                    color: AppColors.ink,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.label,
    this.imageAsset,
    this.icon,
    required this.onTap,
  });

  final String label;
  final String? imageAsset;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: imageAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(imageAsset!, fit: BoxFit.contain),
                    )
                  : Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
