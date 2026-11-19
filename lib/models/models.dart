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
  });

  final String id;
  final String doctorId;
  final String name;
  final String joinCode;
  final String? address;
  final String? phone;
  final ClinicDepartment department;

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
      );

  factory Clinic.fromJson(Map<String, dynamic> j) => Clinic(
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

  String get age => ageLabel(dob);
  int get ageMonths => ageInMonths(dob);

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
  });

  final String id;
  final String childId;
  final String name;
  final String ageLabel;
  final String? protectsAgainst;
  final DateTime dueDate;
  final String status; // pending | done | skipped
  final DateTime? givenOn;

  bool get isDone => status == 'done';
  int get daysToDue => dateOnly(dueDate).difference(dateOnly(DateTime.now())).inDays;
  bool get isOverdue => status == 'pending' && daysToDue < 0;
  bool get isDueSoon => status == 'pending' && daysToDue >= 0 && daysToDue <= 14;

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

  bool get isActive => status == 'booked' || status == 'in_consult';
  bool get isUpcoming =>
      isActive && !dateOnly(scheduledAt).isBefore(dateOnly(DateTime.now()));

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
