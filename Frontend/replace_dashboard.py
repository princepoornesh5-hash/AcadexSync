import re

with open('lib/features/dashboard/presentation/providers/dashboard_providers.dart', 'r') as f:
    content = f.read()

# Replace Certificates Quick Action
content = re.sub(
    r"label:\s*'Certificates',\s*icon:\s*LucideIcons\.award,\s*iconColor:\s*DashboardColors\.warning,\s*iconBackground:\s*DashboardColors\.warningLight,\s*route:\s*'/module/Certificates',",
    r"label: 'AI Assistant',\n        icon: LucideIcons.bot,\n        iconColor: DashboardColors.warning,\n        iconBackground: DashboardColors.warningLight,\n        route: '/ai-assistant',",
    content
)

# Replace Student Stat
content = re.sub(
    r"title:\s*'Certificates',\s*value:\s*'3',\s*subtitle:\s*'Uploaded this semester',\s*icon:\s*LucideIcons\.award,",
    r"title: 'AI Assistant',\n      value: 'Ready',\n      subtitle: 'Your campus guide',\n      icon: LucideIcons.bot,",
    content
)

# Replace Student Activity
content = re.sub(
    r"title:\s*'Certificate submitted',\s*subtitle:\s*'Hackathon certificate under review',\s*timeAgo:\s*'Yesterday',\s*icon:\s*LucideIcons\.award,",
    r"title: 'Asked Campus AI',\n        subtitle: 'Question about hostel fees answered',\n        timeAgo: 'Yesterday',\n        icon: LucideIcons.bot,",
    content
)

# Add AI Assistant to HOD Quick Actions (after Timetable)
hod_quick_action = r"""      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),
      const QuickActionModel(
        label: 'AI Assistant',
        icon: LucideIcons.bot,
        iconColor: DashboardColors.warning,
        iconBackground: DashboardColors.warningLight,
        route: '/ai-assistant',
      ),"""
content = content.replace(
    r"""      const QuickActionModel(
        label: 'Timetable',
        icon: LucideIcons.calendarDays,
        iconColor: DashboardColors.purple,
        iconBackground: DashboardColors.purpleLight,
        route: '/module/Timetable',
      ),""",
    hod_quick_action
)

with open('lib/features/dashboard/presentation/providers/dashboard_providers.dart', 'w') as f:
    f.write(content)

print("Replaced successfully")
