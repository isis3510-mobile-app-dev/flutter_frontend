import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDbTables {
  static const String users = 'users_local';
  static const String pets = 'pets_local';
  static const String events = 'events_local';
  static const String exercises = 'exercises_local';
  static const String vaccines = 'vaccines_local';
  static const String petVaccinations = 'pet_vaccinations_local';
  static const String medicines = 'medicines_local';
  static const String lostPets = 'lost_pets_local';
  static const String syncQueue = 'sync_queue';
  static const String appMeta = 'app_meta';
}

class SyncQueueOperation {
  const SyncQueueOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.createdAt,
    required this.retryCount,
    this.payload,
    this.lastError,
  });

  final int id;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
}

class SyncQueueSummary {
  const SyncQueueSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.retryingCount,
    required this.failedCount,
  });

  final int totalCount;
  final int pendingCount;
  final int retryingCount;
  final int failedCount;

  bool get isEmpty => totalCount == 0;

  String get overallStatus {
    if (isEmpty) {
      return 'Synced';
    }

    if (failedCount > 0) {
      return 'Attention needed';
    }

    if (retryingCount > 0) {
      return 'Retrying';
    }

    return 'Queued';
  }
}

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService _instance = LocalDatabaseService._();

  factory LocalDatabaseService() => _instance;

  static const String _databaseName = 'petcare_offline.db';
  static const int _databaseVersion = 4;

  Database? _database;

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final databasesPath = await getDatabasesPath();
    final fullPath = p.join(databasesPath, _databaseName);

    final db = await openDatabase(
      fullPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );

    await _ensureOptionalEntityTables(db);
    _database = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${LocalDbTables.users} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.pets} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.events} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.exercises} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.vaccines} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.petVaccinations} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.medicines} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');

    await _createLostPetsTable(db);

    await db.execute('''
      CREATE TABLE ${LocalDbTables.syncQueue} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${LocalDbTables.appMeta} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sync_queue_entity ON ${LocalDbTables.syncQueue}(entity_type, entity_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_created_at ON ${LocalDbTables.syncQueue}(created_at)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLostPetsTable(db);
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${LocalDbTables.medicines} (
          remote_id TEXT PRIMARY KEY,
          payload TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          updated_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${LocalDbTables.medicines} (
          remote_id TEXT PRIMARY KEY,
          payload TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          updated_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${LocalDbTables.exercises} (
          remote_id TEXT PRIMARY KEY,
          payload TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _ensureOptionalEntityTables(Database db) async {
    await _createLostPetsTable(db);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${LocalDbTables.medicines} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${LocalDbTables.exercises} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createLostPetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${LocalDbTables.lostPets} (
        remote_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> upsertEntity({
    required String table,
    required String remoteId,
    required Map<String, dynamic> payload,
    String syncStatus = 'synced',
    DateTime? updatedAt,
  }) async {
    final db = await database;
    await db.insert(table, <String, Object?>{
      'remote_id': remoteId,
      'payload': jsonEncode(payload),
      'sync_status': syncStatus,
      'updated_at': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getEntityById({
    required String table,
    required String remoteId,
  }) async {
    final db = await database;
    final rows = await db.query(
      table,
      columns: <String>['payload'],
      where: 'remote_id = ?',
      whereArgs: <Object>[remoteId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final payload = rows.first['payload'];
    if (payload is! String) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  Future<String?> getEntitySyncStatus({
    required String table,
    required String remoteId,
  }) async {
    final db = await database;
    final rows = await db.query(
      table,
      columns: <String>['sync_status'],
      where: 'remote_id = ?',
      whereArgs: <Object>[remoteId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final syncStatus = rows.first['sync_status'];
    return syncStatus is String ? syncStatus : null;
  }

  Future<List<Map<String, dynamic>>> getAllEntities(String table) async {
    final db = await database;
    final rows = await db.query(
      table,
      columns: <String>['payload'],
      orderBy: 'updated_at DESC',
    );

    return rows
        .map((row) => row['payload'])
        .whereType<String>()
        .map((payload) => jsonDecode(payload))
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }

  Future<void> deleteEntity({
    required String table,
    required String remoteId,
  }) async {
    final db = await database;
    await db.delete(
      table,
      where: 'remote_id = ?',
      whereArgs: <Object>[remoteId],
    );
  }

  Future<void> deleteEntitiesNotIn({
    required String table,
    required List<String> keepRemoteIds,
    bool onlySynced = true,
  }) async {
    if (keepRemoteIds.isEmpty) {
      return;
    }

    final db = await database;
    final placeholders = List<String>.filled(
      keepRemoteIds.length,
      '?',
    ).join(', ');
    final where = StringBuffer('remote_id NOT IN ($placeholders)');
    final whereArgs = keepRemoteIds.cast<Object?>();

    if (onlySynced) {
      where.write(" AND (sync_status IS NULL OR sync_status = 'synced')");
    }

    await db.delete(table, where: where.toString(), whereArgs: whereArgs);
  }

  Future<void> clearUserData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete(LocalDbTables.users);
    batch.delete(LocalDbTables.pets);
    batch.delete(LocalDbTables.events);
    batch.delete(LocalDbTables.exercises);
    batch.delete(LocalDbTables.vaccines);
    batch.delete(LocalDbTables.petVaccinations);
    batch.delete(LocalDbTables.medicines);
    batch.delete(LocalDbTables.lostPets);
    batch.delete(LocalDbTables.syncQueue);
    await batch.commit(noResult: true);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete(LocalDbTables.syncQueue);
  }

  Future<SyncQueueSummary> getSyncQueueSummary({int maxRetries = 5}) async {
    final db = await database;

    final totalCount = await _countRows(db, LocalDbTables.syncQueue);
    final pendingCount = await _countRows(
      db,
      LocalDbTables.syncQueue,
      where: 'retry_count = 0',
    );
    final retryingCount = await _countRows(
      db,
      LocalDbTables.syncQueue,
      where: 'retry_count > 0 AND retry_count < ?',
      whereArgs: <Object>[maxRetries],
    );
    final failedCount = await _countRows(
      db,
      LocalDbTables.syncQueue,
      where: 'retry_count >= ?',
      whereArgs: <Object>[maxRetries],
    );

    return SyncQueueSummary(
      totalCount: totalCount,
      pendingCount: pendingCount,
      retryingCount: retryingCount,
      failedCount: failedCount,
    );
  }

  Future<List<SyncQueueOperation>> getFailedSyncOperations({
    String? entityType,
    int limit = 50,
    int maxRetries = 5,
  }) async {
    final db = await database;
    final whereClauses = <String>['retry_count >= ?'];
    final whereArgs = <Object>[maxRetries];

    if (entityType != null && entityType.trim().isNotEmpty) {
      whereClauses.add('entity_type = ?');
      whereArgs.add(entityType.trim());
    }

    final rows = await db.query(
      LocalDbTables.syncQueue,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_toSyncQueueOperation).toList(growable: false);
  }

  Future<void> enqueueSyncOperation({
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    final db = await database;
    await db.insert(LocalDbTables.syncQueue, <String, Object?>{
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
      'last_error': null,
    });
  }

  Future<List<SyncQueueOperation>> getPendingSyncOperations({
    String? entityType,
    int limit = 50,
    int maxRetries = 5,
  }) async {
    final db = await database;
    final whereClauses = <String>['retry_count < ?'];
    final whereArgs = <Object>[maxRetries];

    if (entityType != null && entityType.trim().isNotEmpty) {
      whereClauses.add('entity_type = ?');
      whereArgs.add(entityType.trim());
    }

    final rows = await db.query(
      LocalDbTables.syncQueue,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_toSyncQueueOperation).toList(growable: false);
  }

  Future<void> markSyncOperationCompleted(int operationId) async {
    final db = await database;
    await db.delete(
      LocalDbTables.syncQueue,
      where: 'id = ?',
      whereArgs: <Object>[operationId],
    );
  }

  Future<void> markSyncOperationFailed(int operationId, {String? error}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ${LocalDbTables.syncQueue} '
      'SET retry_count = retry_count + 1, last_error = ? '
      'WHERE id = ?',
      <Object?>[error, operationId],
    );
  }

  Future<void> resetSyncOperationRetries(Iterable<int> operationIds) async {
    final ids = operationIds.toList(growable: false);
    if (ids.isEmpty) {
      return;
    }

    final db = await database;
    final placeholders = List<String>.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE ${LocalDbTables.syncQueue} '
      'SET retry_count = 0, last_error = NULL '
      'WHERE id IN ($placeholders)',
      ids.cast<Object?>(),
    );
  }

  Future<void> setMetaValue({
    required String key,
    required String value,
  }) async {
    final db = await database;
    await db.insert(LocalDbTables.appMeta, <String, Object>{
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMetaValue(String key) async {
    final db = await database;
    final rows = await db.query(
      LocalDbTables.appMeta,
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object>[key],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['value'];
    return value is String ? value : null;
  }

  Future<int> _countRows(
    Database db,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final query = StringBuffer('SELECT COUNT(*) AS count FROM $table');
    if (where != null && where.trim().isNotEmpty) {
      query.write(' WHERE $where');
    }

    final rows = await db.rawQuery(query.toString(), whereArgs);
    final countValue = rows.isNotEmpty ? rows.first['count'] : 0;
    return (countValue as num?)?.toInt() ?? 0;
  }

  SyncQueueOperation _toSyncQueueOperation(Map<String, Object?> row) {
    final payloadRaw = row['payload'];
    Map<String, dynamic>? payload;
    if (payloadRaw is String && payloadRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payloadRaw);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        payload = null;
      }
    }

    return SyncQueueOperation(
      id: (row['id'] as num?)?.toInt() ?? 0,
      entityType: (row['entity_type'] as String?) ?? '',
      entityId: (row['entity_id'] as String?) ?? '',
      action: (row['action'] as String?) ?? '',
      payload: payload,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num?)?.toInt() ?? 0,
      ),
      retryCount: (row['retry_count'] as num?)?.toInt() ?? 0,
      lastError: row['last_error'] as String?,
    );
  }
}
