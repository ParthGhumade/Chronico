import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/settings.dart';
import '../services/database_helper.dart';

class AppState extends ChangeNotifier {
  int _currentTabIndex = 0;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  Event? _selectedEvent;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  int get currentTabIndex => _currentTabIndex;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  Event? get selectedEvent => _selectedEvent;

  InstitutionalSettings _settings = InstitutionalSettings(
    schoolName: 'Springfield Elementary School',
    address: '742 Evergreen Terrace, Springfield, State, 12345',
    principalName: 'Seymour Skinner',
    defaultSignatory: 'Gary Chalmers',
    customFields: [
      CustomField(id: '1', name: 'U-DISE Code', value: '27210509902'),
      CustomField(id: '2', name: 'Affiliation No.', value: 'CBSE-110482'),
    ],
  );

  List<Event> _events = [];

  AppState() {
    _initFromDatabase();
  }

  Future<void> _initFromDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      final presetsMap = await DatabaseHelper.instance.getAllPresets();
      if (presetsMap.isEmpty) {
        // Seed default presets to SQLite
        _settings = InstitutionalSettings(
          schoolName: 'Springfield Elementary School',
          address: '742 Evergreen Terrace, Springfield, State, 12345',
          principalName: 'Seymour Skinner',
          defaultSignatory: 'Gary Chalmers',
          customFields: [
            CustomField(id: '1', name: 'U-DISE Code', value: '27210509902'),
            CustomField(id: '2', name: 'Affiliation No.', value: 'CBSE-110482'),
          ],
        );
        await DatabaseHelper.instance.setAllPresets(_settings.toPresetsMap());
      } else {
        _settings = InstitutionalSettings.fromPresetsMap(presetsMap);
      }

