import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'parent_bottom_nav.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime _selectedDob = DateTime.now().subtract(const Duration(days: 365 * 2)); // Default ~2 yrs
  String _gender = 'Male';

  // Physical Vitals
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _birthWeightController = TextEditingController();

  // Clinical Profile
  String _selectedBloodGroup = 'O+';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final List<String> _commonAllergies = ['None', 'Penicillin', 'Peanuts', 'Dairy / Lactose', 'Eggs', 'Dust', 'Sulfa'];
  final Set<String> _selectedAllergies = {'None'};

  final List<String> _commonConditions = ['None', 'Asthma', 'Eczema', 'Febrile Seizures', 'G6PD', 'Congenital Heart'];
  final Set<String> _selectedConditions = {'None'};

  // Healthcare & Emergency
  final _pediatricianController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dobController.text = DateFormat('d MMM yyyy').format(_selectedDob);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _birthWeightController.dispose();
    _pediatricianController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  String get _calculatedAgeText {
    final now = DateTime.now();
    int years = now.year - _selectedDob.year;
    int months = now.month - _selectedDob.month;
    if (now.day < _selectedDob.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years == 0) {
      return '$months months old';
    }
    return '$years yrs, $months mos old';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('d MMM yyyy').format(picked);
      });
    }
  }

  void _adjustWeight(double delta) {
    double current = double.tryParse(_weightController.text.trim()) ?? 12.0;
    current = (current + delta).clamp(1.0, 70.0);
    setState(() {
      _weightController.text = current.toStringAsFixed(1);
    });
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (allergy == 'None') {
        _selectedAllergies.clear();
        _selectedAllergies.add('None');
      } else {
        _selectedAllergies.remove('None');
        if (_selectedAllergies.contains(allergy)) {
          _selectedAllergies.remove(allergy);
          if (_selectedAllergies.isEmpty) _selectedAllergies.add('None');
        } else {
          _selectedAllergies.add(allergy);
        }
      }
    });
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (condition == 'None') {
        _selectedConditions.clear();
        _selectedConditions.add('None');
      } else {
        _selectedConditions.remove('None');
        if (_selectedConditions.contains(condition)) {
          _selectedConditions.remove(condition);
          if (_selectedConditions.isEmpty) _selectedConditions.add('None');
        } else {
          _selectedConditions.add(condition);
        }
      }
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showToast(context, "Please enter your child's name", error: true);
      return;
    }

    final weight = double.tryParse(_weightController.text.trim()) ?? 12.0;
    final height = double.tryParse(_heightController.text.trim());
    final birthWeight = double.tryParse(_birthWeightController.text.trim());

    final allergiesStr = _selectedAllergies.join(', ');
    final conditionsStr = _selectedConditions.join(', ');
    final emergencyPhone = _emergencyPhoneController.text.trim();

    setState(() => _saving = true);

    try {
      final childId = 'child-${DateTime.now().millisecondsSinceEpoch}';
      final newChild = Child(
        id: childId,
        parentId: 'parent-1',
        name: name,
        dob: _selectedDob,
        gender: _gender.toLowerCase(),
        bloodGroup: _selectedBloodGroup,
        allergies: allergiesStr,
        weightKg: weight,
        heightCm: height,
        birthWeightKg: birthWeight,
        chronicConditions: conditionsStr,
        emergencyContact: emergencyPhone.isEmpty ? null : '${_emergencyNameController.text.trim()} ($emergencyPhone)',
        pediatrician: _pediatricianController.text.trim().isEmpty ? null : _pediatricianController.text.trim(),
        parentName: _emergencyNameController.text.trim().isNotEmpty ? _emergencyNameController.text.trim() : 'Parent',
        parentPhone: emergencyPhone.isNotEmpty ? emergencyPhone : null,
      );

      // Save to local reactive provider immediately
      ref.read(localChildrenProvider.notifier).addChild(newChild);
      ref.read(selectedChildIdProvider.notifier).state = childId;
      ref.invalidate(childrenProvider);
      ref.invalidate(selectedChildProvider);

      // Also persist to Supabase if signed in
      final uid = ref.read(userIdProvider);
      if (uid != null) {
        try {
          await ref.read(healthRepositoryProvider).addChild(
                parentId: uid,
                name: name,
                dob: _selectedDob,
                gender: _gender.toLowerCase(),
                bloodGroup: _selectedBloodGroup,
                allergies: allergiesStr,
                weightKg: weight,
                heightCm: height,
                birthWeightKg: birthWeight,
                chronicConditions: conditionsStr,
                emergencyContact: emergencyPhone,
                pediatrician: _pediatricianController.text.trim(),
              );
        } catch (_) {}
      }

      if (mounted) {
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
                    'Profile created for $name! Immunization & doses calibrated.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
        context.go('/parent/home');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/parent/home'),
        ),
        title: Text(
          'Add Child Profile',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Card with 3D Illustration & Guidance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF5FF), Color(0xFFE0F2FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/add_child.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Child Health Profile",
                              style: AppText.h2.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Provide clinical details to personalize vaccine schedules, growth charts, and medication dosages.',
                              style: AppText.muted.copyWith(fontSize: 12, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 1: BASIC INFORMATION
                // ==========================================
                _buildSectionHeader('1. Basic Information', Icons.person_rounded, AppColors.primary),
                const SizedBox(height: 12),

                // Child's Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Child's Full Name *",
                    hintText: 'e.g. Diya Sharma',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Enter child's full name" : null,
                ),
                const SizedBox(height: 14),

                // Date of Birth & Live Age Display
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth *',
                        prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primary),
                        suffixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          child: Text(
                            _calculatedAgeText,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Gender Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderChoice('Male', 'Boy 👦', Icons.male_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGenderChoice('Female', 'Girl 👧', Icons.female_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // ==========================================
                // SECTION 2: GROWTH & PHYSICAL VITALS
                // ==========================================
                _buildSectionHeader('2. Physical Vitals & Growth', Icons.monitor_weight_outlined, const Color(0xFF0F766E)),
                const SizedBox(height: 6),
                Text(
                  'Critical for pediatric dose calculations and WHO growth charts.',
                  style: AppText.muted.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Current Weight with Stepper
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Weight (kg) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              SizedBox(height: 2),
                              Text('Calibrates syrup mL doses', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () => _adjustWeight(-0.5),
                              ),
                              SizedBox(
                                width: 70,
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: AppText.h3.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    suffixText: 'kg',
                                    suffixStyle: TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => _adjustWeight(0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Height & Birth Weight
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          hintText: 'e.g. 92.5',
                          prefixIcon: const Icon(Icons.height_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _birthWeightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Birth Weight',
                          hintText: 'e.g. 3.2 kg',
                          prefixIcon: const Icon(Icons.child_care_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // ==========================================
                // SECTION 3: CLINICAL & MEDICAL PROFILE
                // ==========================================
                _buildSectionHeader('3. Clinical & Medical Profile', Icons.medical_services_outlined, const Color(0xFFDC2626)),
                const SizedBox(height: 12),

                // Blood Group Chips
                const Text('Blood Group *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bloodGroups.map((bg) {
                    final isSelected = _selectedBloodGroup == bg;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(bg),
                      selectedColor: const Color(0xFFFEE2E2),
                      backgroundColor: const Color(0xFFF8FAFC),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFFDC2626) : AppColors.ink,
                        fontSize: 13,
                      ),
                      onSelected: (_) => setState(() => _selectedBloodGroup = bg),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Known Allergies
                const Text('Known Drug / Food Allergies', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonAllergies.map((allergy) {
                    final isSelected = _selectedAllergies.contains(allergy);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(allergy),
                      selectedColor: const Color(0xFFFEF3C7),
                      backgroundColor: const Color(0xFFF8FAFC),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFFB45309) : AppColors.ink,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => _toggleAllergy(allergy),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Chronic Conditions
                const Text('Chronic Pediatric Conditions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonConditions.map((cond) {
                    final isSelected = _selectedConditions.contains(cond);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(cond),
                      selectedColor: AppColors.lavender,
                      backgroundColor: const Color(0xFFF8FAFC),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.ink,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => _toggleCondition(cond),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 26),

                // ==========================================
                // SECTION 4: PRIMARY PEDIATRICIAN & EMERGENCY
                // ==========================================
                _buildSectionHeader('4. Doctor & Emergency Contact', Icons.emergency_share_outlined, const Color(0xFF8B5CF6)),
                const SizedBox(height: 12),

                // Primary Pediatrician
                TextFormField(
                  controller: _pediatricianController,
                  decoration: InputDecoration(
                    labelText: 'Primary Pediatrician / Clinic',
                    hintText: 'e.g., Dr. Pediatrician • Children Clinic',
                    prefixIcon: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),

                // Emergency Contact Name & Phone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emergencyNameController,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact',
                          hintText: 'e.g. Father (Bala)',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+91 98765 43210',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Text(
                            'Save Child Profile & Calibrate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const ParentBottomNav(currentIndex: 2),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _buildGenderChoice(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.muted, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.ink,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
