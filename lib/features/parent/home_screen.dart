import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'parent_bottom_nav.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  int _currentNavIndex = 0;

  void _showChildPicker(BuildContext context) {
    final children = ref.watch(localChildrenProvider);
    final selectedId = ref.watch(selectedChildIdProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Child Profile',
                      style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/parent/add-child');
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Child', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (children.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.child_care_rounded, size: 40, color: AppColors.muted),
                          const SizedBox(height: 8),
                          Text('No child profiles found', style: AppText.h3.copyWith(color: AppColors.ink)),
                          const SizedBox(height: 4),
                          const Text('Add your child to start tracking health records.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  )
                else
                  ...children.map((c) {
                  final isSelected = c.id == selectedId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: AppText.h3.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.primary : AppColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        '${c.age} • ${c.gender[0].toUpperCase()}${c.gender.substring(1)}${c.bloodGroup != null ? ' • ${c.bloodGroup}' : ''}${c.weightKg != null ? ' • ${c.weightKg} kg' : ''}',
                        style: AppText.muted.copyWith(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24)
                          : null,
                      onTap: () {
                        ref.read(selectedChildIdProvider.notifier).state = c.id;
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context, Appointment? upcomingAppt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications & Alerts', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (upcomingAppt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                      child: const Text('1 New', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (upcomingAppt != null)
                _buildNotificationItem(
                  icon: Icons.event_available_rounded,
                  iconColor: AppColors.mint,
                  title: 'Upcoming Consultation',
                  subtitle: '${upcomingAppt.doctorName ?? "Pediatrician Checkup"} is confirmed for ${fmtDayDate(upcomingAppt.scheduledAt)} at ${fmtTime(upcomingAppt.scheduledAt)}.',
                  time: 'Confirmed',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/parent/appointments');
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.muted),
                        const SizedBox(height: 8),
                        Text('No New Notifications', style: AppText.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        const Text('You will be alerted about upcoming visits and vaccine schedules here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
                      Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedChildAsync = ref.watch(selectedChildProvider);
    final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChildAsync.valueOrNull ?? (allChildren.isNotEmpty ? allChildren.first : null);
    final apptsAsync = currentChild != null ? ref.watch(childAppointmentsProvider(currentChild.id)) : null;
    final upcomingAppt = apptsAsync?.valueOrNull?.where((a) => a.isUpcoming).firstOrNull;
    final rxAsync = currentChild != null ? ref.watch(prescriptionsProvider(currentChild.id)) : null;
    final activeRx = rxAsync?.valueOrNull?.firstOrNull;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.ink, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const BrandMark(size: 38, showName: true, light: false),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.ink, size: 24),
                onPressed: () => _showNotificationsSheet(context, upcomingAppt),
              ),
              if (upcomingAppt != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const PediaCareTwinLogo(size: 48),
                  const SizedBox(height: 10),
                  Text(
                    'PediaCare Health',
                    style: AppText.h2.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Parent Portal',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
              title: const Text('Appointments & Visits'),
              subtitle: const Text('Doctor visits, tokens & bookings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/appointments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
              title: const Text('Medicine Tracker'),
              subtitle: const Text('Daily schedules & dose reminders'),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/med-tracker');
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.primary),
              title: const Text('Symptom Checker & Triage'),
              subtitle: const Text('Fever & symptom guide'),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/symptom-checker');
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes_rounded, color: AppColors.primary),
              title: const Text('Development Milestones'),
              subtitle: const Text('CDC / WHO 5-6 Yrs checklist'),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/milestones');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency_outlined, color: AppColors.danger),
              title: const Text('Emergency SOS & First Aid'),
              subtitle: const Text('Hotlines & life-saving guides'),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/emergency');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.switch_account_rounded, color: AppColors.primary),
              title: const Text('Switch to Doctor View'),
              onTap: () {
                Navigator.pop(context);
                context.go('/doctor/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined, color: AppColors.primary),
              title: const Text('Add Another Child'),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/add-child');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                context.go('/choose-role');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello! 👋',
                          style: AppText.h1.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your children's health at a glance.",
                          style: AppText.muted.copyWith(fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Parent profile avatar (Enlarged 3D Illustration)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFE0F2FE),
                      child: Image.asset(
                        'assets/images/parent_family.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Child Selector Card (Dynamic) - Soft Lavender Tint, Rounded, No rigid border
              if (currentChild == null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/parent/add-child'),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Your Child Profile', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 2),
                                const Text('Track vaccinations, growth charts & digital prescriptions', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showChildPicker(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
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
                                    Flexible(
                                      child: Text(
                                        currentChild.name,
                                        style: AppText.h3.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: AppColors.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (currentChild.bloodGroup != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          currentChild.bloodGroup!,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentChild.age} • ${currentChild.gender[0].toUpperCase()}${currentChild.gender.substring(1)}${currentChild.weightKg != null ? ' • ${currentChild.weightKg} kg' : ''}',
                                  style: AppText.muted.copyWith(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Emergency SOS Quick Access Pill
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/parent/emergency'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Emergency SOS & Pediatric First Aid',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFDC2626), size: 13),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Quick Actions Grid (3x2) - 3D PNG Icons Fill The Space Without Rigid Card Elements
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                crossAxisSpacing: 10,
                childAspectRatio: 0.80,
                children: [
                  _QuickActionTile(
                    title: 'Book\nAppointment',
                    imageAsset: 'assets/images/book_appointment.png',
                    onTap: () => context.push('/parent/book'),
                  ),
                  _QuickActionTile(
                    title: 'Medicine\nTracker',
                    imageAsset: 'assets/images/prescription_badge.png',
                    onTap: () => context.push('/parent/med-tracker'),
                  ),
                  _QuickActionTile(
                    title: 'Symptom\nChecker',
                    imageAsset: 'assets/images/teleconsult_badge.png',
                    onTap: () => context.push('/parent/symptom-checker'),
                  ),
                  _QuickActionTile(
                    title: 'Vaccination\nTracker',
                    imageAsset: 'assets/images/vaccination_badge.png',
                    onTap: () => context.push('/parent/vaccines'),
                  ),
                  _QuickActionTile(
                    title: 'Growth &\nMilestones',
                    imageAsset: 'assets/images/growth_badge.png',
                    onTap: () => context.push('/parent/milestones'),
                  ),
                  _QuickActionTile(
                    title: 'Emergency\nHotline',
                    imageAsset: 'assets/images/confirmed_badge.png',
                    onTap: () => context.push('/parent/emergency'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Upcoming Appointment Banner (Clickable to Parent Appointments)
              if (upcomingAppt != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Upcoming Visit',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (upcomingAppt.tokenNo != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Token #${upcomingAppt.tokenNo}',
                                      style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              upcomingAppt.doctorName ?? 'Pediatrician Checkup',
                              style: AppText.h3.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${fmtDayDate(upcomingAppt.scheduledAt)} • ${fmtTime(upcomingAppt.scheduledAt)}',
                              style: AppText.muted.copyWith(fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/parent/appointments'),
                        child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Active Dose Reminder Card (Only when active prescription exists)
              if (activeRx != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Prescription',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeRx.diagnosis?.isNotEmpty == true ? activeRx.diagnosis! : 'Doctor Prescription',
                              style: AppText.h3.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Prescribed by ${activeRx.doctorName ?? "Pediatrician"}',
                              style: AppText.muted.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/parent/med-tracker'),
                        child: const Text('Track', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Next Vaccination Banner Card with 3D Vaccine Asset (Clickable to Vaccine Tracker)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/parent/vaccines'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.lavender, AppColors.mintSoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Immunization',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.mint.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Digital Card',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentChild != null ? 'Vaccine Schedule' : 'Immunization Tracker',
                                style: AppText.h2.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentChild != null
                                    ? 'Tap to check ${currentChild.name}\'s WHO / IAP vaccine milestones'
                                    : 'Add a child profile to track vaccines & due dates',
                                style: AppText.muted.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 3D Syringe & Vaccine graphic (Enlarged)
                        Image.asset(
                          'assets/images/vaccination_badge.png',
                          width: 76,
                          height: 76,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ParentBottomNav(currentIndex: 0),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D PNG Icon filling the space prominently (Enlarged)
              Image.asset(
                imageAsset,
                width: 68,
                height: 68,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyBold.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.2,
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
