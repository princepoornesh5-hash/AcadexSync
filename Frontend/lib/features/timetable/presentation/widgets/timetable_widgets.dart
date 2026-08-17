import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/timetable_models.dart';

class TimetableCard extends StatelessWidget {
  final TimetableModel entry;
  final bool isCompact;

  const TimetableCard({super.key, required this.entry, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  entry.startTime,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.primary,
                    fontSize: isCompact ? 14 : 16,
                  ),
                ),
                Text(
                  entry.endTime,
                  style: GoogleFonts.inter(
                    color: DashboardColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.subjectId, // Ideally we map this to subject name
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary,
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DashboardColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.sessionType.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.user, size: 14, color: DashboardColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      entry.facultyId, // Ideally map to faculty name
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 14, color: DashboardColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.roomNumber}${entry.building != null ? ' (${entry.building})' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TodayScheduleWidget extends StatelessWidget {
  final List<TimetableModel> todayEntries;

  const TodayScheduleWidget({super.key, required this.todayEntries});

  @override
  Widget build(BuildContext context) {
    if (todayEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DashboardColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashboardColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.calendarCheck, size: 48, color: DashboardColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No classes scheduled for today',
                style: GoogleFonts.inter(
                  color: DashboardColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: todayEntries.map((entry) => TimetableCard(entry: entry, isCompact: true)).toList(),
    );
  }
}
