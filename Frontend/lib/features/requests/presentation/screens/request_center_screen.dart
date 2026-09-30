import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/request_model.dart';
import '../providers/requests_providers.dart';
import '../widgets/request_card.dart';

class RequestCenterScreen extends ConsumerStatefulWidget {
  const RequestCenterScreen({super.key});

  @override
  ConsumerState<RequestCenterScreen> createState() => _RequestCenterScreenState();
}

class _RequestCenterScreenState extends ConsumerState<RequestCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    AppRole role = AppRole.student;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final hasIncomingRole = role == AppRole.faculty ||
        role == AppRole.hod ||
        role == AppRole.collegeAdmin ||
        role == AppRole.superAdmin;

    final filter = ref.watch(requestsFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Request Center',
          style: AcadexTypography.heading2(color: AcadexColors.ink),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AcadexButton(
              label: 'New Request',
              icon: LucideIcons.plus,
              size: AcadexButtonSize.sm,
              onPressed: () => context.push('/requests/new'),
            ),
          ),
        ],
        bottom: hasIncomingRole
            ? TabBar(
                controller: _tabController,
                indicatorColor: AcadexColors.primary,
                indicatorWeight: 3,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: AcadexColors.inkMuted,
                labelStyle: AcadexTypography.bodySmall().copyWith(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'My Requests'),
                  Tab(text: 'Needs Attention'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AcadexColors.hairline, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(requestsFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search requests by title or reason...',
                    hintStyle: AcadexTypography.bodySmall(color: AcadexColors.inkMuted),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AcadexColors.inkMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(requestsFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AcadexColors.canvasSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AcadexColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: filter.status == null,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(clearStatus: true);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Draft',
                        isSelected: filter.status == RequestStatus.draft,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.draft);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Submitted',
                        isSelected: filter.status == RequestStatus.submitted,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.submitted);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Under Review',
                        isSelected: filter.status == RequestStatus.inReview,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.inReview);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Approved',
                        isSelected: filter.status == RequestStatus.approved,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.approved);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Rejected',
                        isSelected: filter.status == RequestStatus.rejected,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.rejected);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Resolved',
                        isSelected: filter.status == RequestStatus.resolved,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.resolved);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Cancelled',
                        isSelected: filter.status == RequestStatus.cancelled,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.cancelled);
                        },
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'Closed',
                        isSelected: filter.status == RequestStatus.closed,
                        onTap: () {
                          ref.read(requestsFilterProvider.notifier).state =
                              filter.copyWith(status: RequestStatus.closed);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Lists
          Expanded(
            child: hasIncomingRole
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _RequestsListView(
                        provider: myRequestsProvider,
                        isIncoming: false,
                        emptyMessage: 'No requests submitted yet.',
                        onRefresh: () async {
                          ref.invalidate(myRequestsProvider);
                          ref.invalidate(requestSummaryCountsProvider);
                        },
                      ),
                      _RequestsListView(
                        provider: incomingRequestsProvider,
                        isIncoming: true,
                        emptyMessage: 'No incoming requests awaiting your response.',
                        onRefresh: () async {
                          ref.invalidate(incomingRequestsProvider);
                          ref.invalidate(requestSummaryCountsProvider);
                        },
                      ),
                    ],
                  )
                : _RequestsListView(
                    provider: myRequestsProvider,
                    isIncoming: false,
                    emptyMessage: 'No requests submitted yet.',
                    onRefresh: () async {
                      ref.invalidate(myRequestsProvider);
                      ref.invalidate(requestSummaryCountsProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AcadexColors.primary : AcadexColors.canvasSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AcadexColors.primary : AcadexColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AcadexTypography.caption().copyWith(
            color: isSelected ? Colors.white : AcadexColors.inkSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _RequestsListView extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<RequestModel>> provider;
  final bool isIncoming;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _RequestsListView({
    required this.provider,
    required this.isIncoming,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(provider);

    return asyncRequests.when(
      loading: () => const Center(
        child: AcadexLoadingState(message: 'Loading requests...'),
      ),
      error: (err, _) => Center(
        child: AcadexErrorState(
          message: 'Unable to load requests: $err',
          onRetry: onRefresh,
        ),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AcadexColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AcadexColors.canvasSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.inbox,
                          size: 36,
                          color: AcadexColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        emptyMessage,
                        style: AcadexTypography.body(color: AcadexColors.inkSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AcadexColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return RequestCard(
                request: req,
                isIncoming: isIncoming,
                onTap: () => context.push('/requests/${req.id}'),
              );
            },
          ),
        );
      },
    );
  }
}
