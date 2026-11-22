import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> with SingleTickerProviderStateMixin {
  late final TabController _firstAidTabController;

  final List<String> _guides = ['Choking', 'Febrile Seizures', 'Poisoning', 'Anaphylaxis', 'Burns'];

  @override
  void initState() {
    super.initState();
    _firstAidTabController = TabController(length: _guides.length, vsync: this);
  }

  @override
  void dispose() {
    _firstAidTabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing $phoneNumber...'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  void _showMedicalIdQr() {
    final selectedChild = ref.read(selectedChildProvider).valueOrNull;
    final allChildren = ref.read(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Child Emergency Medical Pass', style: AppText.h2),
            const SizedBox(height: 4),
            Text(
              'Show to school, daycare, or ER staff for immediate child vitals',
              textAlign: TextAlign.center,
              style: AppText.muted.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Mock QR card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Text(
              currentChild != null
                  ? '${currentChild.name} • Blood Group: ${currentChild.bloodGroup?.isNotEmpty == true ? currentChild.bloodGroup! : "Not Recorded"}\nEmergency Contact: ${currentChild.emergencyContact ?? currentChild.parentPhone ?? "None recorded"}'
                  : 'Emergency Medical Pass • No child profile selected',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Pass', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
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
          'Emergency SOS & First Aid',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red Emergency Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'Emergency SOS Hotline',
                          style: AppText.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to immediately call pediatric emergency services or clinic hotline.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _EmergencyDialButton(
                            label: 'Ambulance\n(108 / 112)',
                            icon: Icons.local_hospital_rounded,
                            onTap: () => _makeCall('108'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _EmergencyDialButton(
                            label: 'Apollo Children ER\n044 2829 0200',
                            icon: Icons.emergency_share_rounded,
                            onTap: () => _makeCall('04428290200'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _EmergencyDialButton(
                            label: 'National Emergency\n112',
                            icon: Icons.local_police_outlined,
                            onTap: () => _makeCall('112'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _EmergencyDialButton(
                            label: 'Poison Control\n1800 116 117',
                            icon: Icons.science_outlined,
                            onTap: () => _makeCall('1800116117'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Emergency Child Medical Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Child Medical ID', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text('Show Pass', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: _showMedicalIdQr,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: currentChild != null
                    ? Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/avatar_child.png',
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
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
                                          currentChild.name,
                                          style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                        if (currentChild.bloodGroup?.isNotEmpty == true) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Blood ${currentChild.bloodGroup}',
                                              style: const TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${currentChild.age}${currentChild.weightKg != null ? ' • ${currentChild.weightKg} kg body weight' : ''}',
                                      style: AppText.muted.copyWith(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          _buildMedicalRow(Icons.warning_amber_rounded, 'Severe Allergies', currentChild.allergies?.isNotEmpty == true ? currentChild.allergies! : 'None Reported', AppColors.danger),
                          const SizedBox(height: 8),
                          _buildMedicalRow(Icons.medical_information_outlined, 'Chronic Condition', currentChild.chronicConditions?.isNotEmpty == true ? currentChild.chronicConditions! : 'None Reported', AppColors.primary),
                          const SizedBox(height: 8),
                          _buildMedicalRow(Icons.phone_outlined, 'Emergency Contact', currentChild.emergencyContact ?? currentChild.parentPhone ?? 'Not Added', AppColors.ink),
                        ],
                      )
                    : Column(
                        children: [
                          const Icon(Icons.child_care_rounded, size: 36, color: AppColors.muted),
                          const SizedBox(height: 8),
                          Text('No Child Profile Selected', style: AppText.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(height: 4),
                          const Text('Add a child profile to generate emergency medical QR and SOS health pass.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
              ),
              const SizedBox(height: 26),

              // Visual Step-by-Step First Aid Guides
              Text('Pediatric First Aid Guides', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _guides.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final isSelected = _firstAidTabController.index == i;
                    return InkWell(
                      onTap: () => setState(() => _firstAidTabController.index = i),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _guides[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Selected First Aid Guide Content
              _buildGuideContent(_firstAidTabController.index),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalRow(IconData icon, String title, String val, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink),
        ),
        Expanded(
          child: Text(
            val,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideContent(int index) {
    switch (index) {
      case 0:
        return _buildChokingGuide();
      case 1:
        return _buildSeizureGuide();
      case 2:
        return _buildPoisoningGuide();
      case 3:
        return _buildAnaphylaxisGuide();
      case 4:
      default:
        return _buildBurnsGuide();
    }
  }

  Widget _buildChokingGuide() {
    return _GuideCard(
      title: 'Choking Protocol (Child > 1 Year)',
      subtitle: 'Perform Heimlich Maneuver immediately if child cannot cough, speak, or breathe.',
      steps: const [
        '1. Stand or kneel behind the child and wrap your arms around their waist.',
        '2. Make a fist with one hand and place the thumb side just above the child’s navel (well below breastbone).',
        '3. Grasp your fist with your other hand and give quick, inward and upward abdominal thrusts.',
        '4. Repeat thrusts until the lodged object is expelled.',
        '5. If child becomes unconscious, lower to ground and start CPR immediately while calling 108.',
      ],
      warning: 'Never blindly sweep the mouth with fingers unless you clearly see the object.',
    );
  }

  Widget _buildSeizureGuide() {
    return _GuideCard(
      title: 'High Fever & Febrile Convulsions',
      subtitle: 'Febrile seizures can occur during sudden temperature spikes in young children.',
      steps: const [
        '1. Gently place the child onto their side in the recovery position to keep airway clear.',
        '2. Loosen tight clothing around the neck and chest.',
        '3. Protect their head by placing a folded towel or cushion underneath.',
        '4. Note the exact time the seizure started.',
        '5. DO NOT put anything into the child’s mouth (no fingers, spoons, or water).',
        '6. If seizure lasts longer than 5 minutes, call 108 immediately.',
      ],
      warning: 'Never restrain the child’s arms or legs during a convulsion.',
    );
  }

  Widget _buildPoisoningGuide() {
    return _GuideCard(
      title: 'Accidental Poisoning / Ingestion',
      subtitle: 'Household cleaners, detergents, or overdose of adult medicines.',
      steps: const [
        '1. Keep child calm and remove any remaining substance from their hands or mouth.',
        '2. DO NOT induce vomiting unless specifically told by a poison specialist.',
        '3. DO NOT give milk, raw eggs, or large quantities of water.',
        '4. Locate the exact container/bottle so doctor knows ingredients and concentration.',
        '5. Call National Poison Control (1800 116 117) or 108 immediately.',
      ],
      warning: 'Inducing vomiting can cause chemical burns to the esophagus and lungs.',
    );
  }

  Widget _buildAnaphylaxisGuide() {
    return _GuideCard(
      title: 'Severe Allergic Reaction (Anaphylaxis)',
      subtitle: 'Sudden reaction to food, medications, or bee/wasp stings.',
      steps: const [
        '1. Check for facial/lip swelling, throat tightness, or wheezing.',
        '2. If an EpiPen / auto-injector is prescribed, inject into outer mid-thigh.',
        '3. Lay the child flat with legs elevated (unless breathing is difficult, then keep seated).',
        '4. Call 108 / 112 immediately.',
      ],
      warning: 'Anaphylaxis progresses quickly; do not wait to see if symptoms improve on their own.',
    );
  }

  Widget _buildBurnsGuide() {
    return _GuideCard(
      title: 'Scalds & Thermal Burns',
      subtitle: 'Hot water, tea/coffee spills, or hot surface contact.',
      steps: const [
        '1. Immediately cool the burn under running room temperature water for 15-20 minutes.',
        '2. Gently remove clothing around the area unless stuck to the skin.',
        '3. Cover loosely with sterile plastic cling wrap or a clean damp cloth.',
        '4. Keep child warm with a blanket around unaffected areas.',
      ],
      warning: 'Never apply ice, toothpaste, turmeric, or butter to a burn.',
    );
  }
}

class _EmergencyDialButton extends StatelessWidget {
  const _EmergencyDialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.warning,
  });

  final String title;
  final String subtitle;
  final List<String> steps;
  final String warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.muted.copyWith(fontSize: 13)),
          const SizedBox(height: 14),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.35),
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.do_not_disturb_on_rounded, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF991B1B),
                    ),
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
