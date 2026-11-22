import '../core/utils.dart';
export 'department_models.dart';
import 'department_models.dart';

DateTime _ts(dynamic v) => DateTime.parse(v as String).toLocal();
DateTime _day(dynamic v) {
  final p = DateTime.parse(v as String);
  return DateTime(p.year, p.month, p.day);
}

double? _num(dynamic v) => (v as num?)?.toDouble();

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------
enum UserRole { parent, doctor }

class Profile {
  const Profile({required this.id, required this.role, required this.fullName, this.phone});

  final String id;
  final UserRole role;
  final String fullName;
  final String? phone;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        role: j['role'] == 'doctor' ? UserRole.doctor : UserRole.parent,
        fullName: (j['full_name'] as String?) ?? '',
        phone: j['phone'] as String?,
      );
}

class Clinic {
  const Clinic({
    required this.id,
    required this.doctorId,
    required this.name,
    required this.joinCode,
    required this.openTime,
    required this.closeTime,
    required this.slotMinutes,
    this.address,
    this.phone,
    this.department = ClinicDepartment.pediatrics,
    this.availableDepartments = const [ClinicDepartment.pediatrics],
  });

  final String id;
  final String doctorId;
  final String name;
  final String joinCode;
  final String? address;
  final String? phone;
  final ClinicDepartment department;
  final List<ClinicDepartment> availableDepartments;

  /// "HH:mm" 24h
  final String openTime;
  final String closeTime;
  final int slotMinutes;

  Clinic copyWith({
    String? name,
    String? address,
    String? phone,
    String? openTime,
    String? closeTime,
    int? slotMinutes,
    ClinicDepartment? department,
    List<ClinicDepartment>? availableDepartments,
  }) =>
      Clinic(
        id: id,
        doctorId: doctorId,
        name: name ?? this.name,
        joinCode: joinCode,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        slotMinutes: slotMinutes ?? this.slotMinutes,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        department: department ?? this.department,
        availableDepartments: availableDepartments ?? this.availableDepartments,
      );

  factory Clinic.fromJson(Map<String, dynamic> j) {
    final deptList = (j['available_departments'] as List<dynamic>?)
            ?.map((e) => ClinicDepartment.fromKey(e as String?))
            .toList() ??
        [ClinicDepartment.fromKey(j['department'] as String?)];
    return Clinic(
      id: j['id'] as String,
      doctorId: j['doctor_id'] as String,
      name: j['name'] as String,
      joinCode: j['join_code'] as String,
      address: j['address'] as String?,
      phone: j['phone'] as String?,
      openTime: (j['open_time'] as String).substring(0, 5),
      closeTime: (j['close_time'] as String).substring(0, 5),
      slotMinutes: (j['slot_minutes'] as num).toInt(),
      department: ClinicDepartment.fromKey(j['department'] as String?),
      availableDepartments: deptList,
    );
  }
}

// ---------------------------------------------------------------------------
// Doctor Account & RBAC
// ---------------------------------------------------------------------------
class DoctorAccount {
  const DoctorAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.pin,
    required this.specialty,
    required this.regNo,
    required this.phone,
    this.avatarPath = 'assets/images/avatar_doctor.png',
    this.clinicId,
  });

  final String id;
  final String name;
  final String email;
  final String pin;
  final String specialty;
  final String regNo;
  final String phone;
  final String avatarPath;
  final String? clinicId;

  DoctorAccount copyWith({
    String? name,
    String? email,
    String? pin,
    String? specialty,
    String? regNo,
    String? phone,
    String? avatarPath,
    String? clinicId,
  }) =>
      DoctorAccount(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        pin: pin ?? this.pin,
        specialty: specialty ?? this.specialty,
        regNo: regNo ?? this.regNo,
        phone: phone ?? this.phone,
        avatarPath: avatarPath ?? this.avatarPath,
        clinicId: clinicId ?? this.clinicId,
      );
}

