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
class ChildrenNotifier extends StateNotifier<List<Child>> {
  ChildrenNotifier() : super(const []);

  void addChild(Child child) {
    state = [child, ...state.where((c) => c.id != child.id)];
  }

  void updateChild(Child child) {
    state = [
      for (final c in state)
        if (c.id == child.id) child else c
    ];
  }
}

final localChildrenProvider = StateNotifierProvider<ChildrenNotifier, List<Child>>((ref) {
  return ChildrenNotifier();
});

final childrenProvider = FutureProvider<List<Child>>((ref) async {
  final uid = ref.watch(userIdProvider);
  final local = ref.watch(localChildrenProvider);
  if (uid == null) return local;
  try {
    final remote = await ref.watch(healthRepositoryProvider).myChildren(uid);
    if (remote.isNotEmpty) return remote;
    return local;
  } catch (_) {
    return local;
  }
});

final selectedChildIdProvider = StateProvider<String?>((ref) => null);

final selectedChildProvider = Provider<AsyncValue<Child?>>((ref) {
  final children = ref.watch(childrenProvider);
  final id = ref.watch(selectedChildIdProvider);
  return children.whenData((list) {
    if (list.isEmpty) return null;
    if (id == null) return list.first;
    return list.firstWhere((c) => c.id == id, orElse: () => list.first);
  });
});

// ---------------------------------------------------------------------------
// Per-child data (used by parent AND doctor screens)
// ---------------------------------------------------------------------------

class LocalPrescriptionsNotifier extends StateNotifier<List<Prescription>> {
  LocalPrescriptionsNotifier() : super(const []);

  void addPrescription(Prescription rx) {
    state = [rx, ...state.where((p) => p.id != rx.id)];
  }
}

final localPrescriptionsProvider =
    StateNotifierProvider<LocalPrescriptionsNotifier, List<Prescription>>((ref) {
  return LocalPrescriptionsNotifier();
});

class LocalRecordsNotifier extends StateNotifier<List<MedicalRecord>> {
  LocalRecordsNotifier() : super(const []);

  void addRecord(MedicalRecord record) {
    state = [record, ...state.where((r) => r.id != record.id)];
  }
}

final localRecordsProvider =
    StateNotifierProvider<LocalRecordsNotifier, List<MedicalRecord>>((ref) {
  return LocalRecordsNotifier();
});

final childByIdProvider = FutureProvider.autoDispose.family<Child, String>(
  (ref, childId) async {
    // 1. Check local children (parent created)
    final local = ref.watch(localChildrenProvider);
    final found = local.where((c) => c.id == childId).firstOrNull;
    if (found != null) return found;

    // 2. Check doctor patients roster
    final allPatients = ref.watch(doctorPatientsProvider).values.expand((x) => x);
    final dp = allPatients.where((p) => p.id == childId).firstOrNull;
    if (dp != null) {
      return Child(
        id: dp.id,
        parentId: 'parent_${dp.id}',
        name: dp.name,
        dob: DateTime.now().subtract(const Duration(days: 365 * 4)),
        gender: dp.gender.isEmpty ? 'male' : dp.gender,
        bloodGroup: dp.bloodGroup,
        weightKg: dp.weightKg,
        allergies: null,
        chronicConditions: dp.condition,
        parentName: dp.parentName,
        parentPhone: dp.parentPhone,
      );
    }

    // 3. Try remote repository
    try {
      return await ref.watch(healthRepositoryProvider).childById(childId);
    } catch (_) {
      return Child(
        id: childId,
        parentId: '',
        name: 'Patient #${childId.length > 5 ? childId.substring(childId.length - 5) : childId}',
        dob: DateTime.now().subtract(const Duration(days: 365 * 3)),
        gender: 'child',
      );
    }
  },
);

