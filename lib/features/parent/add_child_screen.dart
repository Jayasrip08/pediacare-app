import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _allergies = TextEditingController();
  DateTime? _dob;
  String _gender = 'male';
  String? _blood;
  bool _consent = false;
  bool _saving = false;

  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  @override
  void dispose() {
    _name.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      showToast(context, 'Please select date of birth', error: true);
      return;
    }
    if (!_consent) {
      showToast(context, 'Parental consent is required to continue',
          error: true);
      return;
    }
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final child = await ref.read(healthRepositoryProvider).addChild(
            parentId: uid,
            name: _name.text,
            dob: _dob!,
            gender: _gender,
            bloodGroup: _blood,
            allergies: _allergies.text,
          );
      ref.invalidate(childrenProvider);
      ref.read(selectedChildIdProvider.notifier).state = child.id;
      if (mounted) {
        context.pop();
        showToast(context, 'Vaccine schedule created for ${child.name}');
      }
    } catch (e) {
      if (mounted) {
        showToast(context, errorMessage(e), error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Add child profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            color: AppColors.bg,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Child’s name',
                  prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter child’s name' : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final d = await pickDate(
                  context,
                  initial: _dob ?? DateTime.now(),
                  first:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
                  last: DateTime.now(),
                );
                if (d != null) setState(() => _dob = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date of birth',
                    prefixIcon: Icon(Icons.calendar_today_rounded)),
                child: Text(
                  _dob == null
                      ? 'Select date'
                      : '${fmtDate(_dob!)}  (${ageLabel(_dob!)})',
                  style: _dob == null ? AppText.muted : AppText.body,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Gender', style: AppText.bodyBold),
            const SizedBox(height: 10),
            ChoiceGroup<String>(
              options: const ['male', 'female', 'other'],
              selected: _gender,
              onChanged: (v) => setState(() => _gender = v),
              labelOf: (v) => v[0].toUpperCase() + v.substring(1),
            ),
            const SizedBox(height: 20),
            Text('Blood group (optional)', style: AppText.bodyBold),
            const SizedBox(height: 10),
            ChoiceGroup<String>(
              options: _bloodGroups,
              selected: _blood,
              onChanged: (v) => setState(() => _blood = _blood == v ? null : v),
              labelOf: (v) => v,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _allergies,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Known allergies (optional)',
                prefixIcon: Icon(Icons.info_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              color: AppColors.orangeSoft,
              borderColor: AppColors.line,
              shadow: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                activeColor: AppColors.navy,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I am the parent / legal guardian and I consent to storing this child’s '
                  'health data and sharing it with my chosen clinic (DPDP Act, 2023).',
                  style: AppText.small.copyWith(color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
                label: 'Create profile',
                kind: AppButtonKind.primary,
                loading: _saving,
                onPressed: _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