class DoctorPatient {
  const DoctorPatient({
    required this.id,
    required this.name,
    required this.ageDisplay,
    required this.condition,
    required this.time,
    required this.avatarPath,
    required this.gender,
    this.bloodGroup,
    this.weightKg,
    this.parentName,
    this.parentPhone,
    this.lastVisit,
    this.status = 'Scheduled',
  });

  final String id;
  final String name;
  final String ageDisplay;
  final String condition;
  final String time;
  final String avatarPath;
  final String gender;
  final String? bloodGroup;
  final double? weightKg;
  final String? parentName;
  final String? parentPhone;
  final DateTime? lastVisit;
  final String status;

  String get ageGender => '$ageDisplay • $gender';

  DoctorPatient copyWith({
    String? name,
    String? ageDisplay,
    String? condition,
    String? time,
    String? avatarPath,
    String? gender,
    String? bloodGroup,
    double? weightKg,
    String? parentName,
    String? parentPhone,
    DateTime? lastVisit,
    String? status,
  }) =>
      DoctorPatient(
        id: id,
        name: name ?? this.name,
        ageDisplay: ageDisplay ?? this.ageDisplay,
        condition: condition ?? this.condition,
        time: time ?? this.time,
        avatarPath: avatarPath ?? this.avatarPath,
        gender: gender ?? this.gender,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        weightKg: weightKg ?? this.weightKg,
        parentName: parentName ?? this.parentName,
        parentPhone: parentPhone ?? this.parentPhone,
        lastVisit: lastVisit ?? this.lastVisit,
        status: status ?? this.status,
      );
}

// ---------------------------------------------------------------------------
// Child
// ---------------------------------------------------------------------------
class Child {
  const Child({
    required this.id,
    required this.parentId,
    required this.name,
    required this.dob,
    required this.gender,
    this.bloodGroup,
    this.allergies,
    this.parentName,
    this.parentPhone,
    this.weightKg,
    this.heightCm,
    this.birthWeightKg,
    this.chronicConditions,
    this.emergencyContact,
    this.pediatrician,
  });

  final String id;
  final String parentId;
  final String name;
  final DateTime dob;
  final String gender;
  final String? bloodGroup;
  final String? allergies;
  final String? parentName;
  final String? parentPhone;
  final double? weightKg;
  final double? heightCm;
  final double? birthWeightKg;
  final String? chronicConditions;
  final String? emergencyContact;
  final String? pediatrician;

  String get age => ageLabel(dob);
  int get ageMonths => ageInMonths(dob);

  Child copyWith({
    String? id,
    String? parentId,
    String? name,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? parentName,
    String? parentPhone,
    double? weightKg,
    double? heightCm,
    double? birthWeightKg,
    String? chronicConditions,
    String? emergencyContact,
    String? pediatrician,
  }) =>
      Child(
        id: id ?? this.id,
        parentId: parentId ?? this.parentId,
        name: name ?? this.name,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        allergies: allergies ?? this.allergies,
        parentName: parentName ?? this.parentName,
        parentPhone: parentPhone ?? this.parentPhone,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        birthWeightKg: birthWeightKg ?? this.birthWeightKg,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        emergencyContact: emergencyContact ?? this.emergencyContact,
        pediatrician: pediatrician ?? this.pediatrician,
      );

  factory Child.fromJson(Map<String, dynamic> j) {
    final p = j['profiles'];
    return Child(
      id: j['id'] as String,
      parentId: j['parent_id'] as String,
      name: j['name'] as String,
      dob: _day(j['dob']),
      gender: j['gender'] as String,
      bloodGroup: j['blood_group'] as String?,
      allergies: j['allergies'] as String?,
      parentName: p is Map ? p['full_name'] as String? : null,
      parentPhone: p is Map ? p['phone'] as String? : null,
      weightKg: _num(j['weight_kg']),
      heightCm: _num(j['height_cm']),
      birthWeightKg: _num(j['birth_weight_kg']),
      chronicConditions: j['chronic_conditions'] as String?,
      emergencyContact: j['emergency_contact'] as String?,
      pediatrician: j['pediatrician'] as String?,
    );
  }
}

