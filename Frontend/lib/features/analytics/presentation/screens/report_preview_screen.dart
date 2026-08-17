import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/analytics_models.dart';

class ReportPreviewScreen extends ConsumerWidget {
  final AttendanceReport report;

  const ReportPreviewScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('Report Preview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing is not implemented yet')));
            },
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(LucideIcons.printer),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printing is not implemented yet')));
            },
            tooltip: 'Print',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DashboardColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.type.name.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: DashboardColors.primary),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(report.generatedAt),
                        style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    report.title,
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: DashboardColors.border),
                  const SizedBox(height: 16),
                  Text('Filters Applied', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: report.filtersApplied.entries.map((entry) {
                      return Chip(
                        label: Text('${entry.key}: ${entry.value}', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary)),
                        backgroundColor: DashboardColors.background,
                        side: const BorderSide(color: DashboardColors.border),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary
            Text('Summary', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border),
              ),
              child: Text(
                report.summary,
                style: GoogleFonts.inter(fontSize: 15, color: DashboardColors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Placeholders for Table / Detailed Data
            Text('Detailed Data', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: DashboardColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.table2, size: 48, color: DashboardColors.border),
                    const SizedBox(height: 12),
                    Text('Tabular data will be rendered here', style: GoogleFonts.inter(color: DashboardColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: DashboardColors.surface,
          border: Border(top: BorderSide(color: DashboardColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel export is not implemented yet')));
                },
                icon: const Icon(LucideIcons.fileSpreadsheet),
                label: const Text('Export Excel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generation is not implemented yet')));
                },
                icon: const Icon(LucideIcons.fileText),
                label: const Text('Export PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
