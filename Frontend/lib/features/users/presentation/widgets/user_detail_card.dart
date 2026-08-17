import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';

class UserDetailCard extends StatelessWidget {
  final String title;
  final Map<String, String> data;

  const UserDetailCard({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    e.key,
                    style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value.isNotEmpty ? e.value : 'N/A',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: DashboardColors.textPrimary),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
