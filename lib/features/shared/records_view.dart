import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

const _categories = <String, (IconData, String)>{
  'report': (Icons.science_outlined, 'Lab report'),
  'prescription': (Icons.receipt_long_outlined, 'Prescription'),
  'vaccine_card': (Icons.vaccines_outlined, 'Vaccine card'),
  'discharge': (Icons.local_hospital_outlined, 'Discharge'),
  'other': (Icons.description_outlined, 'Other'),
};

/// Reports & documents vault for one child (parent and doctor).
class RecordsView extends ConsumerWidget {
  const RecordsView({super.key, required this.childId});

  final String childId;

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length > 10 * 1024 * 1024) {
      if (context.mounted) showToast(context, 'File is larger than 10 MB', error: true);
      return;
    }
    if (!context.mounted) return;

    final meta = await showAppSheet<(String, String)>(
      context,
      builder: (_) => _RecordMetaForm(initialTitle: file.name.replaceAll(RegExp(r'\.[^.]+$'), '')),
    );
    if (meta == null || !context.mounted) return;

    showToast(context, 'Uploading…');
    try {
      await ref.read(healthRepositoryProvider).uploadRecord(
            childId: childId,
            title: meta.$1,
            category: meta.$2,
            fileName: file.name,
            bytes: bytes,
          );
      ref.invalidate(recordsProvider(childId));
      if (context.mounted) showToast(context, 'Report saved');
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  Future<void> _open(BuildContext context, WidgetRef ref, MedicalRecord r) async {
    try {
      final url = await ref.read(healthRepositoryProvider).signedUrl(r.filePath);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, MedicalRecord r) async {
    final ok = await confirmDialog(context,
        title: 'Delete "${r.title}"?',
        message: 'This file will be permanently removed.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    try {
      await ref.read(healthRepositoryProvider).deleteRecord(r);
      ref.invalidate(recordsProvider(childId));
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Only the person who uploaded a file can delete it.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recordsProvider(childId));
    return AsyncValueView<List<MedicalRecord>>(
      value: async,
      onRetry: () => ref.invalidate(recordsProvider(childId)),
      data: (list) => RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () async => ref.invalidate(recordsProvider(childId)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppButton(
              label: 'Upload report or photo',
              icon: Icons.upload_file_rounded,
              kind: AppButtonKind.accent,
              onPressed: () => _upload(context, ref),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'No documents yet',
                  message: 'Keep lab reports, prescriptions and vaccine cards safe in one place.',
                ),
              )
            else
              for (final r in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => _open(context, ref, r),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        IconBadge(icon: (_categories[r.category] ?? _categories['other']!).$1),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: AppText.bodyBold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${(_categories[r.category] ?? _categories['other']!).$2} · ${fmtDate(r.createdAt)}',
                                style: AppText.small,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
                          onSelected: (v) {
                            if (v == 'delete') _delete(context, ref, r);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _RecordMetaForm extends StatefulWidget {
  const _RecordMetaForm({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RecordMetaForm> createState() => _RecordMetaFormState();
}

class _RecordMetaFormState extends State<_RecordMetaForm> {
  late final _title = TextEditingController(text: widget.initialTitle);
  String _category = 'report';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Document details', style: AppText.h1),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 16),
        Text('Type', style: AppText.bodyBold),
        const SizedBox(height: 10),
        ChoiceGroup<String>(
          options: _categories.keys.toList(),
          selected: _category,
          onChanged: (v) => setState(() => _category = v),
          labelOf: (k) => _categories[k]!.$2,
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Save to vault',
          kind: AppButtonKind.accent,
          onPressed: () {
            final t = _title.text.trim();
            if (t.isEmpty) return;
            Navigator.pop(context, (t, _category));
          },
        ),
      ],
    );
  }
}
