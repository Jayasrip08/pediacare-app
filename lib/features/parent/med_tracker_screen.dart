import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

enum DoseStatus { pending, taken, snoozed, skipped }

class DoseSchedule {
  final String id;
  final String medicineName;
  final String form; // Syrup, Tablet, Drops, Inhaler
  final String dose; // e.g., 5.0 mL, 1 puff, 1 tab
  final String time; // e.g., 08:00 AM
  final String timeSlot; // Morning, Afternoon, Evening, Night
  final String foodInstruction; // After food, Before food
  final String doctor;
  final Color accentColor;
  DoseStatus status;
  DateTime? takenAt;

  DoseSchedule({
    required this.id,
    required this.medicineName,
    required this.form,
    required this.dose,
    required this.time,
    required this.timeSlot,
    required this.foodInstruction,
    required this.doctor,
    required this.accentColor,
    this.status = DoseStatus.pending,
    this.takenAt,
  });
}

class MedTrackerScreen extends ConsumerStatefulWidget {
  const MedTrackerScreen({super.key});

  @override
  ConsumerState<MedTrackerScreen> createState() => _MedTrackerScreenState();
}

class _MedTrackerScreenState extends ConsumerState<MedTrackerScreen> {
  int _selectedDayIndex = 2; // Wednesday (Today)

  final List<String> _days = ['Mon\n17', 'Tue\n18', 'Today\n19', 'Thu\n20', 'Fri\n21', 'Sat\n22', 'Sun\n23'];

  final List<DoseSchedule> _doses = [];

  int get _takenCount => _doses.where((d) => d.status == DoseStatus.taken).length;
  double get _progress => _doses.isEmpty ? 0 : _takenCount / _doses.length;

