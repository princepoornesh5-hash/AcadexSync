enum CertificateType {
  academic,
  technical,
  internship,
  workshop,
  participation,
  achievement,
  sports,
  cultural,
  other,
}

extension CertificateTypeExtension on CertificateType {
  String get value {
    switch (this) {
      case CertificateType.academic: return 'academic';
      case CertificateType.technical: return 'technical';
      case CertificateType.internship: return 'internship';
      case CertificateType.workshop: return 'workshop';
      case CertificateType.participation: return 'participation';
      case CertificateType.achievement: return 'achievement';
      case CertificateType.sports: return 'sports';
      case CertificateType.cultural: return 'cultural';
      case CertificateType.other: return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case CertificateType.academic: return 'Academic';
      case CertificateType.technical: return 'Technical';
      case CertificateType.internship: return 'Internship';
      case CertificateType.workshop: return 'Workshop';
      case CertificateType.participation: return 'Participation';
      case CertificateType.achievement: return 'Achievement';
      case CertificateType.sports: return 'Sports';
      case CertificateType.cultural: return 'Cultural';
      case CertificateType.other: return 'Other';
    }
  }

  static CertificateType fromValue(String value) {
    return CertificateType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CertificateType.other,
    );
  }
}
