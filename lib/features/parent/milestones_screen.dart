import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

enum MilestoneStatus { achieved, inProgress, notYet }

class MilestoneItem {
  final String id;
  final String title;
  final String domain; // Gross Motor, Fine Motor, Language, Social/Cognitive
  final String description;
  MilestoneStatus status;

  MilestoneItem({
    required this.id,
    required this.title,
    required this.domain,
    required this.description,
    this.status = MilestoneStatus.achieved,
  });
}

class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen> with SingleTickerProviderStateMixin {
  late final TabController _ageTabController;

  final List<String> _ageStages = ['0-6 Mo', '6-12 Mo', '1-2 Yrs', '3-4 Yrs', '5-6 Yrs'];

  // Milestones for 5-6 Years age bracket
  final List<MilestoneItem> _milestones = [
    MilestoneItem(
      id: 'm1',
      title: 'Hops & stands on one foot',
      domain: 'Gross Motor',
      description: 'Stands on one foot for 10 seconds or longer without losing balance.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm2',
      title: 'Catches a bounced ball',
      domain: 'Gross Motor',
      description: 'Catches a bounced tennis or rubber ball with hands most of the time.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm3',
      title: 'Skips and runs smoothly',
      domain: 'Gross Motor',
      description: 'Coordinates skipping, swinging, and climbing playground structures.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm4',
      title: 'Uses child-safe scissors',
      domain: 'Fine Motor',
      description: 'Cuts paper along curves and simple shapes comfortably.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm5',
      title: 'Draws a person with 6+ body parts',
      domain: 'Fine Motor',
      description: 'Draws head, body, arms, legs, and facial features recognizable to adults.',
      status: MilestoneStatus.inProgress,
    ),
    MilestoneItem(
      id: 'm6',
      title: 'Buttons and unbuttons clothes',
      domain: 'Fine Motor',
      description: 'Able to dress independently and fasten medium-sized buttons.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm7',
      title: 'Tells simple stories in full sentences',
      domain: 'Language',
      description: 'Describes daily school events using past, present, and future tenses.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm8',
      title: 'Knows full name & home address',
      domain: 'Language',
      description: 'Can recite first and last name, parents’ names, and general home location.',
      status: MilestoneStatus.inProgress,
    ),
    MilestoneItem(
      id: 'm9',
      title: 'Plays cooperatively with peers',
      domain: 'Social & Cognitive',
      description: 'Agrees to rules in board/tag games, shares toys, and takes turns.',
      status: MilestoneStatus.achieved,
    ),
    MilestoneItem(
      id: 'm10',
      title: 'Counts 10 or more items correctly',
      domain: 'Social & Cognitive',
      description: 'Can touch and accurately count 10 objects without skipping numbers.',
      status: MilestoneStatus.achieved,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default to '5-6 Yrs' (index 4) as initial reference bracket
    _ageTabController = TabController(length: _ageStages.length, initialIndex: 4, vsync: this);
  }

  @override
  void dispose() {
    _ageTabController.dispose();
    super.dispose();
  }

  int get _achievedCount => _milestones.where((m) => m.status == MilestoneStatus.achieved).length;
  double get _progress => _milestones.isEmpty ? 0 : _achievedCount / _milestones.length;

  void _cycleStatus(MilestoneItem item) {
    setState(() {
      if (item.status == MilestoneStatus.achieved) {
        item.status = MilestoneStatus.inProgress;
      } else if (item.status == MilestoneStatus.inProgress) {
        item.status = MilestoneStatus.notYet;
      } else {
        item.status = MilestoneStatus.achieved;
      }
    });
  }

  void _showShareSummary() {
    final selectedChild = ref.read(selectedChildProvider).valueOrNull;
    final allChildren = ref.read(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChild ?? (allChildren.isNotEmpty ? allChildren.first : null);
    final pediatrician = currentChild?.pediatrician ?? 'Pediatrician';

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
            Row(
              children: [
                const Icon(Icons.share_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Milestone Summary for Doctor', style: AppText.h2),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              currentChild != null
                  ? '${currentChild.name} (${currentChild.age}) has completed $_achievedCount of ${_milestones.length} milestones for this age bracket.'
                  : 'Completed $_achievedCount of ${_milestones.length} milestones for this age bracket.',
              style: AppText.muted.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lavender.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Gross Motor Skills', '3 / 3 (100%)', Colors.teal.shade700),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Fine Motor Skills', '2 / 3 (67%)', AppColors.primary),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Language & Speech', '1 / 2 (50%)', const Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Social & Cognitive', '2 / 2 (100%)', Colors.teal.shade700),
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
                label: Text('Send to $pediatrician', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0F766E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Text(
                        'Milestone summary shared with $pediatrician for upcoming visit!',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
      ],
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
          'Development Milestones',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
            onPressed: _showShareSummary,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _ageTabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _ageStages.map((stage) => Tab(text: stage)).toList(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Profile Card
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
                              Text(
                                currentChild?.name ?? 'No Child Selected',
                                style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              if (currentChild != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    currentChild.age,
                                    style: const TextStyle(
                                      color: AppColors.primary,
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
                                ? 'WHO / CDC Developmental Checklist (${currentChild.age})'
                                : 'Add a child profile to track developmental milestones',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Progress Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF36C6B0), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
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
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stage Progress',
                            style: AppText.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_achievedCount of ${_milestones.length} milestones achieved!',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap any milestone to update status',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Milestones List by Domain
              ..._buildDomainSection('Gross Motor Skills', Icons.directions_run_rounded, AppColors.primary),
              ..._buildDomainSection('Fine Motor & Self-Care', Icons.edit_note_rounded, const Color(0xFFF59E0B)),
              ..._buildDomainSection('Language & Communication', Icons.record_voice_over_rounded, const Color(0xFF8B5CF6)),
              ..._buildDomainSection('Social & Cognitive', Icons.psychology_rounded, AppColors.mint),

              const SizedBox(height: 10),

              // Pediatric Tip Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pediatrician Note on Milestones',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Every child develops at their own pace. If a skill is in progress, practice together through play. Discuss any persistent delay with your pediatrician during routine visits.',
                            style: AppText.muted.copyWith(fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDomainSection(String domainName, IconData icon, Color color) {
    final domainItems = _milestones.where((m) => m.domain.contains(domainName.split(' ')[0])).toList();
    if (domainItems.isEmpty) return [];

    return [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Text(domainName, style: AppText.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
      const SizedBox(height: 10),
      ...domainItems.map((item) => _MilestoneCard(
            item: item,
            onTap: () => _cycleStatus(item),
          )),
      const SizedBox(height: 16),
    ];
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.item, required this.onTap});

  final MilestoneItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (item.status) {
      case MilestoneStatus.achieved:
        badgeColor = const Color(0xFF0F766E);
        badgeText = 'Achieved';
        badgeIcon = Icons.check_circle_rounded;
        break;
      case MilestoneStatus.inProgress:
        badgeColor = const Color(0xFFD97706);
        badgeText = 'In Progress';
        badgeIcon = Icons.access_time_rounded;
        break;
      case MilestoneStatus.notYet:
        badgeColor = AppColors.muted;
        badgeText = 'Not Yet';
        badgeIcon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(badgeIcon, color: badgeColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppText.bodyBold.copyWith(
                          fontSize: 14,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: AppText.muted.copyWith(fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
