import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'providers/ai_providers.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitQuery(String query) {
    if (query.trim().isEmpty) return;
    _queryController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(query).then((_) {
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  List<String> _getSuggestedPrompts(AppRole role) {
    switch (role) {
      case AppRole.student:
        return [
          "How can I check my attendance?",
          "Explain my attendance percentage.",
          "Where can I find my notes?",
          "Where can I find my timetable?"
        ];
      case AppRole.faculty:
        return [
          "How do I mark attendance?",
          "How do I publish chapter notes?",
          "How do I view my assigned sections?",
          "How can I check attendance shortages?"
        ];
      case AppRole.hod:
        return [
          "How do I monitor department attendance?",
          "How can I identify attendance shortages?",
          "Where can I view faculty activity?"
        ];
      case AppRole.collegeAdmin:
        return [
          "How do I manage departments?",
          "How do I manage students?",
          "How do I view college analytics?"
        ];
      case AppRole.superAdmin:
        return [
          "How do I view platform analytics?",
          "How do I manage colleges?",
          "How does role management work?"
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final authState = ref.watch(authProvider);

    AppRole userRole = AppRole.student;
    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
    }

    final isGradientRole = userRole == AppRole.superAdmin ||
        userRole == AppRole.collegeAdmin ||
        userRole == AppRole.hod ||
        userRole == AppRole.faculty ||
        userRole == AppRole.student;
    final primaryActionColor = isGradientRole ? AcadexColors.superAdminDeepAction : Theme.of(context).primaryColor;
    final isMobile = AcadexBreakpoints.isMobile(context);

    // Auto-scroll when new messages arrive
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            if (hasEnclosingScaffold)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
                      icon: Icon(LucideIcons.trash2, size: 15, color: isGradientRole ? const Color(0xFFCCE6FF) : null),
                      label: Text(
                        'Clear Chat',
                        style: TextStyle(
                          color: isGradientRole ? Colors.white : null,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Chat History or Welcome State
            if (chatState.messages.isEmpty)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isGradientRole ? const Color(0xFFE6F2FF) : AcadexColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.bot,
                            size: 28,
                            color: Color(0xFF003366),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Acadex AI',
                          style: AcadexTypography.heading2(
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ask questions about attendance, schedules, courses, or college operations.',
                          textAlign: TextAlign.center,
                          style: AcadexTypography.body(
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _getSuggestedPrompts(userRole).map((prompt) {
                            return ActionChip(
                              label: Text(prompt),
                              labelStyle: AcadexTypography.caption(
                                color: const Color(0xFF003366),
                              ).copyWith(fontWeight: FontWeight.w600),
                              backgroundColor: const Color(0xFFE6F2FF),
                              side: const BorderSide(color: Color(0xFFCCE6FF)),
                              onPressed: chatState.isLoading ? null : () => _submitQuery(prompt),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
                    final isAi = msg.isAi;
                    
                    return Align(
                      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        constraints: const BoxConstraints(maxWidth: 600),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.white : primaryActionColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isAi ? const Radius.circular(4) : const Radius.circular(16),
                            bottomRight: isAi ? const Radius.circular(16) : const Radius.circular(4),
                          ),
                          border: isAi ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                          boxShadow: [
                            if (isAi) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: AcadexTypography.body(color: isAi ? const Color(0xFF0F172A) : Colors.white).copyWith(height: 1.5, fontSize: 14.5),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Loading / Error States
              if (chatState.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryActionColor),
                        ),
                        const SizedBox(width: 10),
                        if (isGradientRole)
                          const AcadexAdaptiveGradientText(
                            "Acadex AI is thinking...",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            "Acadex AI is thinking...",
                            style: AcadexTypography.caption(
                              color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                            ).copyWith(fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),
                ),

              if (chatState.error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatState.error!,
                          style: AcadexTypography.caption(color: const Color(0xFF991B1B)).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Simple retry of last user message if available
                          final lastUserMsg = chatState.messages.reversed.firstWhere((m) => !m.isAi, orElse: () => chatState.messages.first);
                          if (!lastUserMsg.isAi) {
                            _submitQuery(lastUserMsg.text);
                          }
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),

              // Suggested Prompts when 1 message exists
              if (chatState.messages.length == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getSuggestedPrompts(userRole).map((prompt) {
                      return ActionChip(
                        label: Text(prompt),
                        labelStyle: AcadexTypography.caption(
                          color: isGradientRole ? const Color(0xFF003366) : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                        ).copyWith(fontWeight: FontWeight.w600),
                        backgroundColor: isGradientRole ? const Color(0xFFE6F2FF) : Theme.of(context).colorScheme.surface,
                        side: BorderSide(color: isGradientRole ? const Color(0xFF0066CC).withValues(alpha: 0.3) : Theme.of(context).dividerColor),
                        onPressed: chatState.isLoading ? null : () => _submitQuery(prompt),
                      );
                    }).toList(),
                  ),
                ),

              // Input Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: isGradientRole ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: AcadexTypography.body(color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: "Ask about your campus...",
                          hintStyle: AcadexTypography.body(color: const Color(0xFF64748B).withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusLg,
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusLg,
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusLg,
                            borderSide: BorderSide(color: primaryActionColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: chatState.isLoading ? null : _submitQuery,
                        enabled: !chatState.isLoading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryActionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
                        elevation: 0,
                      ),
                      onPressed: chatState.isLoading
                          ? null
                          : () => _submitQuery(_queryController.text),
                      child: const Icon(LucideIcons.send, size: 20),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: isGradientRole ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Acadex AI',
          style: AcadexTypography.heading3(
            color: isGradientRole ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: isGradientRole ? Colors.transparent : Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isGradientRole ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Conversation',
            icon: Icon(LucideIcons.trash2, color: isGradientRole ? Colors.white : null),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }
}
