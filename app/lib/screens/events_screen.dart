import 'package:flutter/material.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';

class EventsScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onCreateEventTap;

  const EventsScreen({
    super.key,
    required this.appState,
    required this.onCreateEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final events = appState.events;

    final filterOptions = ['All', 'Draft', 'Generated', 'Newest', 'Oldest'];

    return Scaffold(
      backgroundColor: ChronicoColors.background,
      body: Column(
        children: [
          // Search & Filter Header Area
          Container(
            color: ChronicoColors.background,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: ChronicoColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ChronicoColors.outlineVariant),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: ChronicoColors.onSurfaceVariant, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => appState.setSearchQuery(val),
                              style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Search events...',
                                hintStyle: TextStyle(color: ChronicoColors.onSurfaceVariant),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (appState.searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: ChronicoColors.onSurfaceVariant),
                              onPressed: () => appState.setSearchQuery(''),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filter Chips Bar
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filterOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = filterOptions[index];
                          final isSelected = appState.selectedFilter == filter;

                          return InkWell(
                            onTap: () => appState.setFilter(filter),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ChronicoColors.secondaryContainer
                                    : ChronicoColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : ChronicoColors.outlineVariant,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? ChronicoColors.onSecondaryContainer
                                      : ChronicoColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Events Grid Canvas
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_outlined, size: 48, color: ChronicoColors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text(
                          'No matching events found',
                          style: TextStyle(color: ChronicoColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try clearing search filters or create a new event record.',
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
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 900
                                ? 4
                                : (constraints.maxWidth >= 600 ? 3 : 2);

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return ChronicoEventCard(
                                  event: event,
                                  onTap: () {
                                    appState.selectEvent(event);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateEventTap,
        backgroundColor: ChronicoColors.primaryContainer,
        foregroundColor: ChronicoColors.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  void _showEventContextMenu(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChronicoColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: ChronicoColors.primary),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(ctx);
                appState.selectEvent(event);
              },
            ),
            if (event.status == EventStatus.draft)
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: ChronicoColors.tertiary),
                title: const Text('Generate AI Report'),
                onTap: () {
                  Navigator.pop(ctx);
                  appState.generateReportForEvent(event.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report generated successfully!')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: ChronicoColors.error),
              title: const Text('Delete Event', style: TextStyle(color: ChronicoColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteEvent(context, event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronicoColors.surfaceContainerHigh,
        title: const Text('Delete Event', style: TextStyle(color: ChronicoColors.onSurface)),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
          style: const TextStyle(color: ChronicoColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronicoColors.error,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              appState.deleteEvent(event.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
