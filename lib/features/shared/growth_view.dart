import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

enum _Metric { weight, height, head }

extension on _Metric {
  String get label => switch (this) {
        _Metric.weight => 'Weight',
        _Metric.height => 'Height',
        _Metric.head => 'Head',
      };
  String get unit => this == _Metric.weight ? 'kg' : 'cm';
  double? valueOf(GrowthRecord r) => switch (this) {
        _Metric.weight => r.weightKg,
        _Metric.height => r.heightCm,
        _Metric.head => r.headCm,
      };
}

/// Growth tracker: line chart + latest measurements + history.
class GrowthView extends ConsumerStatefulWidget {
  const GrowthView({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<GrowthView> createState() => _GrowthViewState();
}

class _GrowthViewState extends ConsumerState<GrowthView> {
  _Metric _metric = _Metric.weight;

  void _refresh() {
    ref.invalidate(growthProvider(widget.child.id));
    ref.invalidate(timelineProvider(widget.child.id));
  }

  Future<void> _add() async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => _AddGrowthForm(childId: widget.child.id),
    );
    if (saved == true) _refresh();
  }

  Future<void> _delete(GrowthRecord r) async {
    final ok = await confirmDialog(context,
        title: 'Delete measurement?',
        message: 'Measurement of ${fmtDate(r.measuredOn)} will be removed.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    try {
      await ref.read(healthRepositoryProvider).deleteGrowth(r.id);
      _refresh();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(growthProvider(widget.child.id));
    return AsyncValueView<List<GrowthRecord>>(
      value: async,
      onRetry: _refresh,
      data: (records) {
        final latest = records.isEmpty ? null : records.last;
        double? latestOf(_Metric m) {
          for (final r in records.reversed) {
            final v = m.valueOf(r);
            if (v != null) return v;
          }
          return null;
        }

        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  for (final m in _Metric.values) ...[
                    Expanded(
                      child: _MetricTile(
                        label: m.label,
                        value: latestOf(m),
                        unit: m.unit,
                        selected: _metric == m,
                        onTap: () => setState(() => _metric = m),
                      ),
                    ),
                    if (m != _Metric.head) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.fromLTRB(8, 18, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text('${_metric.label} chart (${_metric.unit})',
                                  style: AppText.h3)),
                          if (latest != null)
                            Text('Last: ${fmtShortDate(latest.measuredOn)}',
                                style: AppText.small),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 230,
                      child: _GrowthChart(
                          dob: widget.child.dob, records: records, metric: _metric),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Text('Age (months / years)', style: AppText.small),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Add measurement',
                icon: Icons.add_rounded,
                kind: AppButtonKind.accent,
                onPressed: _add,
              ),
              const SizedBox(height: 8),
              const SectionHeader('History'),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No measurements recorded yet.',
                      style: AppText.muted, textAlign: TextAlign.center),
                )
              else
                for (final r in records.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fmtDate(r.measuredOn), style: AppText.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (r.weightKg != null) '${numFmt(r.weightKg!)} kg',
                                    if (r.heightCm != null) '${numFmt(r.heightCm!)} cm',
                                    if (r.headCm != null) 'head ${numFmt(r.headCm!)} cm',
                                  ].join('  ·  '),
                                  style: AppText.muted,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.muted),
                            onPressed: () => _delete(r),
                          ),
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
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double? value;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: selected ? AppColors.navy : Colors.white,
      borderColor: selected ? AppColors.navy : AppColors.line,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.small.copyWith(color: selected ? Colors.white70 : AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            value == null ? '-' : numFmt(value!),
            style: AppText.h1.copyWith(color: selected ? Colors.white : AppColors.ink),
          ),
          Text(unit,
              style: AppText.small.copyWith(color: selected ? AppColors.orange : AppColors.muted)),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.dob, required this.records, required this.metric});

  final DateTime dob;
  final List<GrowthRecord> records;
  final _Metric metric;

  static String _xLabel(double months) {
    if (months >= 24) {
      final years = months / 12;
      return years == years.roundToDouble() ? '${years.round()}y' : '${years.toStringAsFixed(1)}y';
    }
    return '${months.round()}m';
  }

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (final r in records)
        if (metric.valueOf(r) != null)
          FlSpot(
            math.max(0, r.measuredOn.difference(dob).inDays / 30.4375),
            metric.valueOf(r)!,
          ),
    ];

    if (spots.isEmpty) {
      return Center(
        child: Text('Add a measurement to see the chart.', style: AppText.muted),
      );
    }

    final xs = spots.map((s) => s.x);
    final ys = spots.map((s) => s.y);
    final minX = math.max(0.0, xs.reduce(math.min) - 1);
    final maxX = xs.reduce(math.max) + 1;
    final yMin = ys.reduce(math.min);
    final yMax = ys.reduce(math.max);
    final pad = math.max((yMax - yMin) * 0.25, 1.0);
    final range = maxX - minX;
    final xInterval = range <= 6 ? 1.0 : (range <= 18 ? 3.0 : (range <= 36 ? 6.0 : 12.0));

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: math.max(0, yMin - pad),
        maxY: yMax + pad,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.line, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(numFmt(v), style: AppText.small, textAlign: TextAlign.right),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_xLabel(v), style: AppText.small),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.navy,
            getTooltipItems: (touched) => [
              for (final s in touched)
                LineTooltipItem(
                  '${numFmt(s.y)} ${metric.unit}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            color: AppColors.orange,
            barWidth: 3.5,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: AppColors.orange,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.orange.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGrowthForm extends ConsumerStatefulWidget {
  const _AddGrowthForm({required this.childId});

  final String childId;

  @override
  ConsumerState<_AddGrowthForm> createState() => _AddGrowthFormState();
}

class _AddGrowthFormState extends ConsumerState<_AddGrowthForm> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _head = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _head.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final w = _parse(_weight), h = _parse(_height), hd = _parse(_head);
    if (w == null && h == null && hd == null) {
      showToast(context, 'Enter at least one measurement', error: true);
      return;
    }
    if ((w != null && (w <= 0 || w > 150)) ||
        (h != null && (h <= 0 || h > 220)) ||
        (hd != null && (hd <= 0 || hd > 70))) {
      showToast(context, 'Please check the values entered', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(healthRepositoryProvider).addGrowth(
            childId: widget.childId,
            measuredOn: _date,
            weightKg: w,
            heightCm: h,
            headCm: hd,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showToast(context, errorMessage(e), error: true);
        setState(() => _saving = false);
      }
    }
  }

  Widget _field(TextEditingController c, String label, String suffix) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add measurement', style: AppText.h1),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final d = await pickDate(context,
                initial: _date, first: DateTime(2000), last: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Date', prefixIcon: Icon(Icons.event_rounded)),
            child: Text(fmtDate(_date), style: AppText.body),
          ),
        ),
        const SizedBox(height: 12),
        _field(_weight, 'Weight', 'kg'),
        const SizedBox(height: 12),
        _field(_height, 'Height / length', 'cm'),
        const SizedBox(height: 12),
        _field(_head, 'Head circumference', 'cm'),
        const SizedBox(height: 20),
        AppButton(label: 'Save', kind: AppButtonKind.accent, loading: _saving, onPressed: _save),
      ],
    );
  }
}
