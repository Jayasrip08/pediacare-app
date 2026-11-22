import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String _selectedDept = 'Pediatrics';

  final List<_DepartmentItem> _departments = const [
    _DepartmentItem(
      title: 'Pediatrics',
      subtitle: 'General child health & wellness',
      icon: Icons.child_care_rounded,
      iconColor: AppColors.primary,
      bgColor: AppColors.lavender,
    ),
    _DepartmentItem(
      title: 'Pediatric Cardiology',
      subtitle: 'Heart care for children',
      icon: Icons.favorite_rounded,
      iconColor: Color(0xFFEC4899),
      bgColor: Color(0xFFFCE7F3),
    ),
    _DepartmentItem(
      title: 'Pediatric Neurology',
      subtitle: 'Brain & nervous system care',
      icon: Icons.psychology_rounded,
      iconColor: Color(0xFF8B5CF6),
      bgColor: AppColors.lavender,
    ),
    _DepartmentItem(
      title: 'Pediatric Orthopedics',
      subtitle: 'Bone, joint & growth concerns',
      icon: Icons.healing_rounded,
      iconColor: Color(0xFFF59E0B),
      bgColor: Color(0xFFFEF3C7),
    ),
    _DepartmentItem(
      title: 'Pediatric ENT',
      subtitle: 'Ear, nose & throat care',
      icon: Icons.add_circle_outline_rounded,
      iconColor: AppColors.mint,
      bgColor: AppColors.mintSoft,
    ),
  ];

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
          'Book Appointment',
          style: AppText.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Dropdown selector card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Department',
                    style: AppText.bodyBold.copyWith(
                      color: AppColors.ink,
                      fontSize: 15,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Department items
            ..._departments.map((dept) {
              final isSelected = dept.title == _selectedDept;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedDept = dept.title);
                      context.push('/parent/select-doctor?dept=${Uri.encodeComponent(dept.title)}');
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.line.withValues(alpha: 0.7),
                          width: isSelected ? 1.5 : 1.0,
                        ),
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
                          // Round Icon Badge
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: dept.bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              dept.icon,
                              color: dept.iconColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dept.title,
                                  style: AppText.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  dept.subtitle,
                                  style: AppText.muted.copyWith(fontSize: 12.5),
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
            }),
          ],
        ),
      ),
    );
  }
}

class _DepartmentItem {
  const _DepartmentItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}
