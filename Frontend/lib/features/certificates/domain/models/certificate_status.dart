enum CertificateStatus {
  active,
  archived,
  removed,
  pendingVerification,
  verified,
}

extension CertificateStatusExtension on CertificateStatus {
  String get value {
    switch (this) {
      case CertificateStatus.active: return 'active';
      case CertificateStatus.archived: return 'archived';
      case CertificateStatus.removed: return 'removed';
      case CertificateStatus.pendingVerification: return 'pendingVerification';
      case CertificateStatus.verified: return 'verified';
    }
  }

  String get displayName {
    switch (this) {
      case CertificateStatus.active: return 'Active';
      case CertificateStatus.archived: return 'Archived';
      case CertificateStatus.removed: return 'Removed';
      case CertificateStatus.pendingVerification: return 'Pending Verification';
      case CertificateStatus.verified: return 'Verified';
    }
  }

  bool get isVisible => this == CertificateStatus.active ||
      this == CertificateStatus.pendingVerification ||
      this == CertificateStatus.verified;

  static CertificateStatus fromValue(String value) {
    return CertificateStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CertificateStatus.active,
    );
  }
}
