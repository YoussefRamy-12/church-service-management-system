import 'package:flutter/foundation.dart';

/// Allowed financial status options in Arabic.
class FinancialStatus {
  static const natural = 'طبيعي';
  static const brothersOfLord = 'إخوة رب';
  static const hiddenFamily = 'أسرة مستترة';

  static const List<String> values = [natural, brothersOfLord, hiddenFamily];

  static bool isValid(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    return values.contains(value.trim());
  }
}

/// Represents the sensitive and pastoral data of a student.
@immutable
class SensitiveStudentData {
  const SensitiveStudentData({
    required this.studentId,
    this.fatherJob,
    this.fatherPhone,
    this.motherName,
    this.motherJob,
    this.motherPhone,
    this.familySize,
    this.birthOrder,
    this.confessor,
    this.medicalNotes,
    this.financialStatus,
    this.address,
    this.addressBuilding,
    this.addressStreet,
    this.addressFloor,
    this.addressApartment,
    this.confidentialNotes,
    this.studyYear,
    this.guardianName,
    this.guardianPhone,
    this.emergencyPhone,
  });

  final String studentId;
  final String? fatherJob;
  final String? fatherPhone;
  final String? motherName;
  final String? motherJob;
  final String? motherPhone;
  final int? familySize;
  final int? birthOrder;
  final String? confessor;
  final String? medicalNotes;
  final String? financialStatus;
  final String? address;
  final String? addressBuilding;
  final String? addressStreet;
  final String? addressFloor;
  final String? addressApartment;
  final String? confidentialNotes;
  final String? studyYear;

  // Legacy fields kept for backward compatibility and safe migration
  final String? guardianName;
  final String? guardianPhone;
  final String? emergencyPhone;

  /// Returns the effective father's phone, falling back to legacy guardian_phone.
  String? get effectiveFatherPhone =>
      fatherPhone?.trim().isNotEmpty == true ? fatherPhone : guardianPhone;

  /// Returns the effective mother's phone, falling back to legacy emergency_phone.
  String? get effectiveMotherPhone =>
      motherPhone?.trim().isNotEmpty == true ? motherPhone : emergencyPhone;

  /// Formats a complete human-readable address from structured components or legacy string.
  String get fullAddress {
    final parts = <String>[];
    if (addressBuilding?.trim().isNotEmpty == true) {
      parts.add('عقار ${addressBuilding!.trim()}');
    }
    if (addressStreet?.trim().isNotEmpty == true) {
      parts.add('شارع ${addressStreet!.trim()}');
    }
    if (addressFloor?.trim().isNotEmpty == true) {
      parts.add('الدور ${addressFloor!.trim()}');
    }
    if (addressApartment?.trim().isNotEmpty == true) {
      parts.add('شقة ${addressApartment!.trim()}');
    }

    if (parts.isNotEmpty) {
      return parts.join('، ');
    }
    return address?.trim() ?? '';
  }

  /// Validates domain invariants:
  /// - familySize must be > 0 if provided.
  /// - birthOrder must be > 0 if provided.
  /// - birthOrder must be <= familySize if both provided.
  /// - financialStatus must be one of the approved options if provided.
  static String? validateFamilyAndFinance({
    int? familySize,
    int? birthOrder,
    String? financialStatus,
  }) {
    if (familySize != null && familySize <= 0) {
      return 'عدد أفراد الأسرة يجب أن يكون رقمًا موجبًا.';
    }
    if (birthOrder != null && birthOrder <= 0) {
      return 'ترتيب الطالب بين إخوته يجب أن يكون رقمًا موجبًا.';
    }
    if (familySize != null && birthOrder != null && birthOrder > familySize) {
      return 'ترتيب الطالب بين إخوته ($birthOrder) لا يمكن أن يتجاوز عدد أفراد الأسرة ($familySize).';
    }
    if (financialStatus != null &&
        financialStatus.trim().isNotEmpty &&
        !FinancialStatus.isValid(financialStatus)) {
      return 'الحالة المادية غير مقبولة. الخيارات المتاحة: طبيعي، إخوة رب، أسرة مستترة.';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'father_job': _clean(fatherJob),
      'father_phone': _clean(effectiveFatherPhone),
      'mother_name': _clean(motherName),
      'mother_job': _clean(motherJob),
      'mother_phone': _clean(effectiveMotherPhone),
      'family_size': familySize,
      'birth_order': birthOrder,
      'confessor': _clean(confessor),
      'medical_notes': _clean(medicalNotes),
      'financial_status': _clean(financialStatus),
      'address':
          _clean(address) ?? (fullAddress.isNotEmpty ? fullAddress : null),
      'address_building': _clean(addressBuilding),
      'address_street': _clean(addressStreet),
      'address_floor': _clean(addressFloor),
      'address_apartment': _clean(addressApartment),
      'confidential_notes': _clean(confidentialNotes),
      'study_year': _clean(studyYear),
      // Note: guardian_name, guardian_phone, emergency_phone are legacy
      // columns that may not exist in the production table. They are
      // intentionally excluded from the upsert payload. Read-side
      // fallback logic in fromMap() handles them when present.
    };
  }

  factory SensitiveStudentData.fromMap(
    Map<String, dynamic> map, {
    required String studentId,
  }) {
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString().trim());
    }

    return SensitiveStudentData(
      studentId: studentId,
      fatherJob: map['father_job'] as String?,
      fatherPhone:
          map['father_phone'] as String? ?? map['guardian_phone'] as String?,
      motherName: map['mother_name'] as String?,
      motherJob: map['mother_job'] as String?,
      motherPhone:
          map['mother_phone'] as String? ?? map['emergency_phone'] as String?,
      familySize: parseInt(map['family_size']),
      birthOrder: parseInt(map['birth_order']),
      confessor: map['confessor'] as String?,
      medicalNotes: map['medical_notes'] as String?,
      financialStatus: map['financial_status'] as String?,
      address: map['address'] as String?,
      addressBuilding: map['address_building'] as String?,
      addressStreet: map['address_street'] as String?,
      addressFloor: map['address_floor'] as String?,
      addressApartment: map['address_apartment'] as String?,
      confidentialNotes: map['confidential_notes'] as String?,
      studyYear: map['study_year'] as String?,
      guardianName: map['guardian_name'] as String?,
      guardianPhone: map['guardian_phone'] as String?,
      emergencyPhone: map['emergency_phone'] as String?,
    );
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
