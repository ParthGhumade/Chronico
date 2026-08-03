import 'dart:convert';

enum EventStatus { draft, generated }

class GeneratedReport {
  final String executiveSummary;
  final List<String> keyHighlights;
  final String formattedBody;
  final DateTime generatedAt;

  GeneratedReport({
    required this.executiveSummary,
    required this.keyHighlights,
    required this.formattedBody,
    required this.generatedAt,
  });

  GeneratedReport copyWith({
    String? executiveSummary,
    List<String>? keyHighlights,
    String? formattedBody,
    DateTime? generatedAt,
  }) {
    return GeneratedReport(
      executiveSummary: executiveSummary ?? this.executiveSummary,
      keyHighlights: keyHighlights ?? this.keyHighlights,
      formattedBody: formattedBody ?? this.formattedBody,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'executiveSummary': executiveSummary,
      'keyHighlights': keyHighlights,
      'formattedBody': formattedBody,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  factory GeneratedReport.fromJson(Map<String, dynamic> json) {
    return GeneratedReport(
      executiveSummary: json['executiveSummary'] as String? ?? '',
      keyHighlights: List<String>.from(json['keyHighlights'] as List? ?? []),
      formattedBody: json['formattedBody'] as String? ?? '',
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['generatedAt'] is int
            ? json['generatedAt'] as int
            : (int.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final DateTime date;
  final String narration;
  final EventStatus status;
  final List<String> attachedPhotos;
  final GeneratedReport? generatedReport;
  final String? venue;
  final String? category;
  final String? pdfPath;
  final bool isDirty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.narration,
    required this.status,
    required this.attachedPhotos,
    this.generatedReport,
    this.venue,
    this.category,
    this.pdfPath,
    this.isDirty = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
  });

  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? narration,
    EventStatus? status,
    List<String>? attachedPhotos,
    GeneratedReport? generatedReport,
    String? venue,
    String? category,
    String? pdfPath,
    bool? isDirty,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      narration: narration ?? this.narration,
      status: status ?? this.status,
      attachedPhotos: attachedPhotos ?? this.attachedPhotos,
      generatedReport: generatedReport ?? this.generatedReport,
      venue: venue ?? this.venue,
      category: category ?? this.category,
      pdfPath: pdfPath ?? this.pdfPath,
      isDirty: isDirty ?? this.isDirty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'event_date': date.millisecondsSinceEpoch,
      'venue': venue,
      'category': category,
      'ramble': narration,
      'report': generatedReport != null ? jsonEncode(generatedReport!.toJson()) : null,
      'pdf_path': pdfPath,
      'is_dirty': isDirty ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_synced_at': lastSyncedAt?.millisecondsSinceEpoch,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, {List<String> photos = const []}) {
    GeneratedReport? report;
    if (map['report'] != null && map['report'].toString().isNotEmpty) {
      try {
        report = GeneratedReport.fromJson(jsonDecode(map['report'] as String));
      } catch (_) {}
    }

    final rawStatus = map['report'] != null && map['report'].toString().isNotEmpty
        ? EventStatus.generated
        : EventStatus.draft;

    return Event(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['event_date'] as int? ?? 0),
      narration: map['ramble'] as String? ?? '',
      status: rawStatus,
      attachedPhotos: photos,
      generatedReport: report,
      venue: map['venue'] as String?,
      category: map['category'] as String?,
      pdfPath: map['pdf_path'] as String?,
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_synced_at'] as int)
          : null,
    );
  }
}