final vaccinesProvider = FutureProvider.autoDispose.family<List<ChildVaccine>, String>(
  (ref, childId) async {
    try {
      final remote = await ref.watch(healthRepositoryProvider).vaccines(childId);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
    return const <ChildVaccine>[];
  },
);

final growthProvider = FutureProvider.autoDispose.family<List<GrowthRecord>, String>(
  (ref, childId) async {
    try {
      final remote = await ref.watch(healthRepositoryProvider).growth(childId);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
    final localChildren = ref.watch(localChildrenProvider);
    final child = localChildren.where((c) => c.id == childId).firstOrNull;
    if (child != null && child.weightKg != null) {
      return <GrowthRecord>[
        GrowthRecord(
          id: 'gr_current_${child.id}',
          childId: child.id,
          measuredOn: DateTime.now(),
          weightKg: child.weightKg,
          heightCm: child.heightCm,
          headCm: null,
        ),
      ];
    }
    return const <GrowthRecord>[];
  },
);

final recordsProvider = FutureProvider.autoDispose.family<List<MedicalRecord>, String>(
  (ref, childId) async {
    final local = ref.watch(localRecordsProvider).where((r) => r.childId == childId).toList();
    try {
      final remote = await ref.watch(healthRepositoryProvider).records(childId);
      if (remote.isNotEmpty) {
        final ids = remote.map((e) => e.id).toSet();
        return [...remote, ...local.where((r) => !ids.contains(r.id))];
      }
    } catch (_) {}
    return local;
  },
);

final prescriptionsProvider = FutureProvider.autoDispose.family<List<Prescription>, String>(
  (ref, childId) async {
    final local = ref.watch(localPrescriptionsProvider);
    final childLocal = local.where((p) => p.childId == childId).toList();
    try {
      final remote = await ref.watch(prescriptionRepositoryProvider).forChild(childId);
      if (remote.isNotEmpty) {
        final ids = remote.map((e) => e.id).toSet();
        return [...remote, ...childLocal.where((p) => !ids.contains(p.id))];
      }
    } catch (_) {}
    return childLocal;
  },
);

final prescriptionProvider = FutureProvider.autoDispose.family<Prescription, String>(
  (ref, id) async {
    final local = ref.watch(localPrescriptionsProvider);
    final match = local.where((p) => p.id == id).firstOrNull;
    if (match != null) return match;
    try {
      return await ref.watch(prescriptionRepositoryProvider).byId(id);
    } catch (_) {
      if (local.isNotEmpty) return local.first;
      throw Exception('Prescription not found');
    }
  },
);

class LocalAppointmentsNotifier extends StateNotifier<List<Appointment>> {
  LocalAppointmentsNotifier() : super(const []);

  void addAppointment(Appointment appt) {
    state = [appt, ...state.where((a) => a.id != appt.id)];
  }

  void cancelAppointment(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: 'cancelled') else a
    ];
  }

  void updateStatus(String id, String newStatus) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: newStatus) else a
    ];
  }
}

final localAppointmentsProvider =
    StateNotifierProvider<LocalAppointmentsNotifier, List<Appointment>>((ref) {
  return LocalAppointmentsNotifier();
});

final childAppointmentsProvider = FutureProvider.autoDispose.family<List<Appointment>, String>(
  (ref, childId) async {
    final localList = ref.watch(localAppointmentsProvider)
        .where((a) => a.childId == childId)
        .toList();
    try {
      final remoteList = await ref.watch(appointmentRepositoryProvider).forChild(childId);
      if (remoteList.isNotEmpty) {
        final ids = remoteList.map((e) => e.id).toSet();
        return [...remoteList, ...localList.where((a) => !ids.contains(a.id))];
      }
    } catch (_) {
      // Fallback cleanly to local list
    }
    return localList;
  },
);

final childClinicProvider = FutureProvider.autoDispose.family<Clinic?, String>(
    (ref, childId) async {
  try {
    final remote = await ref.watch(clinicRepositoryProvider).clinicOfChild(childId);
    if (remote != null) return remote;
  } catch (_) {}
  return null;
});

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
// RBAC & Doctor Accounts
// ---------------------------------------------------------------------------
/// Active authenticated role for RBAC enforcement
final currentUserRoleProvider = StateProvider<UserRole?>((ref) => null);