class ChildVaccine {
  const ChildVaccine({
    required this.id,
    required this.childId,
    required this.name,
    required this.ageLabel,
    required this.dueDate,
    required this.status,
    this.protectsAgainst,
    this.givenOn,
    this.batchNumber,
    this.clinic,
  });

  final String id;
  final String childId;
  final String name;
  final String ageLabel;
  final String? protectsAgainst;
  final DateTime dueDate;
  final String status; // pending | done | skipped
  final DateTime? givenOn;
  final String? batchNumber;
  final String? clinic;

  bool get isDone => status == 'done';
  int get daysToDue => dateOnly(dueDate).difference(dateOnly(DateTime.now())).inDays;
  bool get isOverdue => status == 'pending' && daysToDue < 0;
  bool get isDueSoon => status == 'pending' && daysToDue >= 0 && daysToDue <= 30;

  ChildVaccine copyWith({
    String? id,
    String? childId,
    String? name,
    String? ageLabel,
    String? protectsAgainst,
    DateTime? dueDate,
    String? status,
    DateTime? givenOn,
    String? batchNumber,
    String? clinic,
  }) =>
      ChildVaccine(
        id: id ?? this.id,
        childId: childId ?? this.childId,
        name: name ?? this.name,
        ageLabel: ageLabel ?? this.ageLabel,
        protectsAgainst: protectsAgainst ?? this.protectsAgainst,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        givenOn: givenOn ?? this.givenOn,
        batchNumber: batchNumber ?? this.batchNumber,
        clinic: clinic ?? this.clinic,
      );

  factory ChildVaccine.fromJson(Map<String, dynamic> j) {
    final t = (j['vaccine_templates'] as Map?) ?? const {};
    return ChildVaccine(
      id: j['id'] as String,
      childId: j['child_id'] as String,
      name: (t['name'] as String?) ?? 'Vaccine',
      ageLabel: (t['age_label'] as String?) ?? '',
      protectsAgainst: t['protects_against'] as String?,
      dueDate: _day(j['due_date']),
      status: j['status'] as String,
      givenOn: j['given_on'] == null ? null : _day(j['given_on']),
      batchNumber: j['batch_number'] as String?,
      clinic: j['clinic'] as String?,
    );
  }
}

class GrowthRecord {
  const GrowthRecord({
    required this.id,
    required this.childId,
    required this.measuredOn,
    this.weightKg,
    this.heightCm,
    this.headCm,
  });

  final String id;
  final String childId;
  final DateTime measuredOn;
  final double? weightKg;
  final double? heightCm;
  final double? headCm;

  GrowthRecord copyWith({
    String? id,
    String? childId,
    DateTime? measuredOn,
    double? weightKg,
    double? heightCm,
    double? headCm,
  }) =>
      GrowthRecord(
        id: id ?? this.id,
        childId: childId ?? this.childId,
        measuredOn: measuredOn ?? this.measuredOn,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        headCm: headCm ?? this.headCm,
      );

  factory GrowthRecord.fromJson(Map<String, dynamic> j) => GrowthRecord(
        id: j['id'] as String,
        childId: j['child_id'] as String,
        measuredOn: _day(j['measured_on']),
        weightKg: _num(j['weight_kg']),
        heightCm: _num(j['height_cm']),
        headCm: _num(j['head_cm']),
      );
}

// ---------------------------------------------------------------------------
// Appointments
// ---------------------------------------------------------------------------
class Appointment {
  const Appointment({
    required this.id,
    required this.clinicId,
    required this.childId,
    required this.scheduledAt,
    required this.status,
    this.tokenNo,
    this.reason,
    this.symptoms,
    this.childName,
    this.childDob,
    this.clinicName,
    this.doctorName,
    this.specialty,
    this.doctorAvatar,
  });

  final String id;
  final String clinicId;
  final String childId;
  final DateTime scheduledAt;
  final String status; // booked | in_consult | completed | cancelled | no_show
  final int? tokenNo;
  final String? reason;
  final String? symptoms;
  final String? childName;
  final DateTime? childDob;
  final String? clinicName;
  final String? doctorName;
  final String? specialty;
  final String? doctorAvatar;

