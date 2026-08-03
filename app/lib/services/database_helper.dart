import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chronico_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        event_date INTEGER NOT NULL,
        venue TEXT,
        category TEXT,
        ramble TEXT,
        report TEXT,
        pdf_path TEXT,
        is_dirty INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
        updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
        last_synced_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS photos (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        path TEXT NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS presets (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // --- Events CRUD ---

  Future<void> insertEvent(Event event) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'events',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save photos
      await txn.delete('photos', where: 'event_id = ?', whereArgs: [event.id]);
      for (int i = 0; i < event.attachedPhotos.length; i++) {
        final photoPath = event.attachedPhotos[i];
        await txn.insert('photos', {
          'id': '${event.id}_photo_$i',
          'event_id': event.id,
          'path': photoPath,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<List<Event>> getEvents() async {
    final db = await instance.database;
    final eventMaps = await db.query('events', orderBy: 'event_date DESC');

    List<Event> events = [];
    for (final eventMap in eventMaps) {
      final eventId = eventMap['id'] as String;
      final photoMaps = await db.query(
        'photos',
        columns: ['path'],
        where: 'event_id = ?',
        whereArgs: [eventId],
      );
      final photoPaths = photoMaps.map((p) => p['path'] as String).toList();
      events.add(Event.fromMap(eventMap, photos: photoPaths));
    }
    return events;
  }

  Future<Event?> getEventById(String id) async {
    final db = await instance.database;
    final eventMaps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (eventMaps.isEmpty) return null;

    final photoMaps = await db.query(
      'photos',
      columns: ['path'],
      where: 'event_id = ?',
      whereArgs: [id],
    );
    final photoPaths = photoMaps.map((p) => p['path'] as String).toList();
    return Event.fromMap(eventMaps.first, photos: photoPaths);
  }

  Future<void> updateEvent(Event event) async {
    await insertEvent(event);
  }

  Future<void> deleteEvent(String id) async {
    final db = await instance.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // --- Presets Key-Value CRUD ---

  Future<void> setPreset(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'presets',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreset(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'presets',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<Map<String, String>> getAllPresets() async {
    final db = await instance.database;
    final maps = await db.query('presets');
    final Map<String, String> result = {};
    for (final map in maps) {
      final k = map['key'] as String?;
      final v = map['value'] as String?;
      if (k != null && v != null) {
        result[k] = v;
      }
    }
    return result;
  }

  Future<void> setAllPresets(Map<String, String> presets) async {
    final db = await instance.database;
    final batch = db.batch();
    presets.forEach((key, value) {
      batch.insert(
        'presets',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  Future<void> deletePreset(String key) async {
    final db = await instance.database;
    await db.delete('presets', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