class DoctorAccountsNotifier extends StateNotifier<List<DoctorAccount>> {
  DoctorAccountsNotifier() : super(const []);

  void addDoctor(DoctorAccount doctor) {
    state = [...state.where((d) => d.id != doctor.id), doctor];
  }

  void updateDoctor(DoctorAccount doctor) {
    state = [
      for (final d in state)
        if (d.id == doctor.id) doctor else d
    ];
  }
}

final doctorAccountsProvider =
    StateNotifierProvider<DoctorAccountsNotifier, List<DoctorAccount>>((ref) {
  return DoctorAccountsNotifier();
});

final activeDoctorIdProvider = StateProvider<String>((ref) => '');

final currentDoctorAccountProvider = Provider<DoctorAccount>((ref) {
  final doctors = ref.watch(doctorAccountsProvider);
  final activeId = ref.watch(activeDoctorIdProvider);
  final matched = doctors.where((d) => d.id == activeId).firstOrNull;
  if (matched != null) return matched;
  if (doctors.isNotEmpty) return doctors.first;
  return const DoctorAccount(
    id: '',
    name: 'Doctor',
    email: '',
    pin: '',
    specialty: 'Pediatrics',
    regNo: '',
    phone: '',
    avatarPath: 'assets/images/avatar_doctor.png',
  );
});

// ---------------------------------------------------------------------------
// Doctor Clinics
// ---------------------------------------------------------------------------

class DoctorClinicsNotifier extends StateNotifier<Map<String, Clinic>> {
  DoctorClinicsNotifier() : super(const {});

  void setClinic(String doctorId, Clinic clinic) {
    state = {...state, doctorId: clinic};
  }

  void addDepartment(String doctorId, ClinicDepartment dept) {
    final current = state[doctorId];
    if (current == null) return;
    if (!current.availableDepartments.contains(dept)) {
      final updated = current.copyWith(
        availableDepartments: [...current.availableDepartments, dept],
      );
      state = {...state, doctorId: updated};
    }
  }

  void removeDepartment(String doctorId, ClinicDepartment dept) {
    final current = state[doctorId];
    if (current == null) return;
    if (current.availableDepartments.length <= 1) return; // keep at least 1
    final updated = current.copyWith(
      availableDepartments:
          current.availableDepartments.where((d) => d != dept).toList(),
      department: current.department == dept
          ? current.availableDepartments.firstWhere((d) => d != dept)
          : current.department,
    );
    state = {...state, doctorId: updated};
  }

  Clinic? findClinicByCode(String code) {
    final clean = code.trim().toUpperCase();
    for (final c in state.values) {
      if (c.joinCode.toUpperCase() == clean) return c;
    }
    return null;
  }

  void registerDoctorToClinic(String doctorId, Clinic clinic) {
    state = {...state, doctorId: clinic};
  }
}

final localClinicsProvider =
    StateNotifierProvider<DoctorClinicsNotifier, Map<String, Clinic>>((ref) {
  return DoctorClinicsNotifier();
});

// ---------------------------------------------------------------------------
// Doctor-Specific Patients & OPD Queue
// ---------------------------------------------------------------------------

class DoctorPatientsNotifier
    extends StateNotifier<Map<String, List<DoctorPatient>>> {
  DoctorPatientsNotifier()
      : super(const {});

  void addPatientToDoctor(String doctorId, DoctorPatient patient) {
    final list = state[doctorId] ?? [];
    state = {
      ...state,
      doctorId: [...list.where((p) => p.id != patient.id), patient],
    };
  }

  void updatePatientStatus(String doctorId, String patientId, String newStatus) {
    final list = state[doctorId] ?? [];
    state = {
      ...state,
      doctorId: [
        for (final p in list)
          if (p.id == patientId) p.copyWith(status: newStatus) else p
      ],
    };
  }
}

final doctorPatientsProvider = StateNotifierProvider<DoctorPatientsNotifier,
    Map<String, List<DoctorPatient>>>((ref) {
  return DoctorPatientsNotifier();
});

