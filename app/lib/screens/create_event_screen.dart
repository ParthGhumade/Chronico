import 'package:flutter/material.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_uploader.dart';

class CreateEventScreen extends StatefulWidget {
  final AppState appState;
  final Event? initialEvent;
  final VoidCallback onBack;
  final ValueChanged<Event> onReportGenerated;

  const CreateEventScreen({
    super.key,
    required this.appState,
    this.initialEvent,
    required this.onBack,
    required this.onReportGenerated,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late TextEditingController _nameController;
  late TextEditingController _narrationController;
  late DateTime _selectedDate;
  late List<String> _attachedPhotos;
  late String _eventId;
  late EventStatus _currentStatus;
  GeneratedReport? _generatedReport;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    _nameController = TextEditingController(text: ev?.title ?? '');
    _narrationController = TextEditingController(text: ev?.narration ?? '');
    _selectedDate = ev?.date ?? DateTime.now();
    _attachedPhotos = List<String>.from(ev?.attachedPhotos ?? []);
    _eventId = ev?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _currentStatus = ev?.status ?? EventStatus.draft;
    _generatedReport = ev?.generatedReport;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    final title = _nameController.text.trim();
    if (title.isEmpty) return;

    final event = Event(
      id: _eventId,
      title: title,
      date: _selectedDate,
      narration: _narrationController.text.trim(),
      status: _currentStatus,
      attachedPhotos: _attachedPhotos,
      generatedReport: _generatedReport,
      createdAt: widget.initialEvent?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.appState.saveEvent(event);
  }

  void _handleGenerateReport() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Event Name before generating report.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    _saveDraft();

    final eventId = _eventId;

    // Simulate AI generation progress delay
    await Future.delayed(const Duration(milliseconds: 1200));

    widget.appState.generateReportForEvent(eventId);

    final generatedEvent = widget.appState.getEventById(eventId);

    if (mounted) {
      if (generatedEvent != null) {
        _currentStatus = generatedEvent.status;
        _generatedReport = generatedEvent.generatedReport;
      }
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Report generated and saved successfully!'),
          backgroundColor: ChronicoColors.primaryContainer,
        ),
      );
    }
  }

  void _confirmDeleteEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronicoColors.surfaceContainerHigh,
        title: const Text('Delete Event', style: TextStyle(color: ChronicoColors.onSurface)),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
          style: TextStyle(color: ChronicoColors.onSurfaceVariant),
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
              widget.appState.deleteEvent(_eventId);
              widget.onBack();
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: ChronicoColors.background,
      appBar: AppBar(
        backgroundColor: ChronicoColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ChronicoColors.primary),
          onPressed: () {
            _saveDraft();
            widget.onBack();
          },
        ),
        title: Text(
          widget.initialEvent == null ? 'Create New Event' : 'Edit Event',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ChronicoColors.onSurface,
          ),
        ),
        actions: [
          if (widget.initialEvent != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: ChronicoColors.error),
              tooltip: 'Delete Event',
              onPressed: () => _confirmDeleteEvent(context),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.cloud_done, size: 18, color: ChronicoColors.onSurfaceVariant),
                const SizedBox(width: 6),
                const Text(
                  'Saved',
                  style: TextStyle(fontSize: 12, color: ChronicoColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 24,
          ),
          child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 768) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Metadata & Photo Upload (1/3 width)
                      SizedBox(
                        width: 360,
                        child: Column(
                          children: [
                            _buildFormCard(),
                            const SizedBox(height: 16),
                            ChronicoPhotoUploader(
                              photos: _attachedPhotos,
                              onChanged: (updated) {
                                setState(() {
                                  _attachedPhotos = updated;
                                });
                                _saveDraft();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Narration Editor (2/3 width)
                      Expanded(
                        child: Column(
                          children: [
                            _buildNarrationEditor(),
                            const SizedBox(height: 24),
                            _buildActionButton(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 16),
                      ChronicoPhotoUploader(
                        photos: _attachedPhotos,
                        onChanged: (updated) {
                          setState(() {
                            _attachedPhotos = updated;
                          });
                          _saveDraft();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildNarrationEditor(),
                      const SizedBox(height: 24),
                      _buildActionButton(),
                      const SizedBox(height: 40),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChronicoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronicoColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Name
          const Text(
            'Event Name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            onChanged: (_) => _saveDraft(),
            style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'What\'s special?',
            ),
          ),
          const SizedBox(height: 16),

          // Date Picker
          const Text(
            'Event Date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) {
                  return Theme(
                    data: ChronicoTheme.darkTheme,
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
                _saveDraft();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: ChronicoColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChronicoColors.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: ChronicoColors.primary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrationEditor() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChronicoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChronicoColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, color: ChronicoColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Narration & Event Notes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ChronicoColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _narrationController,
            onChanged: (_) => _saveDraft(),
            maxLines: 12,
            minLines: 8,
            style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Describe everything that happened during the event in detail...\n\n- Key speeches and guests\n- Student performances & activities\n- Awards presented & closing remarks',
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_currentStatus == EventStatus.generated && !_isGenerating) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Downloading PDF...')),
            );
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text(
            'Download PDF',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ChronicoColors.tertiary,
            foregroundColor: ChronicoColors.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _handleGenerateReport,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating ? 'Generating report...' : 'Generate Report',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChronicoColors.primaryContainer,
          foregroundColor: ChronicoColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
      ),
    );
  }
}
