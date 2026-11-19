import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'prescription_pdf.dart';

class PrescriptionScreen extends ConsumerWidget {
  const PrescriptionScreen({super.key, required this.id});

  final String id;

  String _summary(Prescription p) {
    final b = StringBuffer()
      ..writeln('${p.clinicName ?? 'Clinic'} - Prescription')
      ..writeln('Patient: ${p.childName ?? ''} (${numFmt(p.weightKg)} kg)')
      ..writeln('Date: ${fmtDate(p.createdAt)}');
    if (p.diagnosis != null) b.writeln('Diagnosis: ${p.diagnosis}');
    b.writeln();
    for (final i in p.items) {
      b.writeln('- ${i.name}: ${i.doseLabel}, ${i.scheduleLabel}');
      if (i.instructions != null && i.instructions!.isNotEmpty) b.writeln('  ${i.instructions}');
    }
    if (p.followUpDate != null) b.writeln('\nReview on: ${fmtDate(p.followUpDate!)}');
    if (p.notes != null) b.writeln('Advice: ${p.notes}');
    return b.toString();
  }

  Future<void> _sharePdf(BuildContext context, Prescription p) async {
    try {
      final bytes = await buildPrescriptionPdf(p);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'prescription_${safeFile(p.childName)}_${toDbDate(p.createdAt)}.pdf',
      );
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  Future<void> _print(BuildContext context, Prescription p) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => buildPrescriptionPdf(p));
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  Future<void> _whatsApp(BuildContext context, Prescription p) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_summary(p))}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) showToast(context, 'Could not open WhatsApp', error: true);
    }
  }

  static String safeFile(String? s) =>
      (s ?? 'child').replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
        actions: [
          if (async.hasValue)
            IconButton(
              tooltip: 'Print',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _print(context, async.requireValue),
            ),
        ],
      ),
      body: AsyncValueView<Prescription>(
        value: async,
        onRetry: () => ref.invalidate(prescriptionProvider(id)),
        data: (p) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            AppCard(
              color: AppColors.navy,
              borderColor: AppColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.clinicName ?? 'Clinic', style: AppText.h1.copyWith(color: Colors.white)),
                  if (p.clinicAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(p.clinicAddress!, style: AppText.small.copyWith(color: Colors.white70)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.doctorName ?? 'Doctor',
                            style: AppText.bodyBold.copyWith(color: Colors.white)),
                      ),
                      Text(fmtDate(p.createdAt),
                          style: AppText.small.copyWith(color: AppColors.orange)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  InfoRow('Patient', p.childName ?? '-'),
                  if (p.childDob != null) InfoRow('Age', ageLabel(p.childDob!, p.createdAt)),
                  InfoRow('Weight', '${numFmt(p.weightKg)} kg'),
                  if (p.diagnosis != null) InfoRow('Diagnosis', p.diagnosis!),
                ],
              ),
            ),
            const SectionHeader('Medicines'),
            for (final i in p.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBadge(icon: Icons.medication_liquid_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.name, style: AppText.h3),
                            const SizedBox(height: 4),
                            Text(i.doseLabel, style: AppText.bodyBold.copyWith(color: AppColors.orange)),
                            const SizedBox(height: 2),
                            Text(i.scheduleLabel, style: AppText.muted),
                            if (i.instructions != null && i.instructions!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(i.instructions!, style: AppText.small),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (p.followUpDate != null)
              AppCard(
                color: AppColors.orangeSoft,
                borderColor: AppColors.orangeSoft,
                shadow: false,
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, color: AppColors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'Review on ${fmtDate(p.followUpDate!)} (${relativeDays(p.followUpDate!)})',
                          style: AppText.bodyBold),
                    ),
                  ],
                ),
              ),
            if (p.notes != null) ...[
              const SectionHeader('Doctor’s advice'),
              AppCard(child: Text(p.notes!, style: AppText.body)),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: 'Download / share PDF',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: () => _sharePdf(context, p),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Send on WhatsApp',
              icon: Icons.send_rounded,
              kind: AppButtonKind.outline,
              onPressed: () => _whatsApp(context, p),
            ),
            const SizedBox(height: 16),
            Text(
              'Doses are confirmed by the prescribing doctor. Do not change the dose without consulting your doctor.',
              style: AppText.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