final currentDoctorPatientsProvider = Provider<List<DoctorPatient>>((ref) {
  final docId = ref.watch(activeDoctorIdProvider);
  final map = ref.watch(doctorPatientsProvider);
  final baseList = List<DoctorPatient>.from(map[docId] ?? []);

  // Merge any parent-registered children assigned to this doctor
  final localChildren = ref.watch(localChildrenProvider);
  final allDocs = ref.watch(doctorAccountsProvider);
  final currentDoc = allDocs.where((d) => d.id == docId).firstOrNull;
  final docName = currentDoc?.name.toLowerCase() ?? '';
  final docClinicId = currentDoc?.clinicId ?? '';
  final localAppts = ref.watch(localAppointmentsProvider);

  for (final c in localChildren) {
    final alreadyIn = baseList.any((p) => p.id == c.id);
    final childApptWithThisDoc = localAppts.any((a) =>
        a.childId == c.id &&
        ((docName.isNotEmpty && a.doctorName != null && a.doctorName!.toLowerCase().contains(docName)) ||
            (docClinicId.isNotEmpty && a.clinicId == docClinicId)));

    final isDocMatch = (docName.isNotEmpty &&
            c.pediatrician != null &&
            c.pediatrician!.toLowerCase().contains(docName)) ||
        childApptWithThisDoc;

    if (!alreadyIn && isDocMatch) {
      baseList.add(DoctorPatient(
        id: c.id,
        name: c.name,
        ageDisplay: c.age,
        condition: (c.chronicConditions != null &&
                c.chronicConditions!.isNotEmpty &&
                c.chronicConditions != 'None')
            ? c.chronicConditions!
            : 'General Pediatric Care',
        time: '11:00 AM',
        avatarPath: 'assets/images/avatar_child.png',
        gender: c.gender,
        bloodGroup: c.bloodGroup,
        weightKg: c.weightKg,
        parentName: c.parentName ?? 'Parent',
        parentPhone: c.parentPhone ?? '',
        status: 'Scheduled',
        lastVisit: DateTime.now().subtract(const Duration(days: 15)),
      ));
    }
  }

  // Also reflect any appointments booked with this doctor
  final appts = ref.watch(localAppointmentsProvider);
  for (final a in appts) {
    if (a.childId.isNotEmpty) {
      final existingIndex = baseList.indexWhere((p) => p.id == a.childId);
      if (existingIndex != -1) {
        if (a.status == 'completed') {
          baseList[existingIndex] = baseList[existingIndex].copyWith(status: 'Completed');
        }
      } else {
        baseList.add(DoctorPatient(
          id: a.childId,
          name: a.childName ?? 'Patient',
          ageDisplay: 'Child',
          condition: a.reason ?? 'Pediatric Appointment',
          time: fmtTime(a.scheduledAt),
          avatarPath: 'assets/images/avatar_child.png',
          gender: 'male',
          status: a.status == 'completed' ? 'Completed' : 'Scheduled',
          lastVisit: a.status == 'completed' ? a.scheduledAt : null,
        ));
      }
    }
  }

  return baseList;
});

// ---------------------------------------------------------------------------
// Doctor Repository Connectors
// ---------------------------------------------------------------------------
final myClinicProvider = FutureProvider<Clinic?>((ref) async {
  final activeDocId = ref.watch(activeDoctorIdProvider);
  final localClinics = ref.watch(localClinicsProvider);
  if (localClinics.containsKey(activeDocId)) {
    return localClinics[activeDocId];
  }
  final uid = ref.watch(userIdProvider);
  if (uid == null) return null;
  try {
    final remote = await ref.watch(clinicRepositoryProvider).myClinic(uid);
    if (remote != null) return remote;
    return localClinics[activeDocId];
  } catch (_) {
    return localClinics[activeDocId];
  }
});

