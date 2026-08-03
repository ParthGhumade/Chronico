import 'package:flutter/material.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onCreateEventTap;

  const HomeScreen({
    super.key,
    required this.appState,
    required this.onCreateEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final drafts = appState.draftEvents;

    return Scaffold(
      backgroundColor: ChronicoColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Draft Events Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Draft Events',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ChronicoColors.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => appState.setTabIndex(1),
                      child: const Row(
                        children: [
                          Text('View All', style: TextStyle(color: ChronicoColors.primary)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16, color: ChronicoColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Draft Events List
                if (drafts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: ChronicoColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ChronicoColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.event_note, size: 48, color: ChronicoColors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text(
                          'No draft events currently',
                          style: TextStyle(color: ChronicoColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a new event to start logging narratives and generating official reports.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ChronicoColors.onSurfaceVariant, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: onCreateEventTap,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Event'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      return _buildDraftListItem(context, draft);
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: onCreateEventTap,
              backgroundColor: ChronicoColors.primaryContainer,
              foregroundColor: ChronicoColors.onPrimaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.edit, size: 24),
            )
          : null,
    );
  }



  Widget _buildDraftListItem(BuildContext context, Event draft) {
    return Container(
      decoration: BoxDecoration(
        color: ChronicoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChronicoColors.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          appState.selectEvent(draft);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ChronicoColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_document,
                  color: ChronicoColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ChronicoColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: ChronicoColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${draft.date.day}/${draft.date.month}/${draft.date.year}',
                          style: const TextStyle(fontSize: 12, color: ChronicoColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: ChronicoColors.outline, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text(
                          'Draft Record',
                          style: TextStyle(fontSize: 12, color: ChronicoColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: ChronicoColors.onSurfaceVariant),
                onPressed: () => appState.selectEvent(draft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