  bool get isActive => status == 'booked' || status == 'in_consult';
  bool get isUpcoming =>
      isActive && !dateOnly(scheduledAt).isBefore(dateOnly(DateTime.now()));

  Appointment copyWith({
    String? id,
    String? clinicId,
    String? childId,
    DateTime? scheduledAt,
    String? status,
    int? tokenNo,
    String? reason,
    String? symptoms,
    String? childName,
    DateTime? childDob,
    String? clinicName,
    String? doctorName,
    String? specialty,
    String? doctorAvatar,
  }) {
    return Appointment(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      childId: childId ?? this.childId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      tokenNo: tokenNo ?? this.tokenNo,
      reason: reason ?? this.reason,
      symptoms: symptoms ?? this.symptoms,
      childName: childName ?? this.childName,
      childDob: childDob ?? this.childDob,
      clinicName: clinicName ?? this.clinicName,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      doctorAvatar: doctorAvatar ?? this.doctorAvatar,
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> j) {
    final c = j['children'];
    final cl = j['clinics'];
    return Appointment(
      id: j['id'] as String,
      clinicId: j['clinic_id'] as String,
      childId: j['child_id'] as String,
      scheduledAt: _ts(j['scheduled_at']),
      status: j['status'] as String,
      tokenNo: (j['token_no'] as num?)?.toInt(),
      reason: j['reason'] as String?,
      symptoms: j['symptoms'] as String?,
      childName: c is Map ? c['name'] as String? : null,
      childDob: c is Map && c['dob'] != null ? _day(c['dob']) : null,
      clinicName: cl is Map ? cl['name'] as String? : null,
      doctorName: j['doctor_name'] as String?,
      specialty: j['specialty'] as String?,
      doctorAvatar: j['doctor_avatar'] as String?,
    );
  }
}

class QueueStatus {
  const QueueStatus({required this.token, required this.ahead, this.nowServing});

  final int? token;
  final int ahead;
  final int? nowServing;

  factory QueueStatus.fromJson(Map<String, dynamic> j) => QueueStatus(
        token: (j['token'] as num?)?.toInt(),
        ahead: (j['ahead'] as num?)?.toInt() ?? 0,
        nowServing: (j['now_serving'] as num?)?.toInt(),
      );
}

// ---------------------------------------------------------------------------
// Prescriptions
// ---------------------------------------------------------------------------
class RxItem {
  const RxItem({
    required this.name,
    required this.timesPerDay,
    required this.durationDays,
    this.doseMg,
    this.doseMl,
    this.doseText,
    this.instructions,
  });

  final String name;
  final double? doseMg;
  final double? doseMl;
  final String? doseText; // free text for custom medicines
  final int timesPerDay;
  final int durationDays;
  final String? instructions;

  String get doseLabel {
    if (doseText != null && doseText!.trim().isNotEmpty) return doseText!;
    final parts = <String>[];
    if (doseMl != null) parts.add('${numFmt(doseMl!)} mL');
    if (doseMg != null) parts.add('${numFmt(doseMg!)} mg');
    return parts.join(' · ');
  }

  String get scheduleLabel =>
      '$timesPerDay× a day · $durationDays day${durationDays == 1 ? '' : 's'}';

  Map<String, dynamic> toJson() => {
        'name': name,
        'dose_mg': doseMg,
        'dose_ml': doseMl,
        'dose_text': doseText,
        'times_per_day': timesPerDay,
        'duration_days': durationDays,
        'instructions': instructions,
      };

  factory RxItem.fromJson(Map<String, dynamic> j) => RxItem(
        name: j['name'] as String,
        doseMg: _num(j['dose_mg']),
        doseMl: _num(j['dose_ml']),
        doseText: j['dose_text'] as String?,
        timesPerDay: (j['times_per_day'] as num?)?.toInt() ?? 1,
        durationDays: (j['duration_days'] as num?)?.toInt() ?? 1,
        instructions: j['instructions'] as String?,
      );
}

class Prescription {
  const Prescription({
    required this.id,
    required this.childId,
    required this.clinicId,
    required this.weightKg,
    required this.items,
    required this.createdAt,
    this.diagnosis,
    this.notes,
    this.followUpDate,
    this.childName,
    this.childDob,
    this.clinicName,
    this.clinicAddress,
    this.clinicPhone,
    this.doctorName,
  });