      final dbEvents = await DatabaseHelper.instance.getEvents();
      if (dbEvents.isEmpty) {
        // Seed initial events to SQLite
        final seedEvents = _getSeedEvents();
        for (final event in seedEvents) {
          await DatabaseHelper.instance.insertEvent(event);
        }
        _events = seedEvents;
      } else {
        _events = dbEvents;
      }
    } catch (e) {
      debugPrint('Error initializing database in AppState: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void selectEvent(Event? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  // Institutional Settings
  InstitutionalSettings get settings => _settings;

  Future<void> updateSettings({
    required String schoolName,
    required String address,
    required String principalName,
    required String defaultSignatory,
  }) async {
    _settings = _settings.copyWith(
      schoolName: schoolName,
      address: address,
      principalName: principalName,
      defaultSignatory: defaultSignatory,
    );
    notifyListeners();
    await DatabaseHelper.instance.setAllPresets(_settings.toPresetsMap());
  }

  Future<void> addCustomField(String name, String value) async {
    final updatedFields = List<CustomField>.from(_settings.customFields)
      ..add(CustomField(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        value: value,
      ));
    _settings = _settings.copyWith(customFields: updatedFields);
    notifyListeners();
    await DatabaseHelper.instance.setAllPresets(_settings.toPresetsMap());
  }

  Future<void> removeCustomField(String id) async {
    final updatedFields = _settings.customFields.where((f) => f.id != id).toList();
    _settings = _settings.copyWith(customFields: updatedFields);
    notifyListeners();
    await DatabaseHelper.instance.setAllPresets(_settings.toPresetsMap());
  }

  Future<void> updateCustomField(String id, String name, String value) async {
    final updatedFields = _settings.customFields.map((f) {
      if (f.id == id) {
        return f.copyWith(name: name, value: value);
      }
      return f;
    }).toList();
    _settings = _settings.copyWith(customFields: updatedFields);
    notifyListeners();
    await DatabaseHelper.instance.setAllPresets(_settings.toPresetsMap());
  }

  List<Event> get events {
    List<Event> filtered = List.from(_events);

    // Apply Search Filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.narration.toLowerCase().contains(q);
      }).toList();
    }

    // Apply Chip Filter
    if (_selectedFilter == 'Draft') {
      filtered = filtered.where((e) => e.status == EventStatus.draft).toList();
    } else if (_selectedFilter == 'Generated') {
      filtered = filtered.where((e) => e.status == EventStatus.generated).toList();
    } else if (_selectedFilter == 'Newest') {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedFilter == 'Oldest') {
      filtered.sort((a, b) => a.date.compareTo(b.date));
    }

    return filtered;
  }

  List<Event> get draftEvents => _events.where((e) => e.status == EventStatus.draft).toList();
  List<Event> get generatedEvents => _events.where((e) => e.status == EventStatus.generated).toList();

  Event? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveEvent(Event event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _events[index] = event;
    } else {
      _events.insert(0, event);
    }
    notifyListeners();
    await DatabaseHelper.instance.insertEvent(event);
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    if (_selectedEvent?.id == id) {
      _selectedEvent = null;
    }
    notifyListeners();
    await DatabaseHelper.instance.deleteEvent(id);
  }

  Future<void> generateReportForEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index >= 0) {
      final ev = _events[index];
      final report = GeneratedReport(
        executiveSummary:
            'Formal documentation generated for ${ev.title} conducted on ${_formatDate(ev.date)}.',
        keyHighlights: [
          'Successful execution of ${ev.title}.',
          'Active involvement of students, faculty, and administrative staff.',
          'Event narrative recorded and archived into official school records.',
        ],
        formattedBody:
            '${ev.title} was held on ${_formatDate(ev.date)}. ${ev.narration.isEmpty ? "The event proceeded according to the scheduled agenda with strong institutional participation." : ev.narration}\n\nThe detailed event records have been reviewed and approved by the institutional leadership.',
        generatedAt: DateTime.now(),
      );

      final updated = ev.copyWith(
        status: EventStatus.generated,
        generatedReport: report,
        updatedAt: DateTime.now(),
      );

      _events[index] = updated;
      if (_selectedEvent?.id == eventId) {
        _selectedEvent = updated;
      }
      notifyListeners();
      await DatabaseHelper.instance.insertEvent(updated);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  List<Event> _getSeedEvents() {
    return [
      Event(
        id: 'event-1',
        title: 'Annual Science Fair 2024',
        date: DateTime(2024, 10, 15),
        narration:
            'The Annual Science Fair 2024 featured innovative student projects ranging from renewable energy prototypes to robotics and AI models. Over 45 student groups showcased their work to visitors, parents, and distinguished external judges.',
        status: EventStatus.generated,
        attachedPhotos: [
          'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600',
          'https://images.unsplash.com/photo-1507668077129-56e32842fceb?w=600',
        ],
        generatedReport: GeneratedReport(
          executiveSummary:
              'Springfield Elementary School successfully organized the Annual Science Fair 2024 on October 15, 2024. The event showcased 45 interactive science projects curated by students across grades 6 to 10.',
          keyHighlights: [
            'Participation of 45 student project teams across STEM domains.',
            'Special guest lecture by Dr. E. Vance on "Future of Renewable Technologies".',
            'First place awarded to Grade 9 Solar-Hydro Hybrid Filtration model.',
            'Over 350 attendees including parents, faculty, and visiting dignitaries.',
          ],
          formattedBody:
              'The Annual Science Fair commenced at 9:00 AM with an inaugural ribbon-cutting by Principal Seymour Skinner. Students presented live demonstrations of their experiments to the evaluation committee. High enthusiasm was witnessed in the robotics and eco-sustainability tracks. The fair concluded with an award ceremony presided over by Superintendent Gary Chalmers.',
          generatedAt: DateTime(2024, 10, 15, 17, 30),
        ),
        createdAt: DateTime(2024, 10, 15, 9, 0),
        updatedAt: DateTime(2024, 10, 15, 17, 30),
      ),
      Event(
        id: 'event-2',
        title: 'Science Exhibition',
        date: DateTime(2024, 8, 10),
        narration:
            'Preparatory exhibit draft for the regional science showcase. Student team lists, poster boards, and demonstration tables arranged for peer review.',
        status: EventStatus.draft,
        attachedPhotos: [],
        createdAt: DateTime(2024, 8, 9, 14, 0),
        updatedAt: DateTime(2024, 8, 10, 11, 20),
      ),
      Event(
        id: 'event-3',
        title: 'Q3 Faculty Meeting',
        date: DateTime(2024, 9, 20),
        narration:
            'Discussion of third quarter curriculum progression, upcoming midterm examination schedules, and student mentoring initiatives.',
        status: EventStatus.draft,
        attachedPhotos: [],
        createdAt: DateTime(2024, 9, 20, 10, 0),
        updatedAt: DateTime(2024, 9, 20, 12, 0),
      ),
      Event(
        id: 'event-4',
        title: 'Annual Sports Meet 2024',
        date: DateTime(2024, 9, 28),
        narration:
            'Inter-house athletics championship including track events, high jump, relay races, and tug-of-war. Blue House won the overall champions trophy.',
        status: EventStatus.generated,
        attachedPhotos: [
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=600',
        ],
        generatedReport: GeneratedReport(
          executiveSummary:
              'The Annual Sports Meet 2024 took place on September 28, 2024, bringing together over 600 student athletes competing across 18 athletic disciplines.',
          keyHighlights: [
            'March past parade evaluated by Chief Guest Lt. Col. R. Miller.',
            'New school record established in 100m sprint by Grade 10 athlete.',
            'Blue House clinched the Championship Shield with 340 points.',
          ],
          formattedBody:
              'The athletic meet began with the traditional torch lighting relay. High sportsmanship was displayed across track and field events. Medals and trophies were presented during the closing ceremony by Superintendent Gary Chalmers.',
          generatedAt: DateTime(2024, 9, 28, 16, 0),
        ),
        createdAt: DateTime(2024, 9, 28, 8, 30),
        updatedAt: DateTime(2024, 9, 28, 16, 0),
      ),
    ];
  }
}

