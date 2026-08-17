import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_providers.dart';
import '../widgets/timetable_widgets.dart';

class TimetableDashboardScreen extends ConsumerStatefulWidget {
  const TimetableDashboardScreen({super.key});

  @override
  ConsumerState<TimetableDashboardScreen> createState() => _TimetableDashboardScreenState();
}

class _TimetableDashboardScreenState extends ConsumerState<TimetableDashboardScreen> {
  TimetableDay _selectedDay = TimetableDay.values[DateTime.now().weekday - 1];

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyTimetableProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(
          'My Timetable',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: DashboardColors.textPrimary,
          ),
        ),
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: weeklyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: DashboardColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load timetable', style: GoogleFonts.inter(fontSize: 16)),
              TextButton(
                onPressed: () => ref.refresh(weeklyTimetableProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (weeklyData) {
          if (isDesktop) {
            return _buildDesktopGrid(weeklyData);
          }
          return _buildMobileView(weeklyData);
        },
      ),
    );
  }

  Widget _buildDesktopGrid(Map<TimetableDay, List<TimetableModel>> weeklyData) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: TimetableDay.values.map((day) {
          final entries = weeklyData[day] ?? [];
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: DashboardColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DashboardColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: DashboardColors.border)),
                    ),
                    child: Text(
                      day.displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              'Free',
                              style: GoogleFonts.inter(
                                color: DashboardColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              return TimetableCard(entry: entries[index], isCompact: true);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileView(Map<TimetableDay, List<TimetableModel>> weeklyData) {
    final entries = weeklyData[_selectedDay] ?? [];

    return Column(
      children: [
        Container(
          height: 60,
          decoration: const BoxDecoration(
            color: DashboardColors.surface,
            border: Border(bottom: BorderSide(color: DashboardColors.border)),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: TimetableDay.values.map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(day.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDay = day);
                  },
                  backgroundColor: DashboardColors.background,
                  selectedColor: DashboardColors.primaryLight,
                  labelStyle: TextStyle(
                    color: isSelected ? DashboardColors.primary : DashboardColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? DashboardColors.primary.withValues(alpha: 0.5) : DashboardColors.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.coffee, size: 64, color: DashboardColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No classes scheduled',
                        style: GoogleFonts.inter(color: DashboardColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return TimetableCard(entry: entries[index]);
                  },
                ),
        ),
      ],
    );
  }
}