  void _markDoseTaken(DoseSchedule dose) {
    setState(() {
      dose.status = DoseStatus.taken;
      dose.takenAt = DateTime.now();
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
                'Logged ${dose.medicineName} (${dose.dose}) as given!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snoozeDose(DoseSchedule dose, int minutes) {
    setState(() {
      dose.status = DoseStatus.snoozed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Snoozed ${dose.medicineName} for $minutes minutes.',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  void _undoDose(DoseSchedule dose) {
    setState(() {
      dose.status = DoseStatus.pending;
      dose.takenAt = null;
    });
  }

  void _showAddMedicineModal() {
    final selectedChild = ref.read(selectedChildProvider).valueOrNull;
    final allChildren = ref.read(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);

    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    String selectedForm = 'Syrup';
    String selectedSlot = 'Morning (08:00 AM)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Dose Reminder', style: AppText.h2),
              const SizedBox(height: 4),
              Text(
                currentChild != null ? 'Set schedule and dosage for ${currentChild.name}' : 'Set schedule and dosage',
                style: AppText.muted.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  hintText: 'e.g. Augmentin 228mg',
                  prefixIcon: const Icon(Icons.medication_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedForm,
                      decoration: InputDecoration(
                        labelText: 'Form',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Syrup', child: Text('Syrup')),
                        DropdownMenuItem(value: 'Drops', child: Text('Drops')),
                        DropdownMenuItem(value: 'Tablet', child: Text('Tablet')),
                        DropdownMenuItem(value: 'Inhaler', child: Text('Inhaler')),
                      ],
                      onChanged: (v) => setModalState(() => selectedForm = v ?? 'Syrup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: doseCtrl,
                      decoration: InputDecoration(
                        labelText: 'Dose',
                        hintText: '5 mL',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedSlot,
                decoration: InputDecoration(
                  labelText: 'Time Slot',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Morning (08:00 AM)', child: Text('Morning (08:00 AM)')),
                  DropdownMenuItem(value: 'Afternoon (01:30 PM)', child: Text('Afternoon (01:30 PM)')),
                  DropdownMenuItem(value: 'Evening (07:30 PM)', child: Text('Evening (07:30 PM)')),
                  DropdownMenuItem(value: 'Bedtime (09:30 PM)', child: Text('Bedtime (09:30 PM)')),
                ],
                onChanged: (v) => setModalState(() => selectedSlot = v ?? 'Morning (08:00 AM)'),
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
                    final slotParts = selectedSlot.split(' ');
                    final slotName = slotParts[0];
                    final time = slotParts[1].replaceAll('(', '').replaceAll(')', '');
                    setState(() {
                      _doses.add(
                        DoseSchedule(
                          id: 'dose-${DateTime.now().millisecondsSinceEpoch}',
                          medicineName: name,
                          form: selectedForm,
                          dose: doseCtrl.text.trim(),
                          time: time,
                          timeSlot: slotName,
                          foodInstruction: 'As instructed by doctor',
                          doctor: currentChild?.pediatrician ?? 'Pediatrician',
                          accentColor: AppColors.mint,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider).valueOrNull;
    final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);

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
          'Medicine Tracker',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
            onPressed: _showAddMedicineModal,
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
              // Child Profile & Weight Calibration Badge
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
                        width: 46,
                        height: 46,
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
                              Text(
                                currentChild?.name ?? 'No Child Selected',
                                style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              if (currentChild?.weightKg != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${currentChild!.weightKg} kg',
                                    style: const TextStyle(
                                      color: Color(0xFF0F766E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentChild != null
                                ? 'Pediatrician: ${currentChild.pediatrician ?? "Not Assigned"}'
                                : 'Add a child profile to manage medication schedules',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Horizontal Day Picker
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final isSelected = i == _selectedDayIndex;
                    return InkWell(
                      onTap: () => setState(() => _selectedDayIndex = i),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 54,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.line.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _days[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Today's Adherence Gauge Card
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
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Circular progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 62,
                          height: 62,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF36C6B0)),
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Today’s Adherence',
                                style: AppText.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.local_fire_department_rounded, color: Color(0xFFFBBF24), size: 14),
                                    SizedBox(width: 3),
                                    Text(
                                      '5 Days Streak',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_takenCount of ${_doses.length} doses given today',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Doses Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scheduled Doses',
                    style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${_doses.length} Doses',
                    style: AppText.muted.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Doses List
              if (_doses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication_liquid_outlined, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('No Active Medication Schedules', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap "+ Add Dose" above to schedule pediatric syrups, drops, or tablets for your child.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ..._doses.map((dose) => _DoseCard(
                      dose: dose,
                      onMarkGiven: () => _markDoseTaken(dose),
                      onSnooze: (mins) => _snoozeDose(dose, mins),
                      onUndo: () => _undoDose(dose),
                    )),

              const SizedBox(height: 16),

              // Pediatric Dosing Safety Tip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pediatric Measuring Tip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Always use the graduated oral syringe or measuring cup provided with the syrup. Household kitchen spoons vary greatly and cause dosing errors.',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF92400E).withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.onMarkGiven,
    required this.onSnooze,
    required this.onUndo,
  });

  final DoseSchedule dose;
  final VoidCallback onMarkGiven;
  final ValueChanged<int> onSnooze;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final isTaken = dose.status == DoseStatus.taken;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTaken ? const Color(0xFF36C6B0).withValues(alpha: 0.5) : AppColors.line.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isTaken ? AppColors.mintSoft : AppColors.lavender,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                  color: isTaken ? AppColors.mint : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dose.medicineName,
                            style: AppText.h3.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              decoration: isTaken ? TextDecoration.lineThrough : null,
                              color: isTaken ? AppColors.muted : AppColors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dose.time,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dose.form} • ${dose.dose}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dose.foodInstruction} • Prescribed by ${dose.doctor}',
                      style: AppText.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          if (isTaken)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Given today ✅',
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onUndo,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.muted,
                  ),
                  child: const Text('Undo', style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Mark Given', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: onMarkGiven,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => onSnooze(30),
                    child: const Text('Snooze 30m', style: TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