  final String id;
  final String childId;
  final String clinicId;
  final double weightKg;
  final List<RxItem> items;
  final DateTime createdAt;
  final String? diagnosis;
  final String? notes;
  final DateTime? followUpDate;
  final String? childName;
  final DateTime? childDob;
  final String? clinicName;
  final String? clinicAddress;
  final String? clinicPhone;
  final String? doctorName;

  factory Prescription.fromJson(Map<String, dynamic> j) {
    final c = j['children'];
    final cl = j['clinics'];
    final d = j['doctor'];
    return Prescription(
      id: j['id'] as String,
      childId: j['child_id'] as String,
      clinicId: j['clinic_id'] as String,
      weightKg: (j['weight_kg'] as num).toDouble(),
      items: ((j['items'] as List?) ?? const [])
          .map((e) => RxItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: _ts(j['created_at']),
      diagnosis: j['diagnosis'] as String?,
      notes: j['notes'] as String?,
      followUpDate: j['follow_up_date'] == null ? null : _day(j['follow_up_date']),
      childName: c is Map ? c['name'] as String? : null,
      childDob: c is Map && c['dob'] != null ? _day(c['dob']) : null,
      clinicName: cl is Map ? cl['name'] as String? : null,
      clinicAddress: cl is Map ? cl['address'] as String? : null,
      clinicPhone: cl is Map ? cl['phone'] as String? : null,
      doctorName: d is Map ? d['full_name'] as String? : null,
    );
  }
}

class DrugFormulary {
  const DrugFormulary({
    required this.id,
    required this.name,
    required this.form,
    required this.strengthMg,
    required this.strengthMl,
    required this.mgPerKgPerDose,
    required this.dosesPerDay,
    required this.maxMgPerKgPerDay,
    required this.minAgeMonths,
    required this.defaultDurationDays,
    required this.reviewed,
    this.maxSingleDoseMg,
    this.instructions,
  });

  final int id;
  final String name;
  final String form;
  final double strengthMg;
  final double strengthMl;
  final double mgPerKgPerDose;
  final int dosesPerDay;
  final double maxMgPerKgPerDay;
  final double? maxSingleDoseMg;
  final int minAgeMonths;
  final int defaultDurationDays;
  final String? instructions;
  final bool reviewed;

  factory DrugFormulary.fromJson(Map<String, dynamic> j) => DrugFormulary(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        form: (j['form'] as String?) ?? '',
        strengthMg: (j['strength_mg'] as num).toDouble(),
        strengthMl: (j['strength_ml'] as num).toDouble(),
        mgPerKgPerDose: (j['mg_per_kg_per_dose'] as num).toDouble(),
        dosesPerDay: (j['doses_per_day'] as num).toInt(),
        maxMgPerKgPerDay: (j['max_mg_per_kg_per_day'] as num).toDouble(),
        maxSingleDoseMg: _num(j['max_single_dose_mg']),
        minAgeMonths: (j['min_age_months'] as num?)?.toInt() ?? 0,
        defaultDurationDays: (j['default_duration_days'] as num?)?.toInt() ?? 3,
        instructions: j['instructions'] as String?,
        reviewed: (j['reviewed'] as bool?) ?? false,
      );
}

// ---------------------------------------------------------------------------
// Records + chat
// ---------------------------------------------------------------------------
class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.childId,
    required this.title,
    required this.category,
    required this.filePath,
    required this.createdAt,
  });

  final String id;
  final String childId;
  final String title;
  final String category;
  final String filePath;
  final DateTime createdAt;

  factory MedicalRecord.fromJson(Map<String, dynamic> j) => MedicalRecord(
        id: j['id'] as String,
        childId: j['child_id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        filePath: j['file_path'] as String,
        createdAt: _ts(j['created_at']),
      );
}