final doctorStatsProvider =
    FutureProvider.autoDispose<DoctorStats>((ref) async {
  final docPatients = ref.watch(currentDoctorPatientsProvider);
  return DoctorStats(
    todaysAppointments: docPatients.length,
    patients: docPatients.length,
    missedFollowups: 0,
    pendingVaccines: 0,
    unreadMessages: 0,
  );
});

final todaysQueueProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final clinic = ref.watch(myClinicProvider).valueOrNull;
  if (clinic == null) return [];
  try {
    return await ref.watch(appointmentRepositoryProvider).todaysQueue(clinic.id);
  } catch (_) {
    return [];
  }
});

final patientsProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
  final docPatients = ref.watch(currentDoctorPatientsProvider);
  final localChildren = ref.watch(localChildrenProvider);
  return docPatients.map((dp) {
    final match = localChildren.where((c) => c.id == dp.id).firstOrNull;
    if (match != null) {
      return Patient(child: match, lastVisit: dp.lastVisit);
    }
    return Patient(
      child: Child(
        id: dp.id,
        parentId: 'parent_${dp.id}',
        name: dp.name,
        dob: DateTime.now().subtract(const Duration(days: 365 * 4)),
        gender: dp.gender,
        bloodGroup: dp.bloodGroup,
        parentName: dp.parentName,
        parentPhone: dp.parentPhone,
        weightKg: dp.weightKg,
      ),
      lastVisit: dp.lastVisit,
    );
  }).toList();
});

final missedFollowupsProvider =
    FutureProvider.autoDispose<List<MissedFollowUp>>((ref) async {
  final clinic = ref.watch(myClinicProvider).valueOrNull;
  if (clinic == null) return [];
  try {
    return await ref.watch(clinicRepositoryProvider).missedFollowups(clinic.id);
  } catch (_) {
    return [];
  }
});

final pendingVaccinesProvider =
    FutureProvider.autoDispose<List<PendingVaccine>>((ref) async {
  final clinic = ref.watch(myClinicProvider).valueOrNull;
  if (clinic == null) return [];
  try {
    return await ref.watch(clinicRepositoryProvider).pendingVaccines(clinic.id);
  } catch (_) {
    return [];
  }
});

final chatThreadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final clinic = ref.watch(myClinicProvider).valueOrNull;
  if (clinic == null) return [];
  try {
    return await ref.watch(clinicRepositoryProvider).chatThreads(clinic.id);
  } catch (_) {
    return [];
  }
});

final formularyProvider = FutureProvider.autoDispose<List<DrugFormulary>>(
    (ref) => ref.watch(prescriptionRepositoryProvider).formulary());

/// Child timeline for the doctor: visits, prescriptions, vaccines given, growth checks.
final timelineProvider =
    FutureProvider.autoDispose.family<List<TimelineEvent>, String>((ref, childId) async {
  final clinic = ref.watch(myClinicProvider).valueOrNull;
  final health = ref.watch(healthRepositoryProvider);

  try {
    final rxF = ref.watch(prescriptionRepositoryProvider).forChild(childId);
    final vacF = health.vaccines(childId);
    final growthF = health.growth(childId);
    final apptF = clinic != null
        ? ref.watch(appointmentRepositoryProvider).forChildAtClinic(clinic.id, childId)
        : Future.value(<Appointment>[]);

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

    if (events.isNotEmpty) return events;

    return [
      TimelineEvent(
        date: DateTime.now().subtract(const Duration(days: 3)),
        kind: TimelineKind.visit,
        title: 'Pediatric OPD Consultation',
        subtitle: 'Routine wellness assessment & vitals check',
      ),
      TimelineEvent(
        date: DateTime.now().subtract(const Duration(days: 30)),
        kind: TimelineKind.vaccine,
        title: 'DTwP Booster Administered',
        subtitle: 'Diphtheria, Tetanus, Pertussis',
      ),
    ];
  } catch (_) {
    return [
      TimelineEvent(
        date: DateTime.now().subtract(const Duration(days: 3)),
        kind: TimelineKind.visit,
        title: 'Pediatric OPD Consultation',
        subtitle: 'Routine wellness assessment & vitals check',
      ),
    ];
  }
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
