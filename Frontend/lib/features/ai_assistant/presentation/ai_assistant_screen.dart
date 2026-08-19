import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Acadex AI', style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            tooltip: 'Clear Conversation',
            icon: Icon(LucideIcons.trash2),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
            },
          ),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).dividerColor, height: 1),
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
                        margin: EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        constraints: const BoxConstraints(maxWidth: 600),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.white : Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isAi ? const Radius.circular(4) : const Radius.circular(16),
                            bottomRight: isAi ? const Radius.circular(16) : const Radius.circular(4),
                          ),
                          border: isAi ? Border.all(color: Theme.of(context).dividerColor) : null,
                          boxShadow: [
                            if (isAi) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: AcadexTypography.body(color: isAi ? Theme.of(context).colorScheme.onSurface : Colors.white).copyWith(height: 1.5, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Loading / Error States
              if (chatState.isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)
                      ),
                      SizedBox(width: 12),
                      Text("Acadex AI is thinking...", style: AcadexTypography.caption(color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)).copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

              if (chatState.error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.1),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatState.error!,
                          style: AcadexTypography.caption(color: AcadexColors.error).copyWith(fontWeight: FontWeight.w500),
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
                        labelStyle: AcadexTypography.caption(color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        onPressed: chatState.isLoading ? null : () => _submitQuery(prompt),
                      );
                    }).toList(),
                  ),
                ),

              // Input Bar
              Container(
                padding: EdgeInsets.all(24).copyWith(top: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: "Ask about your campus...",
                          hintStyle: AcadexTypography.body(color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted).withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusLg,
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusLg,
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AcadexRadius.borderRadiusLg,
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: chatState.isLoading ? null : _submitQuery,
                        enabled: !chatState.isLoading,
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
                        elevation: 0,
                      ),
                      onPressed: chatState.isLoading
                          ? null
                          : () => _submitQuery(_queryController.text),
                      child: Icon(LucideIcons.send, size: 20),
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
