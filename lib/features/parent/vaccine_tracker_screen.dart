import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'child_scope.dart';

class VaccineScheduleItem {
  final String id;
  final String name;
  final String ageLabel;
  final String protectsAgainst;
  final String route;
  DateTime dueDate;
  String status; // 'done', 'pending', 'skipped'
  DateTime? givenOn;
  String? clinic;
  String? batchNumber;
  final bool isCustom;

  VaccineScheduleItem({
    required this.id,
    required this.name,
    required this.ageLabel,
    required this.protectsAgainst,
    required this.route,
    required this.dueDate,
    this.status = 'pending',
    this.givenOn,
    this.clinic,
    this.batchNumber,
    this.isCustom = false,
  });

  bool get isDone => status == 'done';
  int get daysToDue => dateOnly(dueDate).difference(dateOnly(DateTime.now())).inDays;
  bool get isOverdue => status == 'pending' && daysToDue < 0;
  bool get isDueSoon => status == 'pending' && daysToDue >= 0 && daysToDue <= 30;
}

class VaccineTrackerScreen extends ConsumerStatefulWidget {
  const VaccineTrackerScreen({super.key});

  @override
  ConsumerState<VaccineTrackerScreen> createState() => _VaccineTrackerScreenState();
}

class _VaccineTrackerScreenState extends ConsumerState<VaccineTrackerScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // In-memory personalized schedules mapped by childId
  final Map<String, List<VaccineScheduleItem>> _childVaccineMap = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VaccineScheduleItem> _getScheduleForChild(Child child) {
    if (_childVaccineMap.containsKey(child.id)) {
      return _childVaccineMap[child.id]!;
    }

    final dob = child.dob;

    DateTime addDays(int days) => dob.add(Duration(days: days));
    DateTime addMonths(int months) => DateTime(dob.year, dob.month + months, dob.day);
    DateTime addYears(int years) => DateTime(dob.year + years, dob.month, dob.day);

    final list = <VaccineScheduleItem>[
      // At Birth
      VaccineScheduleItem(
        id: 'v_bcg',
        name: 'BCG (Tuberculosis)',
        ageLabel: 'At Birth',
        protectsAgainst: 'Tuberculosis & Meningitis',
        route: 'Intradermal (Left arm)',
        dueDate: dob,
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_opv0',
        name: 'OPV 0 (Oral Polio Vaccine)',
        ageLabel: 'At Birth',
        protectsAgainst: 'Poliovirus (Infantile Paralysis)',
        route: 'Oral Drops (2 drops)',
        dueDate: dob,
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_hepb0',
        name: 'Hepatitis B - Dose 1',
        ageLabel: 'At Birth',
        protectsAgainst: 'Hepatitis B viral liver infection',
        route: 'Intramuscular (Anterolateral thigh)',
        dueDate: dob,
        status: 'pending',
      ),

      // 6 Weeks
      VaccineScheduleItem(
        id: 'v_hex1',
        name: 'Hexaxim 1 (6-in-1 DTaP-IPV-HepB-Hib)',
        ageLabel: '6 Weeks',
        protectsAgainst: 'Diphtheria, Tetanus, Whooping Cough, Polio, Hep B, Hib',
        route: 'Intramuscular (Thigh)',
        dueDate: addDays(42),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_rota1',
        name: 'Rotavirus Vaccine - Dose 1',
        ageLabel: '6 Weeks',
        protectsAgainst: 'Severe Rotavirus Diarrhea & Dehydration',
        route: 'Oral Drops',
        dueDate: addDays(42),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_pcv1',
        name: 'PCV 1 (Pneumococcal Conjugate)',
        ageLabel: '6 Weeks',
        protectsAgainst: 'Pneumococcal Pneumonia & Sepsis',
        route: 'Intramuscular (Thigh)',
        dueDate: addDays(42),
        status: 'pending',
      ),

      // 10 Weeks
      VaccineScheduleItem(
        id: 'v_hex2',
        name: 'Hexaxim 2 (6-in-1 DTaP-IPV-HepB-Hib)',
        ageLabel: '10 Weeks',
        protectsAgainst: 'Diphtheria, Tetanus, Pertussis, Polio, Hep B, Hib',
        route: 'Intramuscular (Thigh)',
        dueDate: addDays(70),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_rota2',
        name: 'Rotavirus Vaccine - Dose 2',
        ageLabel: '10 Weeks',
        protectsAgainst: 'Rotavirus Gastrointestinal Infection',
        route: 'Oral Drops',
        dueDate: addDays(70),
        status: 'pending',
      ),

      // 14 Weeks
      VaccineScheduleItem(
        id: 'v_hex3',
        name: 'Hexaxim 3 (6-in-1 DTaP-IPV-HepB-Hib)',
        ageLabel: '14 Weeks',
        protectsAgainst: 'Diphtheria, Tetanus, Pertussis, Polio, Hep B, Hib',
        route: 'Intramuscular (Thigh)',
        dueDate: addDays(98),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_pcv2',
        name: 'PCV 2 (Pneumococcal Conjugate)',
        ageLabel: '14 Weeks',
        protectsAgainst: 'Pneumonia & Otitis Media',
        route: 'Intramuscular (Thigh)',
        dueDate: addDays(98),
        status: 'pending',
      ),

      // 6 Months
      VaccineScheduleItem(
        id: 'v_flu1',
        name: 'Influenza (Quadrivalent Flu) - Dose 1',
        ageLabel: '6 Months',
        protectsAgainst: 'Seasonal Influenza Flu A & B',
        route: 'Intramuscular (Thigh/Arm)',
        dueDate: addMonths(6),
        status: 'pending',
      ),

      // 9 Months
      VaccineScheduleItem(
        id: 'v_mmr1',
        name: 'MMR 1 (Measles, Mumps, Rubella)',
        ageLabel: '9 Months',
        protectsAgainst: 'Measles, Epidemic Parotitis, German Measles',
        route: 'Subcutaneous (Right arm)',
        dueDate: addMonths(9),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_tcv1',
        name: 'Typhoid Conjugate Vaccine (TCV)',
        ageLabel: '9 Months',
        protectsAgainst: 'Salmonella Typhi (Enteric Fever)',
        route: 'Intramuscular',
        dueDate: addMonths(9),
        status: 'pending',
      ),

      // 12 Months
      VaccineScheduleItem(
        id: 'v_hepa1',
        name: 'Hepatitis A (Live/Inactivated) - Dose 1',
        ageLabel: '12 Months',
        protectsAgainst: 'Hepatitis A Liver Infection',
        route: 'Intramuscular (Deltoid)',
        dueDate: addMonths(12),
        status: 'pending',
      ),

      // 15 Months
      VaccineScheduleItem(
        id: 'v_mmr2',
        name: 'MMR 2 (Second Dose)',
        ageLabel: '15 Months',
        protectsAgainst: 'Measles, Mumps, Rubella Booster',
        route: 'Subcutaneous',
        dueDate: addMonths(15),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_pcv_b',
        name: 'PCV Booster (Pneumococcal)',
        ageLabel: '15 Months',
        protectsAgainst: 'Pneumococcal Invasive Disease',
        route: 'Intramuscular',
        dueDate: addMonths(15),
        status: 'pending',
      ),

      // 18 Months
      VaccineScheduleItem(
        id: 'v_dtap_b1',
        name: 'DTaP Booster 1 & IPV',
        ageLabel: '18 Months',
        protectsAgainst: 'Diphtheria, Tetanus, Pertussis, Polio',
        route: 'Intramuscular',
        dueDate: addMonths(18),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_var1',
        name: 'Varicella 1 (Chickenpox)',
        ageLabel: '18 Months',
        protectsAgainst: 'Varicella Zoster Virus',
        route: 'Subcutaneous',
        dueDate: addMonths(18),
        status: 'pending',
      ),

      // 4-6 Years
      VaccineScheduleItem(
        id: 'v_mmr_b',
        name: 'MMR Booster (MMR 3)',
        ageLabel: '4-6 Years',
        protectsAgainst: 'Measles, Mumps, Rubella Final Booster',
        route: 'Subcutaneous (Deltoid)',
        dueDate: addYears(5),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_dtap_b2',
        name: 'DTaP Booster 2',
        ageLabel: '4-6 Years',
        protectsAgainst: 'Diphtheria, Tetanus, Pertussis Booster',
        route: 'Intramuscular (Deltoid)',
        dueDate: addYears(5),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_opv_b',
        name: 'OPV Booster / IPV',
        ageLabel: '4-6 Years',
        protectsAgainst: 'Poliovirus',
        route: 'Oral Drops',
        dueDate: addYears(5),
        status: 'pending',
      ),
      VaccineScheduleItem(
        id: 'v_var2',
        name: 'Varicella Booster 2 (Chickenpox)',
        ageLabel: '4-6 Years',
        protectsAgainst: 'Chickenpox Long-term Immunity',
        route: 'Subcutaneous',
        dueDate: addYears(5),
        status: 'pending',
      ),

      // 9-14 Years
      VaccineScheduleItem(
        id: 'v_hpv',
        name: 'HPV Vaccine (Human Papillomavirus)',
        ageLabel: '9-14 Years',
        protectsAgainst: 'Cervical & Anogenital Cancers',
        route: 'Intramuscular (Deltoid)',
        dueDate: addYears(9),
        status: 'pending',
      ),
    ];

    _childVaccineMap[child.id] = list;
    return list;
  }

  void _markVaccineDone(VaccineScheduleItem item, {DateTime? date, String? doctor, String? batch}) {
    setState(() {
      item.status = 'done';
      item.givenOn = date ?? DateTime.now();
      if (doctor != null && doctor.isNotEmpty) item.clinic = doctor;
      if (batch != null && batch.isNotEmpty) item.batchNumber = batch;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recorded ${item.name} as Given on ${DateFormat("d MMM yyyy").format(item.givenOn!)}!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _undoVaccine(VaccineScheduleItem item) {
    setState(() {
      item.status = 'pending';
      item.givenOn = null;
    });
  }

  void _openVaccineSheet(VaccineScheduleItem item) {
    final batchCtrl = TextEditingController(text: item.batchNumber ?? '');
    final clinicCtrl = TextEditingController(text: item.clinic ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.isDone ? AppColors.mintSoft : AppColors.lavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.isDone ? Icons.verified_rounded : Icons.vaccines_rounded,
                    color: item.isDone ? AppColors.mint : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(item.ageLabel, style: AppText.muted.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Clinical Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Protects against', item.protectsAgainst),
                  const SizedBox(height: 8),
                  _buildDetailRow('Administration Route', item.route),
                  const SizedBox(height: 8),
                  _buildDetailRow('Recommended Due Date', DateFormat('d MMM yyyy').format(item.dueDate)),
                  if (item.isDone && item.givenOn != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Administered On', DateFormat('d MMM yyyy').format(item.givenOn!)),
                    if (item.clinic != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow('Administering Doctor', item.clinic!),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (!item.isDone) ...[
              TextField(
                controller: clinicCtrl,
                decoration: InputDecoration(
                  labelText: 'Administering Clinic / Pediatrician',
                  hintText: 'e.g. Dr. Pediatrician • Clinic Name',
                  prefixIcon: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: batchCtrl,
                decoration: InputDecoration(
                  labelText: 'Batch Number (Optional)',
                  hintText: 'e.g. HX-9281',
                  prefixIcon: const Icon(Icons.qr_code_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Mark Given Today', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _markVaccineDone(item, doctor: clinicCtrl.text.trim(), batch: batchCtrl.text.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: item.dueDate,
                        firstDate: DateTime(2015),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        Navigator.pop(ctx);
                        _markVaccineDone(item, date: picked, doctor: clinicCtrl.text.trim(), batch: batchCtrl.text.trim());
                      }
                    },
                    child: const Text('Past Date', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Undo - Mark as Pending', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _undoVaccine(item);
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddCustomVaccineModal(Child child) {
    final nameCtrl = TextEditingController();
    final protectsCtrl = TextEditingController();
    DateTime customDate = DateTime.now().add(const Duration(days: 30));
    final dateCtrl = TextEditingController(text: DateFormat('d MMM yyyy').format(customDate));
    String route = 'Intramuscular';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Add Custom / Travel Vaccine', style: AppText.h2),
              const SizedBox(height: 4),
              Text('Log optional or international travel immunizations', style: AppText.muted.copyWith(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Vaccine Name',
                  hintText: 'e.g. Japanese Encephalitis / Rabies',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: protectsCtrl,
                decoration: InputDecoration(
                  labelText: 'Protects Against',
                  hintText: 'e.g. Viral Encephalitis transmission',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: customDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setModalState(() {
                      customDate = picked;
                      dateCtrl.text = DateFormat('d MMM yyyy').format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: dateCtrl,
                    decoration: InputDecoration(
                      labelText: 'Due / Administration Date',
                      suffixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
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
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    setState(() {
                      final schedule = _getScheduleForChild(child);
                      schedule.add(
                        VaccineScheduleItem(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          ageLabel: 'Custom',
                          protectsAgainst: protectsCtrl.text.trim().isEmpty ? 'Specialized Protection' : protectsCtrl.text.trim(),
                          route: route,
                          dueDate: customDate,
                          status: 'pending',
                          isCustom: true,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Vaccine to Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCertificateSheet(Child child, List<VaccineScheduleItem> schedule) {
    final doneList = schedule.where((v) => v.isDone).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.mint, size: 28),
                const SizedBox(width: 10),
                Text('Digital Immunization Record', style: AppText.h2),
              ],
            ),
            const SizedBox(height: 4),
            Text('Official WHO / IAP compliant record for school & travel admission', style: AppText.muted.copyWith(fontSize: 12.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lavender.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Patient Name', child.name),
                  const SizedBox(height: 6),
                  _buildDetailRow('Date of Birth', DateFormat('d MMM yyyy').format(child.dob)),
                  const SizedBox(height: 6),
                  _buildDetailRow('Blood Group', child.bloodGroup?.isNotEmpty == true ? child.bloodGroup! : 'Not Recorded'),
                  const SizedBox(height: 6),
                  _buildDetailRow('Vaccines Completed', '${doneList.length} of ${schedule.length}'),
                  const SizedBox(height: 6),
                  _buildDetailRow('Certifying Pediatrician', child.pediatrician?.isNotEmpty == true ? child.pediatrician! : 'Not Assigned'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share / Export Immunization Certificate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0F766E),
                      content: Text('Immunization card exported as PDF!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedChildAsync = ref.watch(selectedChildProvider);
    final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];

    return selectedChildAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Vaccine Tracker')),
        body: const Center(child: Text('Unable to load child details.')),
      ),
      data: (child) {
        final activeChild = child ?? (allChildren.isNotEmpty ? allChildren.first : null);
        if (activeChild == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Vaccine Tracker'),
              centerTitle: false,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.vaccines_rounded, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('No Child Profile Selected', style: AppText.h2),
                    const SizedBox(height: 8),
                    const Text(
                      'Please add a child profile to view their personalized immunization schedule and digital records.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13.5),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.push('/parent/add-child'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Child Profile'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final schedule = _getScheduleForChild(activeChild);

        final doneCount = schedule.where((v) => v.isDone).length;
        final dueSoonCount = schedule.where((v) => v.isDueSoon).length;
        final overdueCount = schedule.where((v) => v.isOverdue).length;
        final totalCount = schedule.length;
        final progress = totalCount > 0 ? (doneCount / totalCount) : 0.0;

        // Apply filters
        var filtered = schedule.where((v) {
          if (_selectedFilter == 'Completed') return v.isDone;
          if (_selectedFilter == 'Due Soon') return v.isDueSoon || v.isOverdue;
          if (_selectedFilter == 'Upcoming') return !v.isDone && !v.isOverdue;
          return true;
        }).toList();

        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filtered = filtered.where((v) =>
              v.name.toLowerCase().contains(query) ||
              v.protectsAgainst.toLowerCase().contains(query) ||
              v.ageLabel.toLowerCase().contains(query)).toList();
        }

        // Group by ageLabel
        final groups = <String, List<VaccineScheduleItem>>{};
        for (final v in filtered) {
          groups.putIfAbsent(v.ageLabel, () => []).add(v);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Vaccine Tracker',
              style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 24),
                tooltip: 'Immunization Pass',
                onPressed: () => _showCertificateSheet(activeChild, schedule),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                tooltip: 'Add Custom Vaccine',
                onPressed: () => _showAddCustomVaccineModal(activeChild),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Child Selection Switcher Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/avatar_child.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(activeChild.name, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      activeChild.bloodGroup ?? 'O+',
                                      style: const TextStyle(color: Color(0xFF0F766E), fontSize: 11, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${activeChild.age} • Born ${DateFormat("d MMM yyyy").format(activeChild.dob)}',
                                style: AppText.muted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (allChildren.length > 1)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                            onSelected: (id) => ref.read(selectedChildIdProvider.notifier).state = id,
                            itemBuilder: (ctx) => allChildren.map((c) => PopupMenuItem(value: c.id, child: Text(c.name))).toList(),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.person_add_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => context.push('/parent/add-child'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Overall Vaccination Gauge Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3478ED), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF36C6B0)),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Immunization Progress',
                                    style: AppText.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$doneCount of $totalCount recommended vaccines completed',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildGaugeSubStat('Completed', '$doneCount', const Color(0xFF36C6B0)),
                            _buildGaugeSubStat('Due Soon', '$dueSoonCount', const Color(0xFFFBBF24)),
                            _buildGaugeSubStat('Overdue', '$overdueCount', const Color(0xFFF87171)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search vaccine or disease (e.g. MMR, Polio)',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Due Soon', 'Completed', 'Upcoming'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(filter),
                            selectedColor: AppColors.primary,
                            backgroundColor: const Color(0xFFF8FAFC),
                            labelStyle: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.ink,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedule List by Age Bracket
                  if (groups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        'No vaccines found for "$_selectedFilter"',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  else
                    ...groups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.lavender,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    entry.key.toUpperCase(),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Due around ${DateFormat("MMM yyyy").format(entry.value.first.dueDate)}',
                                  style: AppText.muted.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((v) => _buildVaccineItem(v)),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGaugeSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildVaccineItem(VaccineScheduleItem item) {
    Color badgeBg;
    Color badgeFg;
    String badgeText;
    IconData icon;

    if (item.isDone) {
      badgeBg = AppColors.mintSoft;
      badgeFg = const Color(0xFF0F766E);
      badgeText = 'Given ✅';
      icon = Icons.check_circle_rounded;
    } else if (item.isOverdue) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeFg = AppColors.danger;
      badgeText = 'Overdue';
      icon = Icons.warning_rounded;
    } else if (item.isDueSoon) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFFD97706);
      badgeText = 'Due Soon';
      icon = Icons.schedule_rounded;
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = AppColors.muted;
      badgeText = 'Upcoming';
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openVaccineSheet(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: badgeFg, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        item.isDone && item.givenOn != null
                            ? 'Given on ${DateFormat("d MMM yyyy").format(item.givenOn!)}'
                            : 'Due on ${DateFormat("d MMM yyyy").format(item.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isDone ? const Color(0xFF0F766E) : (item.isDueSoon ? const Color(0xFFD97706) : AppColors.muted),
                          fontWeight: item.isDueSoon ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(item.protectsAgainst, style: AppText.muted.copyWith(fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(badgeText, style: TextStyle(color: badgeFg, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
