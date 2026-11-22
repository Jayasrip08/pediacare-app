import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class SelectDoctorScreen extends ConsumerStatefulWidget {
  const SelectDoctorScreen({super.key, this.department = 'Pediatrics'});

  final String department;

  @override
  ConsumerState<SelectDoctorScreen> createState() => _SelectDoctorScreenState();
}

class _SelectDoctorScreenState extends ConsumerState<SelectDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  List<_DoctorInfo> _getDoctors() {
    final docs = ref.watch(doctorAccountsProvider);
    return docs
        .map((d) => _DoctorInfo(
              id: d.id,
              name: d.name,
              specialty: d.specialty,
              rating: 4.9,
              reviewCount: 120,
              avatarPath: d.avatarPath,
            ))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Select Doctor',
          style: AppText.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search doctor...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                      size: 22,
                    ),
                    suffixIcon: Icon(
                      Icons.tune_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Doctor List
            Expanded(
              child: Builder(builder: (context) {
                final doctors = _getDoctors();
                if (doctors.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.lavender.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 34),
                          ),
                          const SizedBox(height: 16),
                          Text('No Doctors Registered Yet', style: AppText.h3.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            'When doctors register their clinic practice, they will appear here for consultation booking.',
                            textAlign: TextAlign.center,
                            style: AppText.muted.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    final isSelected = index == _selectedIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = index),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.line,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar (Prominent 3D PNG)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  doc.avatarPath,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Doctor details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.name,
                                      style: AppText.h3.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      doc.specialty,
                                      style: AppText.muted.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFF59E0B),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${doc.rating}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${doc.reviewCount} reviews)',
                                          style: AppText.small.copyWith(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Chevron
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Bottom Continue Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final doctors = _getDoctors();
                  if (doctors.isEmpty) {
                    showToast(context, 'No doctors available', error: true);
                    return;
                  }
                  final safeIndex = _selectedIndex < doctors.length ? _selectedIndex : 0;
                  final selectedDoc = doctors[safeIndex];
                  final selectedChild = ref.read(selectedChildProvider).valueOrNull ??
                      (ref.read(localChildrenProvider).isNotEmpty ? ref.read(localChildrenProvider).first : null);

                  if (selectedChild == null) {
                    showToast(context, 'Please add a child profile first', error: true);
                    context.push('/parent/add-child');
                    return;
                  }

                  final docId = selectedDoc.id;
                  final clinic = ref.read(localClinicsProvider)[docId];
                  final clinicName = clinic?.name ?? "PediaCare Specialty Clinic";

                  // Save new appointment in parent appointments state
                  final newAppt = Appointment(
                    id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
                    clinicId: clinic?.id ?? 'clinic_$docId',
                    childId: selectedChild.id,
                    childName: selectedChild.name,
                    doctorName: selectedDoc.name,
                    specialty: selectedDoc.specialty,
                    doctorAvatar: selectedDoc.avatarPath,
                    clinicName: clinicName,
                    scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
                    status: 'booked',
                    tokenNo: 7,
                    reason: '${widget.department} Consultation',
                    symptoms: 'Scheduled online by parent',
                  );
                  ref.read(localAppointmentsProvider.notifier).addAppointment(newAppt);

                    // Sync to doctor's assigned patients roster
                    final newDocPatient = DoctorPatient(
                      id: selectedChild.id,
                      name: selectedChild.name,
                      ageDisplay: selectedChild.age,
                      condition: '${widget.department} Consultation',
                      time: '11:00 AM',
                      avatarPath: 'assets/images/avatar_child.png',
                      gender: selectedChild.gender,
                      bloodGroup: selectedChild.bloodGroup,
                      weightKg: selectedChild.weightKg,
                      status: 'Scheduled',
                      lastVisit: DateTime.now(),
                    );
                    ref.read(doctorPatientsProvider.notifier).addPatientToDoctor(docId, newDocPatient);

                    context.push(
                      '/parent/appointment-confirmed?doc=${Uri.encodeComponent(selectedDoc.name)}&spec=${Uri.encodeComponent(selectedDoc.specialty)}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInfo {
  const _DoctorInfo({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.avatarPath,
  });

  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String avatarPath;
}
