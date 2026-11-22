import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class OpdAnalyticsScreen extends StatefulWidget {
  const OpdAnalyticsScreen({super.key});

  @override
  State<OpdAnalyticsScreen> createState() => _OpdAnalyticsScreenState();
}

class _OpdAnalyticsScreenState extends State<OpdAnalyticsScreen> {
  String _selectedPeriod = 'This Month';

  final List<String> _periods = ['Today', 'This Week', 'This Month', '2026'];

  final List<_DiagnosisStat> _diagnoses = const [
    _DiagnosisStat(
      name: 'Upper Respiratory Infection (URTI)',
      count: 184,
      percentage: 0.38,
      color: AppColors.primary,
    ),
    _DiagnosisStat(
      name: 'Acute Viral Gastroenteritis',
      count: 106,
      percentage: 0.22,
      color: Color(0xFFF59E0B),
    ),
    _DiagnosisStat(
      name: 'Asthma & Reactive Airway Disease',
      count: 78,
      percentage: 0.16,
      color: Color(0xFF8B5CF6),
    ),
    _DiagnosisStat(
      name: 'Allergic Rhinitis & Eczema',
      count: 67,
      percentage: 0.14,
      color: Color(0xFFEC4899),
    ),
    _DiagnosisStat(
      name: 'Acute Otitis Media (Ear Infection)',
      count: 47,
      percentage: 0.10,
      color: AppColors.mint,
    ),
  ];

  final List<int> _weeklyVisits = [24, 28, 32, 26, 30, 36, 14];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
          'Clinical OPD Analytics',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _periods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final isSelected = _selectedPeriod == _periods[i];
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(_periods[i]),
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF8FAFC),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.ink,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => setState(() => _selectedPeriod = _periods[i]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Overview KPI Cards Grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      label: 'Total Consults',
                      value: '482',
                      trend: '+14% vs last mo',
                      icon: Icons.people_outline_rounded,
                      color: AppColors.primary,
                      bg: AppColors.lavender,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      label: 'Avg Consult Time',
                      value: '11.2 min',
                      trend: 'Optimal flow',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF8B5CF6),
                      bg: AppColors.lavender,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      label: 'Vaccine Adherence',
                      value: '94.2%',
                      trend: 'High compliance',
                      icon: Icons.verified_outlined,
                      color: AppColors.mint,
                      bg: AppColors.mintSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      label: 'Parent Rating',
                      value: '4.9 ★',
                      trend: '198 reviews',
                      icon: Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      bg: const Color(0xFFFEF3C7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Volume Trend Bar Chart
              Text('Weekly Consultation Volume', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Total 190 patients evaluated this week', style: AppText.muted.copyWith(fontSize: 12.5)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_weeklyVisits.length, (i) {
                    final count = _weeklyVisits[i];
                    final max = 40.0;
                    final height = (count / max) * 110.0;
                    final isPeak = count >= 36;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isPeak ? AppColors.primary : AppColors.muted)),
                        const SizedBox(height: 6),
                        Container(
                          width: 24,
                          height: height,
                          decoration: BoxDecoration(
                            color: isPeak ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_weekDays[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Top Diagnoses Breakdown
              Text('Top Clinical Diagnoses (Epidemiology)', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              ..._diagnoses.map((d) => _buildDiagnosisProgressRow(d)),
              const SizedBox(height: 24),

              // Clinic Peak Hours Insight Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: Color(0xFF0F766E), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OPD Surge Windows',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Peak inflow occurs between 10:00 AM – 12:30 PM (Morning) and 05:00 PM – 07:30 PM (Evening). Walk-ins advised during 02:00 PM – 04:00 PM slot.',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF0F766E).withValues(alpha: 0.9), height: 1.35),
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

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String trend,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppText.h1.copyWith(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(trend, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildDiagnosisProgressRow(_DiagnosisStat d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
              Text('${d.count} cases (${(d.percentage * 100).toInt()}%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: d.color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: d.percentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(d.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisStat {
  const _DiagnosisStat({
    required this.name,
    required this.count,
    required this.percentage,
    required this.color,
  });

  final String name;
  final int count;
  final double percentage;
  final Color color;
}
