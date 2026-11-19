import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils.dart';
import 'data/appointment_repository.dart';
import 'data/auth_repository.dart';
import 'data/chat_repository.dart';
import 'data/clinic_repository.dart';
import 'data/department_repository.dart';
import 'data/health_repository.dart';
import 'data/prescription_repository.dart';
import 'models/models.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepositoryProvider =
    Provider((ref) => AuthRepository(ref.watch(supabaseProvider)));
final healthRepositoryProvider =
    Provider((ref) => HealthRepository(ref.watch(supabaseProvider)));
final clinicRepositoryProvider =
    Provider((ref) => ClinicRepository(ref.watch(supabaseProvider)));
final appointmentRepositoryProvider =
    Provider((ref) => AppointmentRepository(ref.watch(supabaseProvider)));
final prescriptionRepositoryProvider =
    Provider((ref) => PrescriptionRepository(ref.watch(supabaseProvider)));
final chatRepositoryProvider =
    Provider((ref) => ChatRepository(ref.watch(supabaseProvider)));
final departmentRepositoryProvider =
    Provider((ref) => DepartmentRepository(ref.watch(supabaseProvider)));

// ---------------------------------------------------------------------------
// Auth + profile
// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<AuthState>(
    (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange);

/// Stable id of the signed-in user (does not change on token refresh).
final userIdProvider = Provider<String?>((ref) {
  final fromEvent = ref.watch(authStateProvider).valueOrNull?.session?.user.id;
  return fromEvent ?? ref.watch(supabaseProvider).auth.currentUser?.id;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return null;
  return ref.watch(authRepositoryProvider).fetchProfile(uid);
});

// ---------------------------------------------------------------------------
// Parent: children + selection
// ---------------------------------------------------------------------------
final childrenProvider = FutureProvider<List<Child>>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return [];
  return ref.watch(healthRepositoryProvider).myChildren(uid);
});

final selectedChildIdProvider = StateProvider<String?>((ref) => null);

final selectedChildProvider = Provider<AsyncValue<Child?>>((ref) {
  final children = ref.watch(childrenProvider);
  final id = ref.watch(selectedChildIdProvider);
  return children.whenData((list) {
    if (list.isEmpty) return null;
    return list.firstWhere((c) => c.id == id, orElse: () => list.first);
  });
});

// ---------------------------------------------------------------------------
// Per-child data (used by parent AND doctor screens)
// ---------------------------------------------------------------------------
final childByIdProvider = FutureProvider.autoDispose.family<Child, String>(
    (ref, childId) => ref.watch(healthRepositoryProvider).childById(childId));

final vaccinesProvider = FutureProvider.autoDispose.family<List<ChildVaccine>, String>(
    (ref, childId) => ref.watch(healthRepositoryProvider).vaccines(childId));

final growthProvider = FutureProvider.autoDispose.family<List<GrowthRecord>, String>(
    (ref, childId) => ref.watch(healthRepositoryProvider).growth(childId));

final recordsProvider = FutureProvider.autoDispose.family<List<MedicalRecord>, String>(
    (ref, childId) => ref.watch(healthRepositoryProvider).records(childId));

final prescriptionsProvider = FutureProvider.autoDispose.family<List<Prescription>, String>(
    (ref, childId) => ref.watch(prescriptionRepositoryProvider).forChild(childId));

final prescriptionProvider = FutureProvider.autoDispose.family<Prescription, String>(
    (ref, id) => ref.watch(prescriptionRepositoryProvider).byId(id));

final childAppointmentsProvider = FutureProvider.autoDispose.family<List<Appointment>, String>(
    (ref, childId) => ref.watch(appointmentRepositoryProvider).forChild(childId));

final childClinicProvider = FutureProvider.autoDispose.family<Clinic?, String>(
    (ref, childId) => ref.watch(clinicRepositoryProvider).clinicOfChild(childId));

final unreadFromDoctorProvider = FutureProvider.autoDispose.family<int, String>(
    (ref, childId) => ref.watch(chatRepositoryProvider).unreadFromDoctor(childId));

final signedUrlProvider = FutureProvider.autoDispose.family<String, String>(
    (ref, path) => ref.watch(healthRepositoryProvider).signedUrl(path));

/// Live queue position for a parent's appointment (polled every 15 s).
final queueStatusProvider =
    StreamProvider.autoDispose.family<QueueStatus?, String>((ref, appointmentId) async* {
  final repo = ref.watch(appointmentRepositoryProvider);
  while (true) {
    try {
      yield await repo.queueStatus(appointmentId);
    } catch (_) {
      yield null;
    }
    await Future<void>.delayed(const Duration(seconds: 15));
  }
});

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------
final messagesProvider = StreamProvider.autoDispose.family<List<Message>, ChatKey>(
    (ref, key) => ref.watch(chatRepositoryProvider).messages(key));

// ---------------------------------------------------------------------------
// Doctor
// ---------------------------------------------------------------------------
final myClinicProvider = FutureProvider<Clinic?>((ref) async {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return null;
  return ref.watch(clinicRepositoryProvider).myClinic(uid);
});

Future<Clinic> _requireClinic(Ref ref) async {
  final clinic = await ref.watch(myClinicProvider.future);
  if (clinic == null) throw Exception('No clinic is linked to this account.');
  return clinic;
}

final doctorStatsProvider = FutureProvider.autoDispose<DoctorStats>((ref) async {
  final clinic = await _requireClinic(ref);
  return ref.watch(clinicRepositoryProvider).stats(clinic.id);
});

