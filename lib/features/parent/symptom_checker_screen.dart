import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

enum TriageLevel { green, yellow, red }

class TempReading {
  final double tempF;
  final String method;
  final DateTime time;
  final String note;

  TempReading({
    required this.tempF,
    required this.method,
    required this.time,
    required this.note,
  });
}

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Triage state
  String _selectedSymptom = 'Fever';
  double _temperatureF = 101.4;
  String _duration = '1-2 days';
  String _activityLevel = 'Mildly irritable';
  String _fluidIntake = 'Drinking less than usual';

  // Red flags
  final Map<String, bool> _redFlags = {
    'Blue or pale lips / fingernails': false,
    'Chest pulling in while breathing (retractions)': false,
    'Stiff neck or extreme sensitivity to light': false,
    'Refusing all fluids for more than 8 hours': false,
    'Drowsy / difficult to wake up': false,
    'Dark purple rash that does not fade when pressed': false,
  };

  bool _assessmentSubmitted = false;

  // Temperature log list
  final List<TempReading> _tempLog = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TriageLevel get _triageResult {
    // Red flags check
    if (_redFlags.values.any((flag) => flag == true)) {
      return TriageLevel.red;
    }
    if (_temperatureF >= 104.0) {
      return TriageLevel.red;
    }
    if (_activityLevel == 'Drowsy / hard to wake') {
      return TriageLevel.red;
    }
    if (_fluidIntake == 'No fluids in >8 hrs') {
      return TriageLevel.red;
    }

    // Yellow check
    if (_duration == '>3 days' || _temperatureF >= 102.0 || _fluidIntake == 'Drinking very little') {
      return TriageLevel.yellow;
    }

    return TriageLevel.green;
  }

  void _showAddTempModal() {
    double tempVal = 100.5;
    String method = 'Forehead';
    final noteCtrl = TextEditingController();

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
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Log Temperature Reading', style: AppText.h2),
              const SizedBox(height: 4),
              Builder(builder: (c) {
                final selectedChild = ref.watch(selectedChildProvider).valueOrNull;
                final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];
                final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);
                return Text(
                  currentChild != null ? 'Recording for ${currentChild.name} (${currentChild.age})' : 'Recording temperature',
                  style: AppText.muted.copyWith(fontSize: 13),
                );
              }),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${tempVal.toStringAsFixed(1)}°F',
                      style: AppText.display.copyWith(
                        color: tempVal >= 102.0
                            ? AppColors.danger
                            : (tempVal >= 100.4 ? const Color(0xFFF59E0B) : AppColors.mint),
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      tempVal >= 102.0 ? 'High Fever' : (tempVal >= 100.4 ? 'Mild Fever' : 'Normal Temperature'),
                      style: TextStyle(
                        color: tempVal >= 102.0 ? AppColors.danger : AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: tempVal,
                min: 97.0,
                max: 105.0,
                divisions: 80,
                activeColor: AppColors.primary,
                onChanged: (v) => setModalState(() => tempVal = (v * 10).round() / 10),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: method,
                decoration: InputDecoration(
                  labelText: 'Measurement Method',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Forehead', child: Text('Forehead (Infrared Scanner)')),
                  DropdownMenuItem(value: 'Armpit', child: Text('Armpit (Axillary)')),
                  DropdownMenuItem(value: 'Oral', child: Text('Oral (Under tongue)')),
                  DropdownMenuItem(value: 'Ear', child: Text('Ear (Tympanic)')),
                ],
                onChanged: (v) => setModalState(() => method = v ?? 'Forehead'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Optional Note / Medication Given',
                  hintText: 'e.g., Given 7.5 ml syrup',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                    setState(() {
                      _tempLog.insert(
                        0,
                        TempReading(
                          tempF: tempVal,
                          method: method,
                          time: DateTime.now(),
                          note: noteCtrl.text.trim().isEmpty ? 'Routine check' : noteCtrl.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Reading', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
          'Symptom & Triage',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Symptom Checker'),
            Tab(text: 'Temperature Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSymptomCheckerTab(),
          _buildTempLogTab(),
        ],
      ),
    );
  }

  Widget _buildSymptomCheckerTab() {
    final selectedChild = ref.watch(selectedChildProvider).valueOrNull;
    final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child selector chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/avatar_child.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentChild != null
                        ? 'Assessing: ${currentChild.name} (${currentChild.age}${currentChild.weightKg != null ? " • ${currentChild.weightKg} kg" : ""})'
                        : 'Assessing Pediatric Symptoms',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Symptom Grid
          Text('1. What is the primary concern?', style: AppText.h3.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip('Fever', Icons.thermostat_rounded),
              _buildChoiceChip('Cough / Breathing', Icons.air_rounded),
              _buildChoiceChip('Vomiting / Stomach', Icons.sick_outlined),
              _buildChoiceChip('Skin Rash', Icons.bubble_chart_outlined),
              _buildChoiceChip('Ear / Throat Pain', Icons.hearing_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Current Temperature
          Text('2. Current Body Temperature', style: AppText.h3.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_temperatureF.toStringAsFixed(1)}°F',
                      style: AppText.h1.copyWith(
                        color: _temperatureF >= 102.0
                            ? AppColors.danger
                            : (_temperatureF >= 100.4 ? const Color(0xFFF59E0B) : AppColors.mint),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _temperatureF >= 102.0 ? 'High Fever' : (_temperatureF >= 100.4 ? 'Mild Fever' : 'Normal'),
                      style: TextStyle(
                        color: _temperatureF >= 102.0 ? AppColors.danger : AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _temperatureF,
                  min: 98.0,
                  max: 105.0,
                  divisions: 70,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() {
                    _temperatureF = (v * 10).round() / 10;
                    _assessmentSubmitted = false;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Duration
          Text('3. How long has this symptom lasted?', style: AppText.h3.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRadioOption('duration', '< 24 hours'),
              const SizedBox(width: 8),
              _buildRadioOption('duration', '1-2 days'),
              const SizedBox(width: 8),
              _buildRadioOption('duration', '> 3 days'),
            ],
          ),
          const SizedBox(height: 20),

          // Red Flag Checklist
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
              const SizedBox(width: 6),
              Text('4. Check any active Red Flags:', style: AppText.h3.copyWith(fontSize: 15, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              children: _redFlags.keys.map((flag) {
                final checked = _redFlags[flag] ?? false;
                return CheckboxListTile(
                  value: checked,
                  dense: true,
                  activeColor: AppColors.danger,
                  title: Text(
                    flag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _redFlags[flag] = v ?? false;
                      _assessmentSubmitted = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Check Triage Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.health_and_safety_outlined, size: 20),
              label: const Text('Evaluate Symptoms Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              onPressed: () {
                setState(() => _assessmentSubmitted = true);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Triage Result Display
          if (_assessmentSubmitted) _buildTriageResultCard(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, IconData icon) {
    final isSelected = _selectedSymptom == label;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.ink),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.ink,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() {
        _selectedSymptom = label;
        _assessmentSubmitted = false;
      }),
    );
  }

  Widget _buildRadioOption(String type, String value) {
    final isSelected = _duration == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _duration = value;
          _assessmentSubmitted = false;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.line),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriageResultCard() {
    final result = _triageResult;
    final selectedChild = ref.watch(selectedChildProvider).valueOrNull;
    final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);
    final pediatrician = currentChild?.pediatrician ?? 'Pediatrician';

    if (result == TriageLevel.red) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.danger, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'EMERGENCY: Immediate Medical Care Required',
                    style: AppText.h3.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Your child displays symptoms or red flags requiring prompt emergency evaluation. Do not delay medical assessment.',
              style: TextStyle(fontSize: 13, color: Color(0xFF991B1B), height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                label: const Text('Call Ambulance / ER (108 / 112)', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/parent/emergency'),
              ),
            ),
          ],
        ),
      );
    }

    if (result == TriageLevel.yellow) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: Color(0xFFD97706), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pediatrician Consultation Recommended',
                    style: AppText.h3.copyWith(
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Fever or symptoms have persisted or elevated. We recommend booking an appointment with your pediatrician within 12-24 hours.',
              style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text('Book Appointment with $pediatrician', style: const TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/parent/book'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mint, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.mint, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Safe for Home Care & Monitoring',
                  style: AppText.h3.copyWith(
                    color: const Color(0xFF166534),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'No emergency red flags detected. Child is responsive and hydrating.',
            style: TextStyle(fontSize: 13, color: Color(0xFF166534), height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Home Care Guidelines${currentChild != null ? " (${currentChild.name})" : ""}:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF166534)),
                ),
                const SizedBox(height: 6),
                const Text('• Ensure frequent sips of water, coconut water, or oral rehydration solution.', style: TextStyle(fontSize: 12, height: 1.35)),
                const Text('• Give age & weight-appropriate antipyretic if temp > 100.4°F as advised by doctor.', style: TextStyle(fontSize: 12, height: 1.35)),
                const Text('• Sponge with lukewarm water (never ice or cold water).', style: TextStyle(fontSize: 12, height: 1.35)),
                const Text('• If fever or lethargy persists beyond 48-72 hours, consult your pediatrician.', style: TextStyle(fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempLogTab() {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Log Temperature', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: _showAddTempModal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Temperature History', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${_tempLog.length} readings', style: AppText.muted.copyWith(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            if (_tempLog.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.only(top: 10),
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
                      child: const Icon(Icons.thermostat_outlined, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text('No Temperature Readings Yet', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap "Log Temperature" below to track fever readings and monitor trends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ..._tempLog.map((reading) {
              final isHigh = reading.tempF >= 102.0;
              final isMild = reading.tempF >= 100.4;
              final color = isHigh ? AppColors.danger : (isMild ? const Color(0xFFF59E0B) : AppColors.mint);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
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
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${reading.tempF.toStringAsFixed(1)}°',
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
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
                              Text(
                                isHigh ? 'High Fever' : (isMild ? 'Mild Fever' : 'Normal Temp'),
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                              ),
                              const Spacer(),
                              Text(
                                '${reading.time.hour.toString().padLeft(2, '0')}:${reading.time.minute.toString().padLeft(2, '0')}',
                                style: AppText.muted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Method: ${reading.method} • ${reading.note}',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
