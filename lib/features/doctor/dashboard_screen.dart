import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'doctor_bottom_nav.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int _currentNavIndex = 0;

  void _showDoctorAlertsSheet(BuildContext context) {
    final patients = ref.read(currentDoctorPatientsProvider);
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
                  Text('Doctor Clinical Alerts', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (patients.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${patients.length} Active', style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (patients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.muted),
                        const SizedBox(height: 8),
                        Text('No Active Clinical Alerts', style: AppText.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        const Text('Patient check-ins, appointments, and cold-chain updates will appear here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildAlertItem(
                  icon: Icons.person_pin_circle_outlined,
                  iconColor: AppColors.primary,
                  title: 'Patient Consultations',
                  subtitle: '${patients.first.name} (${patients.first.ageGender}) in patient roster.',
                  time: 'Active',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/doctor/patients');
                  },
                ),
                const SizedBox(height: 10),
                _buildAlertItem(
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.amber.shade700,
                  title: 'Vaccine Inventory & Cold Chain',
                  subtitle: 'Monitor vaccine stocks and cold-chain temperature unit.',
                  time: 'Active',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/doctor/inventory');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertItem({
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
    final currentDoc = ref.watch(currentDoctorAccountProvider);
    final clinic = ref.watch(myClinicProvider).valueOrNull;
    final docPatients = ref.watch(currentDoctorPatientsProvider);

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
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 24),
                onPressed: () => _showDoctorAlertsSheet(context),
              ),
              if (docPatients.isNotEmpty)
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
              decoration: const BoxDecoration(color: Color(0xFF7C3AED)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          currentDoc.avatarPath,
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
                            Text(
                              currentDoc.name,
                              style: AppText.h2.copyWith(color: Colors.white, fontSize: 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentDoc.specialty,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'RBAC DOCTOR • ${currentDoc.regNo}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
              title: const Text('My Clinic Practice'),
              subtitle: Text(clinic != null ? clinic.name : 'Setup Clinic Practice'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/clinic');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
              title: const Text('Appointments & Consultations'),
              subtitle: Text('${docPatients.length} visits scheduled'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/appointments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
              title: const Text('Assigned Patients'),
              subtitle: Text('${docPatients.length} patients registered'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/patients');
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_play_next_rounded, color: AppColors.primary),
              title: const Text('Live OPD Queue'),
              subtitle: const Text('Tokens & waiting room management'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/queue');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined, color: Color(0xFFDC2626)),
              title: const Text('Pediatric Dose & Resus Calc'),
              subtitle: const Text('Emergency drugs & Holliday-Segar fluids'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/calc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: AppColors.mint),
              title: const Text('Vaccine Stock & Cold Chain'),
              subtitle: const Text('Batch tracking & clinic refrigerator sensor'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/inventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: Color(0xFF8B5CF6)),
              title: const Text('Clinical OPD Analytics'),
              subtitle: const Text('Epidemiology & diagnosis trends'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined, color: Color(0xFFF59E0B)),
              title: const Text('Lab & Referral Orders'),
              subtitle: const Text('STAT panels & sub-specialist letters'),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/orders');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () {
                ref.read(currentUserRoleProvider.notifier).state = null;
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
                          'Welcome, ${currentDoc.name} 👋',
                          style: AppText.h1.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          clinic != null ? clinic.name : 'Setup Clinic Practice to Accept Bookings',
                          style: AppText.muted.copyWith(
                            fontSize: 13,
                            color: clinic != null ? AppColors.muted : const Color(0xFFD97706),
                            fontWeight: clinic != null ? FontWeight.normal : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFEDE9FE),
                      child: Image.asset(
                        currentDoc.avatarPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CLINIC ALERT BANNER IF NOT CONFIGURED
              if (clinic == null) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/doctor/clinic'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clinic Practice Not Registered',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 13),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap here to add your clinic name, hours & departments.',
                                  style: TextStyle(color: Color(0xFFB45309), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB45309), size: 13),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Live OPD Queue Active Banner
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/doctor/queue'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3478ED), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              docPatients.isNotEmpty ? '#1' : 'OPD',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
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
                                  const Text(
                                    'NOW SERVING • Live Queue',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${docPatients.length} In Queue',
                                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                docPatients.isNotEmpty
                                    ? '${docPatients.first.name} (${docPatients.first.ageDisplay} • ${docPatients.first.condition})'
                                    : 'No active patient waiting in queue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 4 Stat Cards Grid (2x2) Scoped to this Doctor
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: "Today's Visits",
                      value: '${docPatients.length}',
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.primary,
                      bgColor: AppColors.lavender,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      label: 'Upcoming',
                      value: '${docPatients.length * 2}',
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      bgColor: AppColors.lavender,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Assigned Patients',
                      value: '${docPatients.length}',
                      icon: Icons.people_outline_rounded,
                      iconColor: AppColors.primary,
                      bgColor: AppColors.lavender,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      label: 'Follow-ups',
                      value: '${docPatients.isNotEmpty ? 4 : 0}',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.mint,
                      bgColor: AppColors.mintSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Doctor Clinical Modules Grid (3x2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Clinical Tools & Modules',
                    style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _ToolTile(
                    title: 'Live OPD\nQueue',
                    icon: Icons.queue_play_next_rounded,
                    color: AppColors.primary,
                    bg: AppColors.lavender,
                    onTap: () => context.push('/doctor/queue'),
                  ),
                  _ToolTile(
                    title: 'Dose & Resus\nCalc',
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEE2E2),
                    onTap: () => context.push('/doctor/calc'),
                  ),
                  _ToolTile(
                    title: 'Vaccine Stock\n& Sensor',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.mint,
                    bg: AppColors.mintSoft,
                    onTap: () => context.push('/doctor/inventory'),
                  ),
                  _ToolTile(
                    title: 'OPD\nAnalytics',
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF8B5CF6),
                    bg: AppColors.lavender,
                    onTap: () => context.push('/doctor/analytics'),
                  ),
                  _ToolTile(
                    title: 'Lab & Referral\nOrders',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFFF59E0B),
                    bg: const Color(0xFFFEF3C7),
                    onTap: () => context.push('/doctor/orders'),
                  ),
                  _ToolTile(
                    title: 'Patient\nDirectory',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF0EA5E9),
                    bg: const Color(0xFFE0F2FE),
                    onTap: () => context.push('/doctor/patients'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Appointments Section (Scoped to active doctor)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Appointments (${docPatients.length})",
                    style: AppText.h2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/doctor/appointments'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Appointment List
              if (docPatients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_available_rounded, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Scheduled Patients for ${currentDoc.name}',
                        style: AppText.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This doctor currently has 0 assigned patients. Parents who scan your Clinic QR code will appear here.',
                        style: AppText.muted.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/doctor/clinic'),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('View Clinic QR Code', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              else
                ...docPatients.map((appt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/doctor/patient/${appt.id}'),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  appt.avatarPath,
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
                                    Text(
                                      appt.name,
                                      style: AppText.h3.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${appt.ageDisplay} • ${appt.condition}',
                                      style: AppText.muted.copyWith(fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.lavender.withValues(alpha: 0.5),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppText.h2.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: AppText.muted.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
