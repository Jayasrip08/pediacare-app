import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

enum TokenStatus { serving, waiting, inConsult, completed, noShow }

class OpdToken {
  final int tokenNumber;
  final String patientName;
  final String childAgeGender;
  final String complaint;
  final String appointmentTime;
  final String avatarPath;
  TokenStatus status;

  OpdToken({
    required this.tokenNumber,
    required this.patientName,
    required this.childAgeGender,
    required this.complaint,
    required this.appointmentTime,
    required this.avatarPath,
    this.status = TokenStatus.waiting,
  });
}

class OpdQueueScreen extends StatefulWidget {
  const OpdQueueScreen({super.key});

  @override
  State<OpdQueueScreen> createState() => _OpdQueueScreenState();
}

class _OpdQueueScreenState extends State<OpdQueueScreen> {
  String _clinicStatus = 'Running on Time'; // Running on Time, Delayed 15 mins, On Break

  final List<OpdToken> _queue = [];

  OpdToken? get _currentServing => _queue.where((t) => t.status == TokenStatus.serving || t.status == TokenStatus.inConsult).firstOrNull;
  List<OpdToken> get _waitingList => _queue.where((t) => t.status == TokenStatus.waiting).toList();
  int get _completedCount => _queue.where((t) => t.status == TokenStatus.completed).length;

  void _callNext() {
    final next = _waitingList.firstOrNull;
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more waiting patients in queue!')),
      );
      return;
    }

    setState(() {
      final current = _currentServing;
      if (current != null) {
        current.status = TokenStatus.completed;
      }
      next.status = TokenStatus.serving;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Now Calling: Token #${next.tokenNumber} - ${next.patientName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _markInConsult() {
    final current = _currentServing;
    if (current == null) return;
    setState(() => current.status = TokenStatus.inConsult);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Token #${current.tokenNumber} marked In-Consultation.'),
      ),
    );
  }

  void _markNoShow() {
    final current = _currentServing;
    if (current == null) return;
    setState(() => current.status = TokenStatus.noShow);
    _callNext();
  }

  void _showAddWalkInModal() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final complaintCtrl = TextEditingController();
    String gender = 'Male';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Register Walk-In Patient', style: AppText.h2),
              const SizedBox(height: 4),
              Text('Generates next token in today’s live queue', style: AppText.muted.copyWith(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Child Name',
                  hintText: 'e.g., Aadhavan R',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageCtrl,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        hintText: 'e.g. 5 yrs',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (v) => setModalState(() => gender = v ?? 'Male'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: complaintCtrl,
                decoration: InputDecoration(
                  labelText: 'Chief Complaint',
                  hintText: 'e.g., Acute vomiting, high fever',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final nextTokenNo = _queue.isEmpty ? 1 : ((_queue.map((t) => t.tokenNumber).reduce((a, b) => a > b ? a : b)) + 1);
                    setState(() {
                      _queue.add(
                        OpdToken(
                          tokenNumber: nextTokenNo,
                          patientName: name,
                          childAgeGender: '${ageCtrl.text.trim()} • $gender',
                          complaint: complaintCtrl.text.trim().isEmpty ? 'Walk-in consultation' : complaintCtrl.text.trim(),
                          appointmentTime: 'Walk-in',
                          avatarPath: 'assets/images/avatar_child.png',
                          status: TokenStatus.waiting,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add to Queue & Issue Token', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentServing;

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
          'Live OPD Queue',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 24),
            onPressed: _showAddWalkInModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OPD Summary Stats Bar
              Row(
                children: [
                  Expanded(
                    child: _buildQueueStat('Serving', '#${current?.tokenNumber ?? '--'}', AppColors.primary, AppColors.lavender),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQueueStat('Waiting', '${_waitingList.length}', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQueueStat('Done', '$_completedCount', AppColors.mint, AppColors.mintSoft),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Waiting Room Status Broadcaster Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tv_rounded, color: AppColors.muted, size: 18),
                    const SizedBox(width: 8),
                    const Text('Waiting Room Display: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    DropdownButton<String>(
                      value: _clinicStatus,
                      underline: const SizedBox(),
                      isDense: true,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                      items: const [
                        DropdownMenuItem(value: 'Running on Time', child: Text('Running on Time 🟢')),
                        DropdownMenuItem(value: 'Delayed 15 mins', child: Text('Delayed 15m 🟡')),
                        DropdownMenuItem(value: 'On Short Break', child: Text('On Break ☕')),
                      ],
                      onChanged: (v) => setState(() => _clinicStatus = v ?? 'Running on Time'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Now Serving Big Action Card
              if (current != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3478ED), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  current.status == TokenStatus.inConsult ? 'IN CONSULTATION' : 'NOW SERVING',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            current.appointmentTime,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '#${current.tokenNumber}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.patientName,
                                  style: AppText.h2.copyWith(color: Colors.white, fontSize: 19),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  current.childAgeGender,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Complaint: ${current.complaint}',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF36C6B0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: const Text('Complete & Next', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              onPressed: _callNext,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (current.status == TokenStatus.serving)
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white60),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _markInConsult,
                              child: const Text('In-Consult', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFCA5A5),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _markNoShow,
                            child: const Text('No Show', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
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
                        child: const Icon(Icons.people_outline_rounded, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(height: 10),
                      Text('No Active Consultation', style: AppText.h3.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      const Text('Add a walk-in patient or tap Call Next to start consulting.', style: TextStyle(color: AppColors.muted, fontSize: 12.5), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Waiting Queue Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Waiting Queue (${_waitingList.length})', style: AppText.h2.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: const Text('Call Next', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: _callNext,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_waitingList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No waiting patients! All tokens served.', style: TextStyle(color: AppColors.muted)),
                )
              else
                ..._waitingList.map((token) => _buildQueueTile(token)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueStat(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildQueueTile(OpdToken token) {
    final childId = token.patientName.toLowerCase().replaceAll(' ', '-');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/doctor/patient/$childId'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#${token.tokenNumber}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(token.patientName, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${token.childAgeGender} • ${token.complaint}', style: AppText.muted.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      token.appointmentTime,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