final todaysQueueProvider = FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final clinic = await _requireClinic(ref);
  return ref.watch(appointmentRepositoryProvider).todaysQueue(clinic.id);
});

final patientsProvider = FutureProvider.autoDispose<List<Patient>>((ref) async {
  final clinic = await _requireClinic(ref);
  return ref.watch(clinicRepositoryProvider).patients(clinic.id);
});

final missedFollowupsProvider = FutureProvider.autoDispose<List<MissedFollowUp>>((ref) async {
  final clinic = await _requireClinic(ref);
  return ref.watch(clinicRepositoryProvider).missedFollowups(clinic.id);
});

final pendingVaccinesProvider = FutureProvider.autoDispose<List<PendingVaccine>>((ref) async {
  final clinic = await _requireClinic(ref);
  return ref.watch(clinicRepositoryProvider).pendingVaccines(clinic.id);
});

final chatThreadsProvider = FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final clinic = await _requireClinic(ref);
  return ref.watch(clinicRepositoryProvider).chatThreads(clinic.id);
});

final formularyProvider = FutureProvider.autoDispose<List<DrugFormulary>>(
    (ref) => ref.watch(prescriptionRepositoryProvider).formulary());

/// Child timeline for the doctor: visits, prescriptions, vaccines given, growth checks.
final timelineProvider =
    FutureProvider.autoDispose.family<List<TimelineEvent>, String>((ref, childId) async {
  final clinic = await _requireClinic(ref);
  final health = ref.watch(healthRepositoryProvider);

  final rxF = ref.watch(prescriptionRepositoryProvider).forChild(childId);
  final vacF = health.vaccines(childId);
  final growthF = health.growth(childId);
  final apptF = ref.watch(appointmentRepositoryProvider).forChildAtClinic(clinic.id, childId);

  final rxs = await rxF;
  final vaccines = await vacF;
  final growth = await growthF;
  final appts = await apptF;

  final events = <TimelineEvent>[
    for (final a in appts.where((a) => a.status == 'completed'))
      TimelineEvent(
        date: a.scheduledAt,
        kind: TimelineKind.visit,
        title: a.reason ?? 'Clinic visit',
        subtitle: a.symptoms,
      ),
    for (final p in rxs)
      TimelineEvent(
        date: p.createdAt,
        kind: TimelineKind.prescription,
        title: p.diagnosis ?? 'Prescription',
        subtitle: '${p.items.map((e) => e.name).join(', ')} · ${numFmt(p.weightKg)} kg',
        refId: p.id,
      ),
    for (final v in vaccines.where((v) => v.isDone))
      TimelineEvent(
        date: v.givenOn ?? v.dueDate,
        kind: TimelineKind.vaccine,
        title: '${v.name} given',
        subtitle: v.protectsAgainst,
      ),
    for (final g in growth)
      TimelineEvent(
        date: g.measuredOn,
        kind: TimelineKind.growth,
        title: 'Growth check',
        subtitle: [
          if (g.weightKg != null) '${numFmt(g.weightKg!)} kg',
          if (g.heightCm != null) '${numFmt(g.heightCm!)} cm',
          if (g.headCm != null) 'head ${numFmt(g.headCm!)} cm',
        ].join(' · '),
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));
  return events;
});

// ---------------------------------------------------------------------------
// Department-specific state & providers
// ---------------------------------------------------------------------------
final activeClinicDepartmentProvider = Provider<ClinicDepartment>((ref) {
  final clinic = ref.watch(myClinicProvider).valueOrNull;
  return clinic?.department ?? ClinicDepartment.pediatrics;
});

// Dental
final dentalChartProvider =
    StateProvider.autoDispose.family<List<ToothData>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getToothChart(patientId);
});

final dentalPlansProvider =
    StateProvider.autoDispose.family<List<DentalTreatmentItem>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getTreatmentPlans(patientId);
});

// Dermatology
final dermaComparisonsProvider =
    StateProvider.autoDispose.family<List<DermaComparison>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getDermaComparisons(patientId);
});

final dermaSessionsProvider =
    StateProvider.autoDispose.family<List<DermaSessionLog>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getDermaSessions(patientId);
});

// Pregnancy Care
final pregnancyRecordProvider =
    StateProvider.autoDispose.family<PregnancyRecord, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getPregnancyRecord(patientId);
});

final ancCheckupsProvider =
    StateProvider.autoDispose.family<List<AncCheckup>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getAncCheckups(patientId);
});

final prenatalTestsProvider =
    StateProvider.autoDispose.family<List<PrenatalTestItem>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getPrenatalTests(patientId);
});

// Ophthalmology
final refractionProvider =
    StateProvider.autoDispose.family<RefractionPrescription, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getRefraction(patientId);
});

final eyeExamsProvider =
    StateProvider.autoDispose.family<List<EyeExamRecord>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getEyeExams(patientId);
});

// Psychiatry
final screenerHistoryProvider =
    StateProvider.autoDispose.family<List<ScreenerResult>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getScreenerHistory(patientId);
});

final therapyNotesProvider =
    StateProvider.autoDispose.family<List<TherapyNote>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getTherapyNotes(patientId);
});

final copingGoalsProvider =
    StateProvider.autoDispose.family<List<CopingGoal>, String>((ref, patientId) {
  final repo = ref.watch(departmentRepositoryProvider);
  return repo.getCopingGoals(patientId);
});
