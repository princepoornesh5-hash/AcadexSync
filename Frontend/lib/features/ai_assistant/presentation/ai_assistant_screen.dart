import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'providers/ai_providers.dart';
import 'widgets/ai_markdown_view.dart';
import 'widgets/ai_composer.dart';
import 'widgets/ai_chat_sidebar.dart';
import 'widgets/ai_thinking_indicator.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSidebarOpen = true;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isFarFromBottom = (maxScroll - currentScroll) > 180;
    if (isFarFromBottom != _showScrollToBottom) {
      setState(() => _showScrollToBottom = isFarFromBottom);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(target);
        }
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

  void _handleNewChat() {
    ref.read(aiChatProvider.notifier).clearChat();
    _queryController.clear();
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
          "Where can I view faculty activity?",
          "How do I publish the section timetable?"
        ];
      case AppRole.collegeAdmin:
        return [
          "How do I manage departments?",
          "How do I manage students?",
          "How do I view college analytics?",
          "How do I configure semester dates?"
        ];
      case AppRole.superAdmin:
        return [
          "How do I view platform analytics?",
          "How do I manage colleges?",
          "How does role management work?",
          "Where are system audit logs?"
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

    final isMobile = AcadexBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    final suggestedPrompts = _getSuggestedPrompts(userRole);
    final hasUserMessages = chatState.messages.any((m) => !m.isAi);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: isMobile
          ? Drawer(
              child: AiChatSidebar(
                onNewChat: () {
                  Navigator.of(context).pop();
                  _handleNewChat();
                },
                onClose: () => Navigator.of(context).pop(),
                authState: authState,
                isModal: true,
              ),
            )
          : null,
      body: Row(
        children: [
          // Desktop Collapsible Sidebar
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: _isSidebarOpen ? 260 : 0,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 260,
                  maxWidth: 260,
                  alignment: Alignment.topLeft,
                  child: AiChatSidebar(
                    onNewChat: _handleNewChat,
                    authState: authState,
                    isModal: false,
                  ),
                ),
              ),
            ),

          // Main Chat Area
          Expanded(
            child: Column(
              children: [
                // Minimal Header
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isMobile)
                              IconButton(
                                icon: const Icon(LucideIcons.menu, size: 20),
                                tooltip: "Open chats sidebar",
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  _isSidebarOpen ? LucideIcons.panelLeftClose : LucideIcons.panelLeftOpen,
                                  size: 19,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                tooltip: _isSidebarOpen ? "Collapse sidebar" : "Open sidebar",
                                onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                              ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "Acadex Assistant",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F2FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Academic AI",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0052CC),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.penSquare, size: 18),
                            tooltip: "New Chat",
                            onPressed: _handleNewChat,
                          ),
                          if (hasUserMessages)
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18),
                              tooltip: "Clear conversation",
                              onPressed: _handleNewChat,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Conversation Area (or Empty State)
                Expanded(
                  child: Stack(
                    children: [
                      if (!hasUserMessages)
                        // Empty State Landing
                        Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 18 : 28,
                              vertical: 24,
                            ),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 780),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6F2FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCCE6FF),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.sparkles,
                                      size: 26,
                                      color: Color(0xFF0052CC),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    "What can I help you with?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isMobile ? 22 : 26,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Ask anything about your timetable, attendance standing, courses, or campus operations.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // 4 Suggestion Cards in 2x2 grid
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmall = constraints.maxWidth < 600;
                                      return Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: suggestedPrompts.map((prompt) {
                                          final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
                                          return SizedBox(
                                            width: cardWidth,
                                            child: InkWell(
                                              onTap: chatState.isLoading ? null : () => _submitQuery(prompt),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.02),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        prompt,
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                                          height: 1.35,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      LucideIcons.arrowUpRight,
                                                      size: 16,
                                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        // Active Message List
                        ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 24,
                            vertical: 16,
                          ),
                          itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Thinking state indicator
                            if (index == chatState.messages.length) {
                              return Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 780),
                                  margin: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F2FF),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFCCE6FF)),
                                        ),
                                        child: const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF0052CC)),
                                      ),
                                      const SizedBox(width: 14),
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8.0),
                                        child: AiThinkingIndicator(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final msg = chatState.messages[index];
                            final isAi = msg.isAi;

                            return Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 780),
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: isAi
                                    ? _buildAssistantRow(context, msg.text, isDark)
                                    : _buildUserRow(context, msg.text, isDark),
                              ),
                            );
                          },
                        ),

                      // Floating Jump-to-Bottom Button
                      if (_showScrollToBottom)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: InkWell(
                              onTap: () => _scrollToBottom(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.arrowDown,
                                      size: 14,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Jump to latest",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Error Banner if present
                if (chatState.error != null)
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: AcadexColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              chatState.error!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final lastUserMsg = chatState.messages.reversed
                                  .firstWhere((m) => !m.isAi, orElse: () => chatState.messages.first);
                              if (!lastUserMsg.isAi) {
                                _submitQuery(lastUserMsg.text);
                              }
                            },
                            child: const Text('Retry', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Message Composer
                AiComposer(
                  controller: _queryController,
                  isLoading: chatState.isLoading,
                  onSubmitted: _submitQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(BuildContext context, String text, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark navy ChatGPT style user bubble
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: const Radius.circular(4),
          ),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantRow(BuildContext context, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assistant Avatar Indicator
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE6F2FF),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCCE6FF),
            ),
          ),
          child: const Icon(
            LucideIcons.sparkles,
            size: 16,
            color: Color(0xFF0052CC),
          ),
        ),
        const SizedBox(width: 14),
        // Open Markdown Content Area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiMarkdownView(
                text: text,
                textColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
              ),
              const SizedBox(height: 6),
              // Subtle Assistant Actions (Copy, etc.)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CopyButton(text: text, isDark: isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  final bool isDark;

  const _CopyButton({required this.text, required this.isDark});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? LucideIcons.check : LucideIcons.copy,
              size: 14,
              color: _copied
                  ? AcadexColors.success
                  : (widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? "Copied" : "Copy",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _copied
                    ? AcadexColors.success
                    : (widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
