import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'parent_bottom_nav.dart';

class ParentAppointmentsScreen extends ConsumerStatefulWidget {
  const ParentAppointmentsScreen({super.key});

  @override
  ConsumerState<ParentAppointmentsScreen> createState() => _ParentAppointmentsScreenState();
}

class _ParentAppointmentsScreenState extends ConsumerState<ParentAppointmentsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Upcoming', 'Past', 'Cancelled'

  Future<void> _cancelAppointment(BuildContext context, Appointment appt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Appointment?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to cancel the appointment with ${appt.doctorName ?? "the doctor"} on ${fmtDayDate(appt.scheduledAt)} at ${fmtTime(appt.scheduledAt)}?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      ref.read(localAppointmentsProvider.notifier).cancelAppointment(appt.id);
      showToast(context, 'Appointment cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedChildAsync = ref.watch(selectedChildProvider);
    final allChildren = ref.watch(childrenProvider).valueOrNull ?? const [];
    final currentChild = selectedChildAsync.valueOrNull ?? (allChildren.isNotEmpty ? allChildren.first : null);

    if (currentChild == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.go('/parent/home'),
          ),
          title: Text(
            'My Appointments',
            style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
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
                  child: const Icon(Icons.calendar_month_rounded, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('No Child Profile Added', style: AppText.h2),
                const SizedBox(height: 8),
                const Text(
                  'Please add a child profile first to schedule appointments and view consultation history.',
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

    final appointmentsAsync = ref.watch(childAppointmentsProvider(currentChild.id));
    final appointmentsList = appointmentsAsync.valueOrNull ?? [];

    final upcoming = appointmentsList.where((a) => a.isUpcoming && a.status != 'cancelled').toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past = appointmentsList.where((a) => (!a.isUpcoming || a.status == 'completed') && a.status != 'cancelled').toList();
    final cancelled = appointmentsList.where((a) => a.status == 'cancelled').toList();

    List<Appointment> displayedList;
    if (_selectedFilter == 'Upcoming') {
      displayedList = upcoming;
    } else if (_selectedFilter == 'Past') {
      displayedList = past;
    } else if (_selectedFilter == 'Cancelled') {
      displayedList = cancelled;
    } else {
      displayedList = appointmentsList;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/parent/home'),
        ),
        title: Text(
          'My Appointments',
          style: AppText.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
            tooltip: 'Book New Appointment',
            onPressed: () => context.push('/parent/book'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Child Info Header / Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatar_child.png',
                        width: 42,
                        height: 42,
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
                                currentChild.name,
                                style: AppText.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              if (currentChild.bloodGroup != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    currentChild.bloodGroup!,
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${currentChild.age} • ${currentChild.gender[0].toUpperCase()}${currentChild.gender.substring(1)}',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (allChildren.length > 1)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                        tooltip: 'Switch Child',
                        onSelected: (id) => ref.read(selectedChildIdProvider.notifier).state = id,
                        itemBuilder: (context) => allChildren.map((c) {
                          return PopupMenuItem(
                            value: c.id,
                            child: Text(c.name, style: TextStyle(fontWeight: c.id == currentChild.id ? FontWeight.w800 : FontWeight.w500)),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  _filterChip('All', appointmentsList.length),
                  const SizedBox(width: 8),
                  _filterChip('Upcoming', upcoming.length),
                  const SizedBox(width: 8),
                  _filterChip('Past', past.length),
                  const SizedBox(width: 8),
                  _filterChip('Cancelled', cancelled.length),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Appointments List View
            Expanded(
              child: displayedList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.lavender.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'All'
                                  ? 'No Appointments Found'
                                  : 'No $_selectedFilter Appointments',
                              style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Book a consultation with our experienced pediatricians for ${currentChild.name}.',
                              textAlign: TextAlign.center,
                              style: AppText.muted.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => context.push('/parent/book'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Book Appointment Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      itemCount: displayedList.length,
                      itemBuilder: (context, index) {
                        final appt = displayedList[index];
                        final isUpcoming = appt.isUpcoming && appt.status != 'cancelled';
                        final isCancelled = appt.status == 'cancelled';
                        final isCompleted = appt.status == 'completed';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isUpcoming
                                  ? AppColors.primary.withValues(alpha: 0.35)
                                  : AppColors.line,
                              width: isUpcoming ? 1.4 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isUpcoming
                                    ? AppColors.primary.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top status & date row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_available_rounded,
                                          size: 16,
                                          color: isCancelled
                                              ? AppColors.danger
                                              : (isUpcoming ? AppColors.primary : AppColors.mint),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          fmtDayDate(appt.scheduledAt),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: isCancelled ? AppColors.danger : AppColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : (isCompleted
                                                ? AppColors.mint.withValues(alpha: 0.15)
                                                : AppColors.lavender),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isCancelled
                                            ? 'CANCELLED'
                                            : (isCompleted ? 'COMPLETED' : 'CONFIRMED'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isCancelled
                                              ? AppColors.danger
                                              : (isCompleted ? AppColors.mint : AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Doctor & Clinic Info Card
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        appt.doctorAvatar ?? 'assets/images/avatar_doctor.png',
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appt.doctorName ?? 'Pediatric Specialist',
                                            style: AppText.h3.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            appt.specialty ?? 'Pediatric Specialist',
                                            style: AppText.muted.copyWith(fontSize: 12.5),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  appt.clinicName ?? "Pediacare Children's Clinic",
                                                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Live OPD Queue / Token Info Box (if upcoming)
                                if (isUpcoming) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(child: _infoStat('Time Slot', fmtTime(appt.scheduledAt))),
                                        Container(width: 1, height: 26, color: AppColors.line),
                                        Expanded(child: _infoStat('Token No.', '#${appt.tokenNo ?? 4}', highlight: true)),
                                        Container(width: 1, height: 26, color: AppColors.line),
                                        Expanded(child: _infoStat('Now Serving', '#${(appt.tokenNo ?? 4) > 1 ? (appt.tokenNo! - 2) : 1}')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Reason / Chief Complaint
                                if (appt.reason != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.notes_rounded, size: 15, color: AppColors.muted),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            appt.reason!,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Action Buttons
                                if (isUpcoming) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () => _cancelAppointment(context, appt),
                                          child: const Text('Cancel Visit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () {
                                            showToast(context, 'Check-in confirmed. Please arrive 10 min early.');
                                          },
                                          icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                                          label: const Text('Check In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (isCompleted) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => context.push('/parent/records'),
                                      icon: const Icon(Icons.description_outlined, size: 16),
                                      label: const Text('View Prescription & Notes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ParentBottomNav(currentIndex: 1),
    );
  }

  Widget _filterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: AppColors.lavender,
      backgroundColor: Colors.grey.shade50,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppColors.primary : AppColors.ink,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.line,
        ),
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }

  Widget _infoStat(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
