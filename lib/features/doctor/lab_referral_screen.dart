import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class LabReferralScreen extends ConsumerStatefulWidget {
  const LabReferralScreen({super.key});

  @override
  ConsumerState<LabReferralScreen> createState() => _LabReferralScreenState();
}

class _LabReferralScreenState extends ConsumerState<LabReferralScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Lab orders state
  final Map<String, bool> _labTests = {
    'Complete Blood Count (CBC + Diff)': false,
    'C-Reactive Protein (CRP quantitative)': false,
    'Erythrocyte Sedimentation Rate (ESR)': false,
    'Dengue NS1 Antigen & IgM/IgG': false,
    'Peripheral Blood Smear for Malarial Parasite': false,
    'Urine Routine & Microscopy': false,
    'Chest X-Ray (AP View)': false,
    'Serum Electrolytes (Na, K, Cl)': false,
  };

  bool _isStatUrgent = false;
  final _labNotesCtrl = TextEditingController();

  // Referral state
  String _selectedSpecialty = 'Pediatric ENT';
  String _urgency = 'Within 48 hours';
  final _referralNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _labNotesCtrl.dispose();
    _referralNotesCtrl.dispose();
    super.dispose();
  }

  void _generateLabOrder() {
    final selectedCount = _labTests.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one laboratory test.')),
      );
      return;
    }

    final doc = ref.read(currentDoctorAccountProvider);
    final patients = ref.read(currentDoctorPatientsProvider);
    final patient = patients.isNotEmpty ? patients.first : null;
    final patientName = patient?.name ?? 'Walk-in Patient';
    final patientDetails = patient != null ? ' (${patient.ageGender})' : '';

    showModalBottomSheet(
      context: context,
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
                const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 26),
                const SizedBox(width: 10),
                Text('Lab Requisition Generated', style: AppText.h2),
              ],
            ),
            const SizedBox(height: 10),
            Text('Ordered $selectedCount tests for $patientName$patientDetails. Signed by ${doc.name}.', style: AppText.muted.copyWith(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lavender.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Priority: ${_isStatUrgent ? "STAT (Urgent 2h)" : "Routine"}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text('Clinical Indication: ${_labNotesCtrl.text.trim()}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send to Partner Diagnostic Lab & Parent', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0F766E),
                      content: Text('Lab requisition sent directly to diagnostic lab and parent portal.'),
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

  void _generateReferral() {
    final doc = ref.read(currentDoctorAccountProvider);
    final patients = ref.read(currentDoctorPatientsProvider);
    final patient = patients.isNotEmpty ? patients.first : null;
    final patientName = patient?.name ?? 'Walk-in Patient';

    showModalBottomSheet(
      context: context,
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
                const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 10),
                Text('Specialist Referral Note', style: AppText.h2),
              ],
            ),
            const SizedBox(height: 10),
            Text('Referral for $patientName to $_selectedSpecialty. Signed by ${doc.name}.', style: AppText.muted.copyWith(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Specialty: $_selectedSpecialty ($_urgency)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Text(_referralNotesCtrl.text.trim(), style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Export & Share Referral Letter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0F766E),
                      content: Text('Referral letter generated and shared with parent.'),
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

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(currentDoctorAccountProvider);
    final patients = ref.watch(currentDoctorPatientsProvider);
    final patient = patients.isNotEmpty ? patients.first : null;

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
          'Lab & Referral Orders',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Lab Investigations'),
            Tab(text: 'Specialist Referral'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Patient Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.lavender.withValues(alpha: 0.4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/avatar_child.png', width: 36, height: 36, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient: ${patient?.name ?? "Walk-in Patient"}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
                        Text(patient?.ageGender ?? 'Pediatric Consultation', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text('Dr. ${doc.name.replaceFirst("Dr. ", "")}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 12.5)),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLabOrdersTab(),
                  _buildReferralTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Laboratory Tests', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              Row(
                children: [
                  const Text('STAT (Urgent)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
                  Switch(
                    value: _isStatUrgent,
                    activeColor: AppColors.danger,
                    onChanged: (v) => setState(() => _isStatUrgent = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: _labTests.keys.map((test) {
                final checked = _labTests[test] ?? false;
                return CheckboxListTile(
                  value: checked,
                  dense: true,
                  activeColor: AppColors.primary,
                  title: Text(
                    test,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  onChanged: (v) => setState(() => _labTests[test] = v ?? false),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Text('Clinical Indication / Diagnosis', style: AppText.h3.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _labNotesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g., Acute febrile illness with persistent cough',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.assignment_outlined, size: 20),
              label: const Text('Generate Lab Requisition', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              onPressed: _generateLabOrder,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReferralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Refer to Sub-Specialist', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSpecialty,
            decoration: InputDecoration(
              labelText: 'Pediatric Specialty',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: const [
              DropdownMenuItem(value: 'Pediatric ENT', child: Text('Pediatric ENT (Ear, Nose, Throat)')),
              DropdownMenuItem(value: 'Pediatric Cardiology', child: Text('Pediatric Cardiology')),
              DropdownMenuItem(value: 'Pediatric Neurology', child: Text('Pediatric Neurology')),
              DropdownMenuItem(value: 'Pediatric Surgery', child: Text('Pediatric Surgery')),
              DropdownMenuItem(value: 'Child Psychology / Development', child: Text('Child Development / Psychology')),
              DropdownMenuItem(value: 'Pediatric Ophthalmology', child: Text('Pediatric Ophthalmology')),
            ],
            onChanged: (v) => setState(() => _selectedSpecialty = v ?? 'Pediatric ENT'),
          ),
          const SizedBox(height: 16),

          Text('Referral Urgency', style: AppText.h3.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildUrgencyChip('Within 24 hours'),
              const SizedBox(width: 8),
              _buildUrgencyChip('Within 48 hours'),
              const SizedBox(width: 8),
              _buildUrgencyChip('Routine (2 weeks)'),
            ],
          ),
          const SizedBox(height: 16),

          Text('Clinical Summary & Reason for Referral', style: AppText.h3.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _referralNotesCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe patient history, clinical findings, and question for consultant',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text('Sign & Generate Referral Letter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              onPressed: _generateReferral,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String label) {
    final isSelected = _urgency == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _urgency = label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.line),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
