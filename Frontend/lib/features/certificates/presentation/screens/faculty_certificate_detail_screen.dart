import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'certificate_detail_screen.dart';

class FacultyCertificateDetailScreen extends ConsumerWidget {
  final String certificateId;
  const FacultyCertificateDetailScreen({super.key, required this.certificateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CertificateDetailScreen(certificateId: certificateId);
  }
}
