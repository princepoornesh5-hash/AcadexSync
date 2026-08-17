import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
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

    // Auto-scroll when new messages arrive
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('Acadex AI', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Clear Conversation',
            icon: const Icon(LucideIcons.trash2),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: DashboardColors.border, height: 1),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Chat History
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.messages[index];
                    final isAi = msg.isAi;
                    
                    return Align(
                      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        constraints: const BoxConstraints(maxWidth: 600),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.white : DashboardColors.primary,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isAi ? const Radius.circular(4) : const Radius.circular(16),
                            bottomRight: isAi ? const Radius.circular(16) : const Radius.circular(4),
                          ),
                          border: isAi ? Border.all(color: DashboardColors.border) : null,
                          boxShadow: [
                            if (isAi) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: isAi ? DashboardColors.textPrimary : Colors.white,
                            height: 1.5,
                          ),
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
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: DashboardColors.primary)
                      ),
                      const SizedBox(width: 12),
                      Text("Acadex AI is thinking...", style: GoogleFonts.inter(color: DashboardColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

              if (chatState.error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DashboardColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DashboardColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: DashboardColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatState.error!,
                          style: GoogleFonts.inter(color: DashboardColors.error, fontSize: 13, fontWeight: FontWeight.w500),
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

              // Suggested Prompts
              if (chatState.messages.length <= 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getSuggestedPrompts(userRole).map((prompt) {
                      return ActionChip(
                        label: Text(prompt),
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary),
                        backgroundColor: DashboardColors.surface,
                        side: BorderSide(color: DashboardColors.border),
                        onPressed: chatState.isLoading ? null : () => _submitQuery(prompt),
                      );
                    }).toList(),
                  ),
                ),

              // Input Bar
              Container(
                padding: const EdgeInsets.all(24).copyWith(top: 16),
                decoration: const BoxDecoration(
                  color: DashboardColors.background,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: GoogleFonts.inter(color: DashboardColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Ask about your campus...",
                          hintStyle: GoogleFonts.inter(color: DashboardColors.textMuted),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: DashboardColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: DashboardColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: DashboardColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: chatState.isLoading ? null : _submitQuery,
                        enabled: !chatState.isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }
}