class ChatKey {
  const ChatKey(this.clinicId, this.childId);

  final String clinicId;
  final String childId;

  @override
  bool operator ==(Object other) =>
      other is ChatKey && other.clinicId == clinicId && other.childId == childId;

  @override
  int get hashCode => Object.hash(clinicId, childId);
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.createdAt,
    this.body,
    this.attachmentPath,
    this.readAt,
  });

  final String id;
  final String senderId;
  final String senderRole;
  final String? body;
  final String? attachmentPath;
  final DateTime createdAt;
  final DateTime? readAt;

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        senderRole: j['sender_role'] as String,
        body: j['body'] as String?,
        attachmentPath: j['attachment_path'] as String?,
        createdAt: _ts(j['created_at']),
        readAt: j['read_at'] == null ? null : _ts(j['read_at']),
      );
}

class ChatThread {
  const ChatThread({
    required this.childId,
    required this.childName,
    required this.lastAt,
    required this.unread,
    this.lastBody,
  });

  final String childId;
  final String childName;
  final String? lastBody;
  final DateTime lastAt;
  final int unread;

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        childId: j['child_id'] as String,
        childName: j['child_name'] as String,
        lastBody: j['last_body'] as String?,
        lastAt: _ts(j['last_at']),
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Doctor side
// ---------------------------------------------------------------------------
class DoctorStats {
  const DoctorStats({
    required this.patients,
    required this.pendingVaccines,
    required this.missedFollowups,
    required this.unreadMessages,
    required this.todaysAppointments,
  });

  final int patients;
  final int pendingVaccines;
  final int missedFollowups;
  final int unreadMessages;
  final int todaysAppointments;

  factory DoctorStats.fromJson(Map<String, dynamic> j) => DoctorStats(
        patients: (j['patients'] as num).toInt(),
        pendingVaccines: (j['pending_vaccines'] as num).toInt(),
        missedFollowups: (j['missed_followups'] as num).toInt(),
        unreadMessages: (j['unread_messages'] as num).toInt(),
        todaysAppointments: (j['todays_appointments'] as num).toInt(),
      );
}

class Patient {
  const Patient({required this.child, this.lastVisit});

  final Child child;
  final DateTime? lastVisit;
}

class MissedFollowUp {
  const MissedFollowUp({
    required this.childId,
    required this.childName,
    required this.followUpDate,
    this.diagnosis,
  });

  final String childId;
  final String childName;
  final DateTime followUpDate;
  final String? diagnosis;

  int get daysOverdue => dateOnly(DateTime.now()).difference(followUpDate).inDays;

  factory MissedFollowUp.fromJson(Map<String, dynamic> j) => MissedFollowUp(
        childId: j['child_id'] as String,
        childName: j['child_name'] as String,
        followUpDate: _day(j['follow_up_date']),
        diagnosis: j['diagnosis'] as String?,
      );
}

class PendingVaccine {
  const PendingVaccine({
    required this.id,
    required this.childId,
    required this.childName,
    required this.vaccineName,
    required this.dueDate,
  });

  final String id;
  final String childId;
  final String childName;
  final String vaccineName;
  final DateTime dueDate;

  int get daysToDue => dateOnly(dueDate).difference(dateOnly(DateTime.now())).inDays;

  factory PendingVaccine.fromJson(Map<String, dynamic> j) => PendingVaccine(
        id: j['child_vaccine_id'] as String,
        childId: j['child_id'] as String,
        childName: j['child_name'] as String,
        vaccineName: j['vaccine_name'] as String,
        dueDate: _day(j['due_date']),
      );
}

enum TimelineKind { visit, prescription, vaccine, growth }

class TimelineEvent {
  const TimelineEvent({
    required this.date,
    required this.kind,
    required this.title,
    this.subtitle,
    this.refId,
  });

  final DateTime date;
  final TimelineKind kind;
  final String title;
  final String? subtitle;
  final String? refId;
}
